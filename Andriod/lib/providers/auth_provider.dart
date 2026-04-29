import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_models.dart';
import '../services/api_service.dart';
import '../utils/app_constants.dart';

// ─── SharedPreferences provider ─────────────────────────────────────────────
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Override in ProviderScope');
});

// ─── ApiService provider ─────────────────────────────────────────────────────
final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

// ─── Auth state ──────────────────────────────────────────────────────────────
class AuthState {
  final UserModel? user;
  final bool isLoggedIn;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.user,
    this.isLoggedIn = false,
    this.isLoading = false,
    this.error,
  });

  AuthState copyWith({
    UserModel? user,
    bool? isLoggedIn,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) =>
      AuthState(
        user: user ?? this.user,
        isLoggedIn: isLoggedIn ?? this.isLoggedIn,
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : (error ?? this.error),
      );
}

// ─── Auth notifier ───────────────────────────────────────────────────────────
class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() => _restoreSessionState();

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  // ── Session restore ──────────────────────────────────────────────────────
  AuthState _restoreSessionState() {
    try {
      final isLoggedIn = _prefs.getBool(AppConstants.keyIsLoggedIn) ?? false;
      if (!isLoggedIn) return const AuthState();

      final userJson = _prefs.getString('user_json');
      if (userJson != null && userJson.isNotEmpty) {
        final user = UserModel.fromJson(
          Map<String, dynamic>.from(jsonDecode(userJson) as Map),
        );

        // Restore credits from prefs (may differ from stored user object)
        final credits = _prefs.getInt(AppConstants.keyCredits) ?? user.credits;

        return AuthState(
          user: user.copyWith(credits: credits),
          isLoggedIn: true,
        );
      }

      // Fallback for older/incomplete stored sessions where user_json is missing.
      final restoredId = _prefs.getString(AppConstants.keyUserId) ?? '';
      final restoredToken = _prefs.getString(AppConstants.keyToken) ?? '';

      if (restoredId.isEmpty && restoredToken.isEmpty) {
        return const AuthState();
      }

      return AuthState(
        user: UserModel(
          id: restoredId,
          name: _prefs.getString(AppConstants.keyUserName) ?? '',
          phone: _prefs.getString(AppConstants.keyUserPhone) ?? '',
          email: _prefs.getString(AppConstants.keyUserEmail) ?? '',
          token: restoredToken,
          credits: _prefs.getInt(AppConstants.keyCredits) ??
              AppConstants.initialCredits,
          profileImagePath:
              _prefs.getString(AppConstants.keyUserProfileImagePath),
        ),
        isLoggedIn: true,
      );
    } catch (_) {
      return const AuthState();
    }
  }

  Future<void> refreshSession() async {
    state = _restoreSessionState();
  }

  // ── Persist session ──────────────────────────────────────────────────────
  Future<void> _persistSession(UserModel user) async {
    await _prefs.setBool(AppConstants.keyIsLoggedIn, true);
    await _prefs.setString('user_json', jsonEncode(user.toJson()));
    await _prefs.setString(AppConstants.keyToken, user.token);
    await _prefs.setString(AppConstants.keyUserId, user.id);
    await _prefs.setString(AppConstants.keyUserName, user.name);
    await _prefs.setString(AppConstants.keyUserPhone, user.phone);
    await _prefs.setString(AppConstants.keyUserEmail, user.email);
    await _prefs.setInt(AppConstants.keyCredits, user.credits);
    if (user.profileImagePath != null && user.profileImagePath!.isNotEmpty) {
      await _prefs.setString(
        AppConstants.keyUserProfileImagePath,
        user.profileImagePath!,
      );
    } else {
      await _prefs.remove(AppConstants.keyUserProfileImagePath);
    }
  }

  // ── Phone / Firebase register (called from OTP screen) ───────────────────
  Future<bool> register({required String name, required String phone}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final api = ref.read(apiServiceProvider);
    final res = await api.register(name: name, phone: phone);

    if (res.isSuccess && res.data != null) {
      final user = res.data!;
      await _persistSession(user);
      state = state.copyWith(user: user, isLoggedIn: true, isLoading: false);
      return true;
    }
    state = state.copyWith(isLoading: false, error: res.error);
    return false;
  }

// ── Email register ───────────────────────────────────────────────────────
  Future<OtpResult?> emailRegister({
    required String name,
    required String email,
    required String phone,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final api = ref.read(apiServiceProvider);

    final res = await api.emailRegister(name: name, email: email, phone: phone);

    if (res.isSuccess && res.data != null) {
      state = state.copyWith(isLoading: false);
      return res.data; // Returns the OtpResult object
    }

    state = state.copyWith(isLoading: false, error: res.error);
    return null;
  }

// ── Email login ──────────────────────────────────────────────────────────

  Future<OtpResult?> emailLogin({required String email}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final api = ref.read(apiServiceProvider);

    final res = await api.emailLogin(email: email);

    if (res.isSuccess && res.data != null) {
      state = state.copyWith(isLoading: false);
      return res.data; // This is now returning the OtpResult object correctly
    }

    state = state.copyWith(isLoading: false, error: res.error);
    return null;
  }

  Future<bool> verifyEmailOtp({
    required String userId,
    required String otp,
    String email = '',
    String? fallbackName,
    String? fallbackPhone,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final api = ref.read(apiServiceProvider);
    final res = await api.verifyEmailOtp(userId: userId, otp: otp);

    if (res.isSuccess && res.data != null) {
      final withEmail = res.data!.copyWith(
        email: email.isNotEmpty ? email : res.data!.email,
        name: res.data!.name.isNotEmpty ? res.data!.name : (fallbackName ?? ''),
        phone: res.data!.phone.isNotEmpty
            ? res.data!.phone
            : (fallbackPhone ?? ''),
      );
      await _persistSession(withEmail);
      state =
          state.copyWith(user: withEmail, isLoggedIn: true, isLoading: false);
      return true;
    }
    state = state.copyWith(isLoading: false, error: res.error);
    return false;
  }

  // ── Credits helpers ──────────────────────────────────────────────────────
  bool get hasEnoughCredits =>
      (state.user?.credits ?? 0) >= AppConstants.creditsPerScan;

  Future<void> deductCredits() async {
    final current = state.user?.credits ?? 0;
    if (current < AppConstants.creditsPerScan) return;
    final updated =
        state.user!.copyWith(credits: current - AppConstants.creditsPerScan);
    await _prefs.setInt(AppConstants.keyCredits, updated.credits);
    await _prefs.setString('user_json', jsonEncode(updated.toJson()));
    state = state.copyWith(user: updated);
  }

  Future<void> addCredits(int amount) async {
    final updated =
        state.user!.copyWith(credits: (state.user!.credits) + amount);
    await _prefs.setInt(AppConstants.keyCredits, updated.credits);
    await _prefs.setString('user_json', jsonEncode(updated.toJson()));
    state = state.copyWith(user: updated);
  }

  Future<void> updateCreditsFromWallet(int credits) async {
    if (state.user == null) return;
    final updated = state.user!.copyWith(credits: credits);
    await _prefs.setInt(AppConstants.keyCredits, credits);
    await _prefs.setString('user_json', jsonEncode(updated.toJson()));
    state = state.copyWith(user: updated);
  }

  Future<bool> updateProfile({
    required String name,
    String? profileImagePath,
  }) async {
    if (state.user == null) return false;
    final currentUser = state.user!;
    final trimmedName = name.trim();
    final nextProfileImagePath = profileImagePath ?? currentUser.profileImagePath;
    var updated = currentUser.copyWith(
      name: trimmedName,
      profileImagePath: nextProfileImagePath,
    );

    final shouldSyncName = trimmedName.isNotEmpty && trimmedName != currentUser.name;
    if (shouldSyncName) {
      state = state.copyWith(isLoading: true, clearError: true);
      final api = ref.read(apiServiceProvider);
      final res = await api.updateProfile(
        userId: currentUser.id,
        name: trimmedName,
        email: currentUser.email,
        phone: currentUser.phone,
      );

      if (res.isSuccess && res.data != null) {
        updated = updated.copyWith(
          id: res.data!.id.isNotEmpty ? res.data!.id : currentUser.id,
          name: res.data!.name.isNotEmpty ? res.data!.name : trimmedName,
          phone: res.data!.phone.isNotEmpty ? res.data!.phone : currentUser.phone,
          email: res.data!.email.isNotEmpty ? res.data!.email : currentUser.email,
          token: res.data!.token.isNotEmpty ? res.data!.token : currentUser.token,
          credits: res.data!.credits > 0 ? res.data!.credits : currentUser.credits,
          profileImagePath: nextProfileImagePath ?? res.data!.profileImagePath,
        );
      } else {
        state = state.copyWith(isLoading: false, error: res.error);
        return false;
      }
    }

    await _persistSession(updated);
    state = state.copyWith(
      user: updated,
      isLoggedIn: true,
      isLoading: false,
      clearError: true,
    );
    return true;
  }

  Future<void> logout() async {
    final savedLanguage = _prefs.getString(AppConstants.keyLanguage);
    final savedFirstTime = _prefs.getBool(AppConstants.keyIsFirstTime);

    await _prefs.clear();

    if (savedLanguage != null && savedLanguage.isNotEmpty) {
      await _prefs.setString(AppConstants.keyLanguage, savedLanguage);
    }
    if (savedFirstTime != null) {
      await _prefs.setBool(AppConstants.keyIsFirstTime, savedFirstTime);
    }

    state = const AuthState();
  }

  void clearError() => state = state.copyWith(clearError: true);
}

final authProvider =
    NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
