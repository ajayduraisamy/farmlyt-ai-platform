import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/app_constants.dart';
import 'auth_provider.dart';

class WalletState {
  final int credits;
  final bool isLoading;
  final String? error;
  final bool isPaymentLoading;
  final String? paymentError;
  final String? paymentSuccess;
  // Store pending order details so verify always has correct data
  final PendingOrder? pendingOrder;

  const WalletState({
    this.credits = 0,
    this.isLoading = false,
    this.error,
    this.isPaymentLoading = false,
    this.paymentError,
    this.paymentSuccess,
    this.pendingOrder,
  });

  WalletState copyWith({
    int? credits,
    bool? isLoading,
    String? error,
    bool clearError = false,
    bool? isPaymentLoading,
    String? paymentError,
    bool clearPaymentError = false,
    String? paymentSuccess,
    bool clearPaymentSuccess = false,
    PendingOrder? pendingOrder,
    bool clearPendingOrder = false,
  }) =>
      WalletState(
        credits: credits ?? this.credits,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : (error ?? this.error),
        isPaymentLoading: isPaymentLoading ?? this.isPaymentLoading,
        paymentError:
            clearPaymentError ? null : (paymentError ?? this.paymentError),
        paymentSuccess: clearPaymentSuccess
            ? null
            : (paymentSuccess ?? this.paymentSuccess),
        pendingOrder:
            clearPendingOrder ? null : (pendingOrder ?? this.pendingOrder),
      );
}

class PendingOrder {
  final String orderId;
  final int amountInr;
  final String checkoutKey;
  final int checkoutAmount; // always in paise

  const PendingOrder({
    required this.orderId,
    required this.amountInr,
    required this.checkoutKey,
    required this.checkoutAmount,
  });
}

class WalletNotifier extends Notifier<WalletState> {
  @override
  WalletState build() {
    Future.microtask(() => fetchWallet());
    return const WalletState(isLoading: true);
  }

  Future<void> fetchWallet() async {
    final userId = ref.read(authProvider).user?.id;
    if (userId == null || userId.isEmpty) {
      state = state.copyWith(isLoading: false, error: 'Not logged in');
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    final api = ref.read(apiServiceProvider);
    final res = await api.getWallet(userId: userId);

    if (res.isSuccess && res.data != null) {
      final credits = res.data!;
      state = state.copyWith(credits: credits, isLoading: false);
      await ref.read(authProvider.notifier).updateCreditsFromWallet(credits);
    } else {
      final fallback = ref.read(authProvider).user?.credits ?? 0;
      state =
          state.copyWith(credits: fallback, isLoading: false, error: res.error);
    }
  }

  void spendCredits(int amount) {
    final newTotal = (state.credits - amount).clamp(0, 99999);
    state = state.copyWith(credits: newTotal);
  }

  void addCredits(int amount) {
    state = state.copyWith(credits: state.credits + amount);
  }

  // ── Step 1: Create order — returns resolved order details or null ─────────
  /// Returns a [_ResolvedOrder] with corrected amount/key, or null on failure.
  /// Keeps isPaymentLoading=true so caller can open Razorpay immediately.
  Future<ResolvedOrder?> createOrder(int amountInr) async {
    final userId = ref.read(authProvider).user?.id;
    if (userId == null || userId.isEmpty) {
      state = state.copyWith(
          isPaymentLoading: false,
          paymentError: 'You must be logged in to make a payment.');
      return null;
    }

    state = state.copyWith(
      isPaymentLoading: true,
      clearPaymentError: true,
      clearPaymentSuccess: true,
      clearPendingOrder: true,
    );

    final api = ref.read(apiServiceProvider);
    final res = await api.createOrder(userId: userId, amountInr: amountInr);

    if (!res.isSuccess || res.data == null) {
      state = state.copyWith(
          isPaymentLoading: false,
          paymentError: res.error ?? 'Failed to create order. Try again.');
      return null;
    }

    final data = res.data!;

    // ── Resolve order_id ──────────────────────────────────────────────────
    final orderId =
        data['order_id']?.toString() ?? data['id']?.toString() ?? '';
    if (orderId.isEmpty) {
      state = state.copyWith(
          isPaymentLoading: false,
          paymentError:
              'Server did not return a valid order ID. Contact support.');
      return null;
    }

    // ── Resolve Razorpay key ──────────────────────────────────────────────
    final checkoutKey = data['key_id']?.toString() ??
        data['key']?.toString() ??
        data['razorpay_key']?.toString() ??
        AppConstants.razorpayKeyId;
    if (checkoutKey.isEmpty) {
      state = state.copyWith(
          isPaymentLoading: false,
          paymentError: 'Payment gateway not configured. Contact support.');
      return null;
    }

    // ── Resolve amount in PAISE ──────────────────────────────────────────
    // Backend may return amount in paise (e.g. 4900 for ₹49) or rupees (49).
    // We normalise here: Razorpay always needs paise.
    final rawAmount = _asInt(data['amount']);
    final int checkoutAmount;
    if (rawAmount >= amountInr * 100) {
      // Already in paise
      checkoutAmount = rawAmount;
    } else if (rawAmount > 0) {
      // In rupees — convert to paise
      checkoutAmount = rawAmount * 100;
    } else {
      // Fallback: derive from amountInr
      checkoutAmount = amountInr * 100;
    }

    final currency = data['currency']?.toString() ?? 'INR';

    final resolved = ResolvedOrder(
      orderId: orderId,
      checkoutKey: checkoutKey,
      checkoutAmount: checkoutAmount,
      currency: currency,
      amountInr: amountInr,
    );

    // Persist in state so verify always has data even if UI rebuilds
    state = state.copyWith(
      pendingOrder: PendingOrder(
        orderId: orderId,
        amountInr: amountInr,
        checkoutKey: checkoutKey,
        checkoutAmount: checkoutAmount,
      ),
    );

    return resolved;
  }

  // ── Step 2: Verify payment ────────────────────────────────────────────────
  Future<void> verifyPayment({
    required String paymentId,
    required String orderId,
    required String signature,
    int? amountInr, // optional override; falls back to pendingOrder
  }) async {
    final userId = ref.read(authProvider).user?.id;
    if (userId == null || userId.isEmpty) return;

    final resolvedAmount = amountInr ?? state.pendingOrder?.amountInr ?? 0;

    final api = ref.read(apiServiceProvider);
    final res = await api.verifyPayment(
      userId: userId,
      paymentId: paymentId,
      orderId: orderId,
      signature: signature,
      amountInr: resolvedAmount,
    );

    if (res.isSuccess && res.data != null) {
      final coinsAdded = res.data!;
      final newCredits = state.credits + coinsAdded;
      state = state.copyWith(
        credits: newCredits,
        isPaymentLoading: false,
        clearPendingOrder: true,
        paymentSuccess: '+$coinsAdded coins added to your wallet! 🌱',
      );
      await ref.read(authProvider.notifier).updateCreditsFromWallet(newCredits);
    } else {
      state = state.copyWith(
        isPaymentLoading: false,
        clearPendingOrder: true,
        paymentError:
            res.error ?? 'Payment verification failed. Contact support.',
      );
    }
  }

  void onPaymentCancelled() {
    state = state.copyWith(
      isPaymentLoading: false,
      clearPendingOrder: true,
      paymentError: 'Payment cancelled.',
    );
  }

  void onPaymentError(String message) {
    state = state.copyWith(
      isPaymentLoading: false,
      clearPendingOrder: true,
      paymentError: message,
    );
  }

  void clearPaymentMessages() {
    state = state.copyWith(clearPaymentError: true, clearPaymentSuccess: true);
  }

  int _asInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '0') ?? 0;
  }
}

/// Resolved order details passed back to the UI to open Razorpay checkout.
class ResolvedOrder {
  final String orderId;
  final String checkoutKey;
  final int checkoutAmount; // in paise
  final String currency;
  final int amountInr;

  const ResolvedOrder({
    required this.orderId,
    required this.checkoutKey,
    required this.checkoutAmount,
    required this.currency,
    required this.amountInr,
  });
}

final walletProvider =
    NotifierProvider<WalletNotifier, WalletState>(WalletNotifier.new);
