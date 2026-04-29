import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../widgets/fitted_app_text.dart';
import 'language_selection_screen.dart';
import 'dashboard_screen.dart';

class EmailOtpScreen extends ConsumerStatefulWidget {
  final String email;
  final String userId;
  final String? autoOtp; // ← OTP from API response for auto-fill
  final String? displayName;
  final String? phone;

  const EmailOtpScreen({
    super.key,
    required this.email,
    required this.userId,
    this.autoOtp,
    this.displayName,
    this.phone,
  });

  @override
  ConsumerState<EmailOtpScreen> createState() => _EmailOtpScreenState();
}

class _EmailOtpScreenState extends ConsumerState<EmailOtpScreen> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _isLoading = false;
  String? _error;
  int _resendSeconds = 30;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
    // Auto-fill if OTP was returned in API response
    if (widget.autoOtp != null && widget.autoOtp!.length == 6) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fillOtp(widget.autoOtp!);
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    _timer?.cancel();
    super.dispose();
  }

  String get _otp => _controllers.map((c) => c.text).join();

  void _startTimer() {
    setState(() => _resendSeconds = 30);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_resendSeconds > 0) {
        setState(() => _resendSeconds--);
      } else {
        t.cancel();
      }
    });
  }

  /// Fill all OTP boxes automatically
  void _fillOtp(String otp) {
    for (int i = 0; i < 6 && i < otp.length; i++) {
      _controllers[i].text = otp[i];
    }
    setState(() {});
    // Auto-verify after filling
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted && _otp.length == 6) _verify();
    });
  }

  Future<void> _resendOtp() async {
    final l = AppLocalizations.of(context);
    _startTimer();
    final result = await ref.read(authProvider.notifier).emailLogin(
          email: widget.email,
        );
    if (mounted) {
      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l.t('otp_resent_success')),
            backgroundColor: const Color(0xFF2E7D32),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      } else {
        setState(() =>
            _error = ref.read(authProvider).error ?? l.t('resend_otp_failed'));
      }
    }
  }

  Future<void> _verify() async {
    final l = AppLocalizations.of(context);
    if (_otp.length != 6) {
      setState(() => _error = l.t('please_enter_otp'));
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final ok = await ref.read(authProvider.notifier).verifyEmailOtp(
          userId: widget.userId,
          otp: _otp,
          email: widget.email,
          fallbackName: widget.displayName,
          fallbackPhone: widget.phone,
        );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (ok) {
      final prefs = ref.read(sharedPreferencesProvider);
      final hasLang = prefs.getString('selected_language') != null;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => hasLang
              ? const DashboardScreen()
              : const LanguageSelectionScreen(isOnboarding: true),
        ),
        (_) => false,
      );
    } else {
      setState(() {
        _error = ref.read(authProvider).error ?? l.t('verification_failed');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(l.verifyOtp,
            style: GoogleFonts.nunito(
                fontWeight: FontWeight.w700, color: const Color(0xFF2E7D32))),
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2))
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            color: const Color(0xFF2E7D32),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFFF9A825), Color(0xFFFFB74D)]),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                        color: const Color(0xFFF9A825).withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8))
                  ],
                ),
                child: const Text('✉️', style: TextStyle(fontSize: 52)),
              ),
            ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),

            const SizedBox(height: 32),

            Row(children: [
              const Text('🔐', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Text(l.verifyOtp,
                  style: GoogleFonts.nunito(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF2E7D32))),
            ]).animate().fadeIn(delay: 200.ms),

            const SizedBox(height: 8),
            Container(
              width: 70,
              height: 3,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFFF9A825), Color(0xFF2E7D32)]),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 14),
            Text(l.otpSent,
                style: GoogleFonts.nunito(
                    fontSize: 13, color: const Color(0xFF5D4037))),
            Text(widget.email,
                style: GoogleFonts.nunito(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF2E7D32))),

            // Show OTP hint if available (for testing/development)
            if (widget.autoOtp != null) ...[
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D32).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: const Color(0xFF2E7D32).withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline,
                        color: Color(0xFF2E7D32), size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'OTP: ${widget.autoOtp}',
                      style: GoogleFonts.nunito(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF2E7D32)),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => _fillOtp(widget.autoOtp!),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2E7D32),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Auto Fill',
                          style: GoogleFonts.nunito(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 36),

            // OTP boxes
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(6, (i) => _otpBox(i)),
            ).animate().fadeIn(delay: 300.ms),

            // Error
            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: const Color(0xFFF9A825).withValues(alpha: 0.3)),
                ),
                child: Row(children: [
                  const Icon(Icons.error_outline, color: Color(0xFFF9A825)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(_error!,
                        style: GoogleFonts.nunito(
                            color: const Color(0xFF5D4037), fontSize: 13)),
                  ),
                ]),
              ),
            ],

            const SizedBox(height: 32),

            // Verify button
            SizedBox(
              height: 56,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _verify,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF9A825),
                  foregroundColor: const Color(0xFF5D4037),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  elevation: 4,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Color(0xFF5D4037)),
                        ))
                    : FittedAppText('Verify OTP',
                        style: GoogleFonts.nunito(
                            fontSize: 18, fontWeight: FontWeight.w800)),
              ),
            ).animate().fadeIn(delay: 400.ms),

            const SizedBox(height: 20),

            // Resend
            Center(
              child: _resendSeconds > 0
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E7D32).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: FittedAppText(
                        'Resend in $_resendSeconds s',
                        style: GoogleFonts.nunito(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF5D4037)),
                      ),
                    )
                  : TextButton(
                      onPressed: _resendOtp,
                      child: FittedAppText('Resend OTP',
                          style: GoogleFonts.nunito(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF2E7D32))),
                    ),
            ).animate().fadeIn(delay: 500.ms),
          ],
        ),
      ),
    );
  }

  Widget _otpBox(int i) {
    return Flexible(
      child: Container(
        width: 48,
        height: 58,
        margin: const EdgeInsets.symmetric(horizontal: 3),
        child: TextField(
          controller: _controllers[i],
          focusNode: _focusNodes[i],
          textAlign: TextAlign.center,
          textAlignVertical: TextAlignVertical.center,
          keyboardType: TextInputType.number,
          maxLength: 1,
          autofocus: i == 0,
          style: GoogleFonts.nunito(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF2E7D32)),
          decoration: InputDecoration(
            counterText: '',
            contentPadding: EdgeInsets.zero,
            filled: true,
            fillColor: _controllers[i].text.isNotEmpty
                ? const Color(0xFF2E7D32).withValues(alpha: 0.08)
                : Colors.white,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                  color: const Color(0xFF2E7D32).withValues(alpha: 0.25)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
            ),
          ),
          onChanged: (val) {
            setState(() {});
            if (val.isNotEmpty && i < 5) {
              _focusNodes[i + 1].requestFocus();
            } else if (val.isEmpty && i > 0) {
              _focusNodes[i - 1].requestFocus();
            }
            if (_otp.length == 6) _verify();
          },
        ),
      ),
    );
  }
}
