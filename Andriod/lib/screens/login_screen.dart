import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../widgets/fitted_app_text.dart';
import 'otp_screen.dart';
import 'email_otp_screen.dart';
import 'terms_privacy_policy_screen.dart';

// ─── Login mode enum ──────────────────────────────────────────────────────────
enum _LoginMode { phone, email }

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  // ── Controllers ──────────────────────────────────────────────────────────
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  late AnimationController _tabController;

  // ── State ────────────────────────────────────────────────────────────────
  _LoginMode _mode = _LoginMode.phone;
  String _selectedCountryCode = '+91';
  String _selectedFlag = '🇮🇳';
  bool _isLogin = true; // login vs register toggle for email mode

  @override
  void initState() {
    super.initState();
    _tabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  // ── Navigation ────────────────────────────────────────────────────────────

  /// Phone mode → Firebase OTP screen (existing flow)
  void _continuePhone() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OtpScreen(
          name: _nameController.text.trim(),
          phone: '$_selectedCountryCode${_phoneController.text.trim()}',
        ),
      ),
    );
  }

  /// Email mode → API login / register
  Future<void> _continueEmail() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final auth = ref.read(authProvider.notifier);
    final email = _emailController.text.trim();

    if (_isLogin) {
      // LOGIN FLOW
      final result = await auth.emailLogin(email: email);
      if (!mounted) return;
      if (result != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EmailOtpScreen(
              email: email,
              userId: result.userId, // <--- Correct: Passing String
              autoOtp: result.otp,
              displayName: result.displayName ?? _nameController.text.trim(),
              phone: result.phone ?? _phoneController.text.trim(),
            ),
          ),
        );
      } else {
        _showError(
          ref.read(authProvider).error ??
              AppLocalizations.of(context).t('login_failed'),
        );
      }
    } else {
      // REGISTER FLOW
      final result = await auth.emailRegister(
        name: _nameController.text.trim(),
        email: email,
        phone: _phoneController.text.trim(),
      );
      if (!mounted) return;

      if (result != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EmailOtpScreen(
              email: email,
              userId: result.userId,
              autoOtp: result.otp,
              displayName: result.displayName ?? _nameController.text.trim(),
              phone: result.phone ?? _phoneController.text.trim(),
            ),
          ),
        );
      } else {
        _showError(
          ref.read(authProvider).error ??
              AppLocalizations.of(context).t('login_failed'),
        );
      }
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: const Color(0xFF5D4037),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  void _switchMode(_LoginMode mode) {
    if (_mode == mode) return;
    setState(() {
      _mode = mode;
      _formKey.currentState?.reset();
      ref.read(authProvider.notifier).clearError();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: Opacity(
              opacity: 0.03,
              child: Wrap(children: const [
                Text('🌾', style: TextStyle(fontSize: 100)),
                Text('🌱', style: TextStyle(fontSize: 120)),
                Text('🍃', style: TextStyle(fontSize: 90)),
                Text('🌿', style: TextStyle(fontSize: 110)),
              ]),
            ),
          ),
        ),
        Scaffold(
          backgroundColor: const Color(0xFFF5F7F5),
          body: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // ── Curved green header ─────────────────────────────────
                  _buildHeader(),

                  // ── Form section ────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle(),
                          const SizedBox(height: 20),

                          // ── Mode toggle (Phone / Email) ─────────────────
                          _buildModeToggle(),
                          const SizedBox(height: 24),

                          // ── Fields ──────────────────────────────────────
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: _mode == _LoginMode.phone
                                ? _buildPhoneFields()
                                : _buildEmailFields(),
                          ),

                          const SizedBox(height: 28),

                          // ── Submit button ───────────────────────────────
                          _buildSubmitButton(authState.isLoading),

                          const SizedBox(height: 20),

                          // ── Terms ───────────────────────────────────────
                          _buildTermsText(),
                          const SizedBox(height: 16),
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

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    final l = AppLocalizations.of(context);
    return ClipPath(
      clipper: _CurvedClipper(),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(24, 40, 24, 52),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.6), width: 2),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 4))
                ],
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/logo.png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: const Color(0xFFF9A825),
                    child: const Center(
                        child: Text('🌱', style: TextStyle(fontSize: 36))),
                  ),
                ),
              ),
            ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
            const SizedBox(height: 24),
            Text(
              l.welcome,
              style: GoogleFonts.nunito(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                height: 1.2,
              ),
            ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.2, end: 0),
            const SizedBox(height: 10),
            Text(
              l.smartFarming,
              style: GoogleFonts.nunito(
                fontSize: 15,
                color: Colors.white.withValues(alpha: 0.9),
                fontWeight: FontWeight.w500,
              ),
            ).animate().fadeIn(delay: 300.ms),
          ],
        ),
      ),
    );
  }

  // ── Section title ─────────────────────────────────────────────────────────
  Widget _buildSectionTitle() {
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          const Text('👋', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Text(
            l.enterDetails,
            style: GoogleFonts.nunito(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF2E7D32),
            ),
          ),
        ]),
        const SizedBox(height: 6),
        Container(
          width: 60,
          height: 3,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFFF9A825), Color(0xFF2E7D32)]),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          l.otpSubtitle,
          style:
              GoogleFonts.nunito(fontSize: 13, color: const Color(0xFF5D4037)),
        ),
      ],
    ).animate().fadeIn(delay: 300.ms);
  }

  // ── Mode toggle ───────────────────────────────────────────────────────────
  Widget _buildModeToggle() {
    final l = AppLocalizations.of(context);
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2EE),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: _toggleBtn(
              label: '📱  ${l.t('phone')}',
              active: _mode == _LoginMode.phone,
              onTap: () => _switchMode(_LoginMode.phone),
            ),
          ),
          Expanded(
            child: _toggleBtn(
              label: '✉️  ${l.t('email')}',
              active: _mode == _LoginMode.email,
              onTap: () => _switchMode(_LoginMode.email),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 350.ms);
  }

  Widget _toggleBtn(
      {required String label,
      required bool active,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.nunito(
            fontWeight: active ? FontWeight.w800 : FontWeight.w600,
            fontSize: 14,
            color: active ? const Color(0xFF2E7D32) : const Color(0xFF9E9E9E),
          ),
        ),
      ),
    );
  }

  // ── Phone fields ──────────────────────────────────────────────────────────
  Widget _buildPhoneFields() {
    final l = AppLocalizations.of(context);
    return Column(
      key: const ValueKey('phone'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _inputField(
          controller: _nameController,
          label: l.fullName,
          hint: l.enterName,
          icon: Icons.person_outline_rounded,
          validator: (v) {
            if (v == null || v.trim().isEmpty) {
              return l.t('please_enter_name');
            }
            if (v.trim().length < 2) {
              return l.t('name_min_chars');
            }
            return null;
          },
          capitalization: TextCapitalization.words,
        ),
        const SizedBox(height: 16),
        Text(l.phoneNumber,
            style: GoogleFonts.nunito(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF2E7D32))),
        const SizedBox(height: 8),
        Row(
          children: [
            GestureDetector(
              onTap: _showCountryPicker,
              child: Container(
                height: 58,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                      color: const Color(0xFF2E7D32).withValues(alpha: 0.2)),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 4)
                  ],
                ),
                child: Row(
                  children: [
                    Text(_selectedFlag, style: const TextStyle(fontSize: 22)),
                    const SizedBox(width: 6),
                    Text(_selectedCountryCode,
                        style: GoogleFonts.nunito(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF2E7D32))),
                    const Icon(Icons.arrow_drop_down,
                        color: Color(0xFF2E7D32), size: 18),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _phoneField(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _phoneField() {
    final l = AppLocalizations.of(context);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
          )
        ],
      ),
      child: TextFormField(
        controller: _phoneController,
        keyboardType: TextInputType.phone,
        maxLength: 10,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          hintText: '9876543210',
          counterText: '',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          hintStyle: GoogleFonts.nunito(color: const Color(0xFF9E9E9E)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        ),
        validator: (v) {
          if (v == null || v.isEmpty) return l.t('enter_phone_number');
          if (v.length < 10) return l.t('enter_valid_phone');
          return null;
        },
      ),
    );
  }

  // ── Email fields ──────────────────────────────────────────────────────────
  Widget _buildEmailFields() {
    final l = AppLocalizations.of(context);
    return Column(
      key: const ValueKey('email'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Login / Register sub-toggle
        Row(
          children: [
            _subToggleBtn(
                l.t('login'), _isLogin, () => setState(() => _isLogin = true)),
            const SizedBox(width: 12),
            _subToggleBtn(l.t('register'), !_isLogin,
                () => setState(() => _isLogin = false)),
          ],
        ),
        const SizedBox(height: 20),

        // Name + Phone only in register mode
        if (!_isLogin) ...[
          _inputField(
            controller: _nameController,
            label: l.fullName,
            hint: l.enterName,
            icon: Icons.person_outline_rounded,
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return l.t('please_enter_name');
              }
              return null;
            },
            capitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 14),
          _inputField(
            controller: _phoneController,
            label: l.t('phone_optional'),
            hint: '9876543210',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: 14),
        ],

        _inputField(
          controller: _emailController,
          label: l.t('email_address'),
          hint: 'you@example.com',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          validator: (v) {
            if (v == null || v.trim().isEmpty) {
              return l.t('enter_email_address');
            }
            if (!RegExp(r'^[\w.-]+@[\w.-]+\.\w+$').hasMatch(v.trim())) {
              return l.t('enter_valid_email');
            }
            return null;
          },
        ),
        const SizedBox(height: 14),
      ],
    );
  }

  Widget _subToggleBtn(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF2E7D32) : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: active
                ? const Color(0xFF2E7D32)
                : const Color(0xFF2E7D32).withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: active
              ? [
                  BoxShadow(
                      color: const Color(0xFF2E7D32).withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2))
                ]
              : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.nunito(
            fontWeight: FontWeight.w800,
            fontSize: 13,
            color: active ? Colors.white : const Color(0xFF5D4037),
          ),
        ),
      ),
    );
  }

  // ── Reusable input field ──────────────────────────────────────────────────
  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization capitalization = TextCapitalization.none,
    List<TextInputFormatter>? inputFormatters,
    bool obscureText = false,
    Widget? suffix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.nunito(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF5D4037))),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 1))
            ],
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            textCapitalization: capitalization,
            inputFormatters: inputFormatters,
            obscureText: obscureText,
            style: GoogleFonts.nunito(
                fontSize: 15, color: const Color(0xFF2E2E2E)),
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: Icon(icon, color: const Color(0xFF9E9E9E), size: 20),
              suffixIcon: suffix,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(
                    color: const Color(0xFF2E7D32).withValues(alpha: 0.15)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide:
                    const BorderSide(color: Color(0xFF2E7D32), width: 1.5),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide:
                    const BorderSide(color: Color(0xFFF44336), width: 1.5),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide:
                    const BorderSide(color: Color(0xFFF44336), width: 1.5),
              ),
              filled: true,
              fillColor: Colors.white,
              hintStyle: GoogleFonts.nunito(
                  color: const Color(0xFF9E9E9E), fontSize: 14),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            ),
            validator: validator,
          ),
        ),
      ],
    );
  }

  // ── Submit button ─────────────────────────────────────────────────────────
  Widget _buildSubmitButton(bool isLoading) {
    final l = AppLocalizations.of(context);
    return SizedBox(
      height: 56,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading
            ? null
            : () {
                if (_mode == _LoginMode.phone) {
                  _continuePhone();
                } else {
                  _continueEmail();
                }
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFF9A825),
          foregroundColor: const Color(0xFF5D4037),
          disabledBackgroundColor:
              const Color(0xFFF9A825).withValues(alpha: 0.6),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 4,
          shadowColor: const Color(0xFFF9A825).withValues(alpha: 0.3),
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5D4037)),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: FittedAppText(
                      _mode == _LoginMode.phone
                          ? l.continueBtn
                          : (_isLogin ? l.t('login') : l.t('register')),
                      style: GoogleFonts.nunito(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF5D4037),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Icon(Icons.arrow_forward_rounded, size: 22),
                ],
              ),
      ),
    ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2, end: 0);
  }

  // ── Terms text ────────────────────────────────────────────────────────────
  Widget _buildTermsText() {
    final l = AppLocalizations.of(context);
    return Center(
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            l.byContinuing,
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontSize: 12,
              color: const Color(0xFF5D4037),
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const TermsPrivacyPolicyScreen(),
              ),
            ),
            child: Text(
              l.termsPrivacy,
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                fontSize: 12,
                color: const Color(0xFF2E7D32),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 700.ms);
  }

  // ── Country picker ────────────────────────────────────────────────────────
  void _showCountryPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFF5F7F5),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _CountryPickerSheet(
        onSelect: (flag, code) => setState(() {
          _selectedFlag = flag;
          _selectedCountryCode = code;
        }),
      ),
    );
  }
}

// ─── Country picker sheet ─────────────────────────────────────────────────────
class _CountryPickerSheet extends StatelessWidget {
  final void Function(String flag, String code) onSelect;
  const _CountryPickerSheet({required this.onSelect});

  static const _countries = [
    {'flag': '🇮🇳', 'name': 'India', 'code': '+91'},
    {'flag': '🇺🇸', 'name': 'United States', 'code': '+1'},
    {'flag': '🇬🇧', 'name': 'United Kingdom', 'code': '+44'},
    {'flag': '🇦🇺', 'name': 'Australia', 'code': '+61'},
    {'flag': '🇸🇬', 'name': 'Singapore', 'code': '+65'},
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 12),
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: const Color(0xFF5D4037).withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 16),
        Text('Select Country Code',
            style: GoogleFonts.nunito(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF2E7D32))),
        const SizedBox(height: 8),
        ..._countries.map((c) => ListTile(
              leading: Text(c['flag']!, style: const TextStyle(fontSize: 28)),
              title: Text(c['name']!,
                  style: GoogleFonts.nunito(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF5D4037))),
              trailing: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)]),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(c['code']!,
                    style: GoogleFonts.nunito(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 13)),
              ),
              onTap: () {
                onSelect(c['flag']!, c['code']!);
                Navigator.pop(context);
              },
            )),
        const SizedBox(height: 20),
      ],
    );
  }
}

// ─── Curved clip ──────────────────────────────────────────────────────────────
class _CurvedClipper extends CustomClipper<Path> {
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
