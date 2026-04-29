import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

import '../utils/app_constants.dart';
import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../widgets/fitted_app_text.dart';
import 'language_selection_screen.dart';
import 'dashboard_screen.dart';

class OtpScreen extends ConsumerStatefulWidget {
  final String name;
  final String phone;

  const OtpScreen({super.key, required this.name, required this.phone});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  String _verificationId = '';
  bool _isLoading = false;
  bool _isSending = true;
  String? _error;
  int _resendSeconds = 30;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _sendOtp();
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

  void _startResendTimer() {
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

  Future<void> _sendOtp() async {
    setState(() {
      _isSending = true;
      _error = null;
    });

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: widget.phone,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          setState(() {
            _error = e.message ??
                AppLocalizations.of(context).t('verification_failed');
            _isSending = false;
          });
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() {
            _verificationId = verificationId;
            _isSending = false;
          });
          _startResendTimer();
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (e) {
      setState(() {
        _error = AppLocalizations.of(context).t('failed_send_otp');
        _isSending = false;
      });
    }
  }

  Future<void> _verifyOtp() async {
    if (_otp.length != 6) {
      setState(
          () => _error = AppLocalizations.of(context).t('please_enter_otp'));
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId,
        smsCode: _otp,
      );
      await _signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      setState(() {
        _error = e.message ?? AppLocalizations.of(context).t('invalid_otp');
        _isLoading = false;
      });
    }
  }

  Future<void> _signInWithCredential(PhoneAuthCredential credential) async {
    try {
      await FirebaseAuth.instance.signInWithCredential(credential);
      final success = await ref
          .read(authProvider.notifier)
          .register(name: widget.name, phone: widget.phone);

      if (!mounted) return;
      if (success) {
        final prefs = ref.read(sharedPreferencesProvider);
        final hasLang = prefs.getString(AppConstants.keyLanguage) != null;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => hasLang
                ? const DashboardScreen()
                : const LanguageSelectionScreen(isOnboarding: true),
          ),
          (_) => false,
        );
      }
    } catch (e) {
      setState(() {
        _error = AppLocalizations.of(context).t('login_failed');
        _isLoading = false;
      });
    }
  }

  Widget _buildOtpBoxes(bool isSmallScreen) {
    final screenWidth = MediaQuery.of(context).size.width;
    final padding = isSmallScreen ? 20.0 : 24.0;
    final margin = isSmallScreen ? 3.0 : 6.0;
    final availableWidth = screenWidth - (padding * 2);

    double boxSize = isSmallScreen ? 44.0 : 52.0;
    if ((boxSize * 6) + (margin * 12) > availableWidth) {
      boxSize = (availableWidth - (margin * 12)) / 6;
    }

    final fontSize = boxSize * 0.45;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(6, (i) {
        return Container(
          width: boxSize,
          height: boxSize + 12,
          margin: EdgeInsets.symmetric(horizontal: margin),
          child: TextField(
            controller: _controllers[i],
            focusNode: _focusNodes[i],
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            maxLength: 1,
            autofocus: i == 0,
            style: GoogleFonts.nunito(
              fontSize: fontSize,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF2E7D32),
            ),
            decoration: InputDecoration(
              counterText: '',
              contentPadding: EdgeInsets.zero,
              filled: true,
              fillColor: _controllers[i].text.isNotEmpty
                  ? const Color(0xFF2E7D32).withValues(alpha: 0.08)
                  : Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: const Color(0xFF2E7D32).withValues(alpha: 0.2),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: Color(0xFF2E7D32),
                  width: 2,
                ),
              ),
            ),
            onChanged: (val) {
              setState(() {});
              if (val.isNotEmpty && i < 5) {
                _focusNodes[i + 1].requestFocus();
              } else if (val.isEmpty && i > 0) {
                _focusNodes[i - 1].requestFocus();
              }
              if (_otp.length == 6) {
                _verifyOtp();
              }
            },
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 380;
    final headerFontSize = isSmallScreen ? 24.0 : 28.0;
    final logoSize = isSmallScreen ? 100.0 : 120.0;

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
          appBar: AppBar(
            title: Text(
              l.t('verify_phone'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF2E7D32),
              ),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => Navigator.pop(context),
                color: const Color(0xFF2E7D32),
              ),
            ),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.all(isSmallScreen ? 20 : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: logoSize,
                      height: logoSize,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFF9A825), Color(0xFFFFB74D)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFFF9A825).withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text('📱', style: TextStyle(fontSize: 56)),
                      ),
                    ),
                  ).animate().scale(
                        duration: 600.ms,
                        curve: Curves.elasticOut,
                      ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      const Text('🔐', style: TextStyle(fontSize: 24)),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          l.enterOtp,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.nunito(
                            fontSize: headerFontSize,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF2E7D32),
                          ),
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 200.ms),
                  const SizedBox(height: 8),
                  Container(
                    width: 80,
                    height: 3,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF9A825), Color(0xFF2E7D32)],
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ).animate().fadeIn(delay: 250.ms),
                  const SizedBox(height: 16),
                  Text(
                    l.otpSent,
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      color: const Color(0xFF5D4037),
                    ),
                  ).animate().fadeIn(delay: 300.ms),
                  Text(
                    widget.phone,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.nunito(
                      fontSize: isSmallScreen ? 16 : 18,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF2E7D32),
                    ),
                  ).animate().fadeIn(delay: 350.ms),
                  const SizedBox(height: 40),
                  if (_isSending)
                    Center(
                      child: Column(
                        children: [
                          const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF2E7D32)),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            l.t('sending_otp'),
                            style: GoogleFonts.nunito(
                              color: const Color(0xFF5D4037),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    _buildOtpBoxes(isSmallScreen)
                        .animate()
                        .fadeIn(delay: 400.ms),
                  if (_error != null) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFFFFF3E0),
                            const Color(0xFFFFE0B2),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFF9A825).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Color(0xFFF9A825),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _error!,
                              style: GoogleFonts.nunito(
                                color: const Color(0xFF5D4037),
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                  SizedBox(
                    height: 56,
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _verifyOtp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF9A825),
                        foregroundColor: const Color(0xFF5D4037),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 4,
                        shadowColor:
                            const Color(0xFFF9A825).withValues(alpha: 0.3),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    Color(0xFF5D4037)),
                              ),
                            )
                          : FittedAppText(
                              l.verifyOtp,
                              style: GoogleFonts.nunito(
                                fontSize: isSmallScreen ? 16 : 18,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF5D4037),
                              ),
                            ),
                    ),
                  ).animate().fadeIn(delay: 500.ms),
                  const SizedBox(height: 24),
                  Center(
                    child: _resendSeconds > 0
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2E7D32)
                                  .withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: FittedAppText(
                              '${l.resendIn} $_resendSeconds ${l.seconds}',
                              style: GoogleFonts.nunito(
                                fontSize: isSmallScreen ? 11 : 13,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF5D4037),
                              ),
                            ),
                          )
                        : TextButton(
                            onPressed: _sendOtp,
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF2E7D32),
                            ),
                            child: FittedAppText(
                              l.resendOtp,
                              style: GoogleFonts.nunito(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF2E7D32),
                              ),
                            ),
                          ),
                  ).animate().fadeIn(delay: 600.ms),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
