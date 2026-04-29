import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../providers/auth_provider.dart';
import '../providers/categories_provider.dart';
import '../providers/wallet_provider.dart';
import '../utils/app_constants.dart';
import '../utils/detection_localizer.dart';
import '../l10n/app_localizations.dart';
import '../widgets/app_skeleton.dart';
import '../widgets/custom_button.dart';

class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> {
  Razorpay? _razorpay;
  final TextEditingController _customAmountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initRazorpay();
  }

  // ── Razorpay lifecycle ────────────────────────────────────────────────────

  void _initRazorpay() {
    _razorpay?.clear();
    _razorpay = Razorpay();
    _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onPaymentSuccess);
    _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _onPaymentError);
    _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, _onExternalWallet);
  }

  @override
  void dispose() {
    _customAmountController.dispose();
    _razorpay?.clear();
    _razorpay = null;
    super.dispose();
  }

  // ── Razorpay callbacks ────────────────────────────────────────────────────

  Future<void> _onPaymentSuccess(PaymentSuccessResponse response) async {
    debugPrint('[Razorpay] SUCCESS paymentId=${response.paymentId} '
        'orderId=${response.orderId}');

    if (!mounted) return;

    await ref.read(walletProvider.notifier).verifyPayment(
          paymentId: response.paymentId ?? '',
          orderId: response.orderId ?? '',
          signature: response.signature ?? '',
        );

    // Re-initialise so subsequent payments work correctly
    _initRazorpay();
  }

  void _onPaymentError(PaymentFailureResponse response) {
    debugPrint('[Razorpay] ERROR code=${response.code} '
        'message=${response.message}');

    if (!mounted) return;

    final msg = response.message?.isNotEmpty == true
        ? response.message!
        : 'Payment failed. Please try again.';

    ref.read(walletProvider.notifier).onPaymentError(msg);
    _initRazorpay(); // Re-init after failure
  }

  void _onExternalWallet(ExternalWalletResponse response) {
    debugPrint('[Razorpay] EXTERNAL_WALLET name=${response.walletName}');
    if (!mounted) return;
    // External wallet selected — treat as cancelled from our flow
    ref.read(walletProvider.notifier).onPaymentCancelled();
    _initRazorpay();
  }

  // ── Start payment flow ────────────────────────────────────────────────────

  Future<void> _startPayment(int amountInr) async {
    if (amountInr <= 0) {
      ref
          .read(walletProvider.notifier)
          .onPaymentError('Please enter a valid amount.');
      return;
    }

    // Dismiss keyboard
    FocusScope.of(context).unfocus();

    // Step 1 — Create server-side order
    final resolved =
        await ref.read(walletProvider.notifier).createOrder(amountInr);

    if (resolved == null || !mounted) return;

    final authState = ref.read(authProvider);
    final user = authState.user;

    // Build prefill map
    final prefill = <String, String>{};
    if (user?.name.trim().isNotEmpty == true) {
      prefill['name'] = user!.name.trim();
    }
    if (user?.email.trim().isNotEmpty == true) {
      prefill['email'] = user!.email.trim();
    }
    if (user?.phone.trim().isNotEmpty == true) {
      prefill['contact'] = user!.phone.trim();
    }

    // Step 2 — Open Razorpay checkout
    final options = <String, dynamic>{
      'key': resolved.checkoutKey,
      'amount': resolved.checkoutAmount, // in paise
      'currency': resolved.currency,
      'name': AppConstants.appName,
      'description': '${resolved.amountInr} Credits — ${AppConstants.appName}',
      'order_id': resolved.orderId,
      'prefill': prefill,
      'theme': {'color': '#2E7D32'},
      'retry': {'enabled': false}, // Prevent Razorpay internal retry loops
      'send_sms_hash': true,
      'remember_customer': false,
    };

    debugPrint('[Razorpay] Opening checkout orderId=${resolved.orderId} '
        'amount=${resolved.checkoutAmount} key=${resolved.checkoutKey.substring(0, 8)}...');

    try {
      _razorpay!.open(options);
    } catch (e) {
      debugPrint('[Razorpay] open() threw: $e');
      ref.read(walletProvider.notifier).onPaymentError(
            'Could not open payment gateway: $e',
          );
      _initRazorpay();
    }
  }

  void _startCustomPayment() {
    final text = _customAmountController.text.trim();
    final amount = int.tryParse(text) ?? 0;
    if (amount < 1) {
      ref
          .read(walletProvider.notifier)
          .onPaymentError('Enter a valid amount (minimum ₹1).');
      return;
    }
    _startPayment(amount);
  }

  // ── Snackbar handling ─────────────────────────────────────────────────────

  void _handleWalletMessages(WalletState walletState) {
    if (walletState.paymentSuccess != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            content: Text('✅ ${walletState.paymentSuccess}'),
            backgroundColor: const Color(0xFF2E7D32),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ));
        ref.read(walletProvider.notifier).clearPaymentMessages();
      });
    }

    if (walletState.paymentError != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            content: Text('❌ ${walletState.paymentError}'),
            backgroundColor: const Color(0xFF5D4037),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ));
        ref.read(walletProvider.notifier).clearPaymentMessages();
      });
    }
  }

  Future<void> _refreshWalletPage() async {
    await Future.wait<void>([
      ref.read(walletProvider.notifier).fetchWallet(),
      ref.read(categoriesProvider.notifier).fetch(),
    ]);
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final walletState = ref.watch(walletProvider);
    final categoriesState = ref.watch(categoriesProvider);

    final credits = walletState.credits > 0
        ? walletState.credits
        : (authState.user?.credits ?? 0);
    final l = AppLocalizations.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 380;
    final creditText = '$credits';
    final creditFontSize = creditText.length > 8
        ? (isSmallScreen ? 26.0 : 30.0)
        : (isSmallScreen ? 36.0 : 46.0);

    _handleWalletMessages(walletState);

    return Stack(
      children: [
        // Decorative background emojis
        Positioned.fill(
          child: IgnorePointer(
            child: Opacity(
              opacity: 0.03,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final emojiSize = constraints.maxWidth * 0.12;
                  return Wrap(
                    children: [
                      Text('🌾', style: TextStyle(fontSize: emojiSize)),
                      Text('🌱', style: TextStyle(fontSize: emojiSize * 1.2)),
                      Text('🍃', style: TextStyle(fontSize: emojiSize * 0.9)),
                      Text('🌿', style: TextStyle(fontSize: emojiSize * 1.1)),
                      Text('🌾', style: TextStyle(fontSize: emojiSize * 0.8)),
                      Text('🍃', style: TextStyle(fontSize: emojiSize * 1.3)),
                    ],
                  );
                },
              ),
            ),
          ),
        ),

        Scaffold(
          backgroundColor: const Color(0xFFF5F7F5),
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: _refreshWalletPage,
              color: const Color(0xFF2E7D32),
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                // ── Curved header ─────────────────────────────────────────
                SliverAppBar(
                  expandedHeight: isSmallScreen ? 200 : 230,
                  floating: false,
                  pinned: true,
                  backgroundColor: Colors.transparent,
                  automaticallyImplyLeading: false,
                  flexibleSpace: FlexibleSpaceBar(
                    background: ClipPath(
                      clipper: _CurvedBottomClipper(),
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.3),
                                    width: 2,
                                  ),
                                ),
                                child: const Text('💰',
                                    style: TextStyle(fontSize: 32)),
                              ),
                              const SizedBox(height: 10),
                              walletState.isLoading
                                  ? const _WalletCreditsSkeleton()
                                  : SizedBox(
                                      width: double.infinity,
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          creditText,
                                          maxLines: 1,
                                          style: GoogleFonts.nunito(
                                            fontSize: creditFontSize,
                                            fontWeight: FontWeight.w900,
                                            color: Colors.white,
                                            shadows: [
                                              Shadow(
                                                color: Colors.black
                                                    .withValues(alpha: 0.2),
                                                blurRadius: 8,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ).animate().scale(duration: 500.ms),
                              const SizedBox(height: 8),
                              Text(
                                l.availableCredits,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.nunito(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: isSmallScreen ? 14 : 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Section title ──────────────────────────────
                        Row(
                          children: [
                            const Text('💰', style: TextStyle(fontSize: 20)),
                            const SizedBox(width: 12),
                            Flexible(
                              child: Text(
                                l.addCredits,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.nunito(
                                  fontSize: isSmallScreen ? 20 : 24,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF2E7D32),
                                ),
                              ),
                            ),
                          ],
                        ).animate().fadeIn(),
                        const SizedBox(height: 4),
                        Container(
                          width: 60,
                          height: 3,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFF9A825), Color(0xFF2E7D32)],
                            ),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ).animate().fadeIn(delay: 50.ms),
                        const SizedBox(height: 8),
                        Text(
                          l.eachScan,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.nunito(
                            fontSize: 14,
                            color: const Color(0xFF5D4037),
                          ),
                        ).animate().fadeIn(delay: 100.ms),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFF2E7D32).withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '1 ₹ = 1 Coin',
                            style: GoogleFonts.nunito(
                                fontSize: 12,
                                color: const Color(0xFF2E7D32),
                                fontWeight: FontWeight.w600),
                          ),
                        ).animate().fadeIn(delay: 120.ms),
                        const SizedBox(height: 16),

                        // ── Custom amount field ────────────────────────
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: const Color(0xFF2E7D32)
                                  .withValues(alpha: 0.12),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l.t('custom_amount_hint'),
                                style: GoogleFonts.nunito(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF2E7D32),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _customAmountController,
                                keyboardType: TextInputType.number,
                                textInputAction: TextInputAction.done,
                                onSubmitted: (_) => _startCustomPayment(),
                                decoration: InputDecoration(
                                  hintText: '0',
                                  prefixText: '₹ ',
                                  filled: true,
                                  fillColor: const Color(0xFFF8FBF8),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 16,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(
                                      color: const Color(0xFF2E7D32)
                                          .withValues(alpha: 0.10),
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(
                                      color: const Color(0xFF2E7D32)
                                          .withValues(alpha: 0.10),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF2E7D32),
                                      width: 1.4,
                                    ),
                                  ),
                                  hintStyle: GoogleFonts.nunito(
                                    color: const Color(0xFF9E9E9E),
                                  ),
                                ),
                                style: GoogleFonts.nunito(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF5D4037),
                                ),
                              ),
                              const SizedBox(height: 14),
                              PrimaryButton(
                                label: l.addCredits,
                                onPressed: walletState.isPaymentLoading
                                    ? null
                                    : _startCustomPayment,
                                isLoading: walletState.isPaymentLoading,
                                icon: Icons.arrow_forward_rounded,
                                color: const Color(0xFF2E7D32),
                                height: 54,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'enter your amount in ₹ and tap "Add Credits" to proceed to payment',
                                style: GoogleFonts.nunito(
                                  fontSize: 12,
                                  color: const Color(0xFF9E9E9E),
                                ),
                              ),
                            ],
                          ),
                        ).animate().fadeIn(delay: 130.ms),

                        const SizedBox(height: 24),

                        // ── Credit usage info ──────────────────────────
                        Container(
                          padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF2E7D32).withValues(alpha: 0.08),
                                const Color(0xFF2E7D32).withValues(alpha: 0.02),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: const Color(0xFF2E7D32)
                                  .withValues(alpha: 0.15),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Text('📊',
                                      style: TextStyle(fontSize: 22)),
                                  const SizedBox(width: 10),
                                  Flexible(
                                    child: Text(
                                      l.t('credit_usage'),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.nunito(
                                        fontSize: isSmallScreen ? 16 : 18,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF2E7D32),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Container(
                                width: 50,
                                height: 2,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFF9A825),
                                      Color(0xFF2E7D32)
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(1),
                                ),
                              ),
                              const SizedBox(height: 16),
                              if (categoriesState.isLoading &&
                                  categoriesState.categories.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  child: _WalletUsageSkeleton(),
                                )
                              else if (categoriesState.categories.isEmpty)
                                Column(
                                  children: [
                                    Text(
                                      categoriesState.error
                                                  ?.trim()
                                                  .isNotEmpty ==
                                              true
                                          ? categoriesState.error!
                                          : 'No categories available',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.nunito(
                                        fontSize: 13,
                                        color: const Color(0xFF5D4037),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    OutlinedButton(
                                      onPressed: () => ref
                                          .read(categoriesProvider.notifier)
                                          .fetch(),
                                      child: Text(l.t('retry')),
                                    ),
                                  ],
                                )
                              else
                                ...categoriesState.categories.map(
                                  (category) => _usageRow(
                                    '${category.icon} ${DetectionLocalizer.categoryTitle(context, category.id, fallbackTitle: category.title)}',
                                    '${AppConstants.creditsPerScan} ${l.t('credits_unit')}',
                                    isSmallScreen,
                                  ),
                                ),
                            ],
                          ),
                        ).animate().fadeIn(delay: 300.ms),

                        const SizedBox(height: 24),

                        // ── Recent activity ────────────────────────────
                        Row(
                          children: [
                            const Text('📜', style: TextStyle(fontSize: 22)),
                            const SizedBox(width: 12),
                            Flexible(
                              child: Text(
                                l.recentActivity,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.nunito(
                                  fontSize: isSmallScreen ? 20 : 22,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF2E7D32),
                                ),
                              ),
                            ),
                          ],
                        ).animate().fadeIn(delay: 400.ms),
                        const SizedBox(height: 4),
                        Container(
                          width: 60,
                          height: 3,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFF9A825), Color(0xFF2E7D32)],
                            ),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ).animate().fadeIn(delay: 450.ms),
                        const SizedBox(height: 12),

                        if (credits == AppConstants.initialCredits)
                          _transactionItem(
                            context,
                            "🎁 ${l.t('welcome_bonus')}",
                            "+50 ${l.t('credits_unit')}",
                            l.t('registration_reward'),
                            const Color(0xFF2E7D32),
                            isSmallScreen,
                          ).animate().fadeIn(delay: 500.ms)
                        else
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(48),
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2E7D32)
                                          .withValues(alpha: 0.05),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Text('📭',
                                        style: TextStyle(fontSize: 48)),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    l.noTransactions,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.nunito(
                                      fontSize: 14,
                                      color: const Color(0xFF5D4037),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _usageRow(String label, String cost, bool isSmallScreen) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.nunito(
                fontSize: isSmallScreen ? 12 : 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF5D4037),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              cost,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.nunito(
                color: Colors.white,
                fontSize: isSmallScreen ? 10 : 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _transactionItem(
    BuildContext context,
    String title,
    String amount,
    String subtitle,
    Color color,
    bool isSmallScreen,
  ) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: isSmallScreen ? 44 : 52,
            height: isSmallScreen ? 44 : 52,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: 0.1),
                  color.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Icon(
                Icons.card_giftcard_rounded,
                color: color,
                size: isSmallScreen ? 22 : 26,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.nunito(
                    fontSize: isSmallScreen ? 13 : 15,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF2E7D32),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.nunito(
                    fontSize: isSmallScreen ? 10 : 12,
                    color: const Color(0xFF5D4037),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              amount,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.nunito(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: isSmallScreen ? 12 : 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WalletCreditsSkeleton extends StatelessWidget {
  const _WalletCreditsSkeleton();

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      baseColor: Colors.white24,
      highlightColor: Colors.white54,
      child: const Column(
        children: [
          AppSkeletonBox(width: 120, height: 42),
          SizedBox(height: 10),
          AppSkeletonBox(width: 90, height: 14),
        ],
      ),
    );
  }
}

class _WalletUsageSkeleton extends StatelessWidget {
  const _WalletUsageSkeleton();

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: Column(
        children: List.generate(
          4,
          (index) => Padding(
            padding: EdgeInsets.only(bottom: index == 3 ? 0 : 12),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Row(
                children: [
                  AppSkeletonBox(width: 44, height: 44, shape: BoxShape.circle),
                  SizedBox(width: 12),
                  Expanded(
                    child: AppSkeletonBox(width: double.infinity, height: 14),
                  ),
                  SizedBox(width: 12),
                  AppSkeletonBox(width: 74, height: 28),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CurvedBottomClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 30);
    path.quadraticBezierTo(
        size.width / 2, size.height, size.width, size.height - 30);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
