import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../models/app_models.dart';
import '../providers/auth_provider.dart';
import '../providers/locale_provider.dart';
import '../l10n/app_localizations.dart';
import 'language_selection_screen.dart';
import 'legal_document_screen.dart';
import 'login_screen.dart';
import 'wallet_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final localeNotifier = ref.read(localeProvider.notifier);
    final l = AppLocalizations.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 380;
    final headerFontSize = isSmallScreen ? 24.0 : 28.0;

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
            child: CustomScrollView(
              slivers: [
                // Curved header
                SliverAppBar(
                  pinned: true,
                  expandedHeight: isSmallScreen ? 110 : 130,
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
                          padding: EdgeInsets.fromLTRB(20, 20, 20, 32),
                          child: Row(
                            children: [
                              const Text('⚙️', style: TextStyle(fontSize: 28)),
                              const SizedBox(width: 12),
                              Flexible(
                                child: Text(
                                  AppLocalizations.of(context).settings,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.nunito(
                                    fontSize: headerFontSize,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
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
                        // Profile card
                        _profileCard(context, ref, user, isSmallScreen)
                            .animate()
                            .fadeIn(duration: 400.ms),
                        const SizedBox(height: 24),

                        // Account section
                        _sectionTitle(context, l.t('account'), isSmallScreen),
                        const SizedBox(height: 12),
                        _settingsTile(
                          context,
                          icon: Icons.person_outline_rounded,
                          iconColor: const Color(0xFF2E7D32),
                          title: AppLocalizations.of(context).editProfile,
                          subtitle: user?.name ?? '',
                          onTap: () => _showEditProfileDialog(context, ref),
                          isSmallScreen: isSmallScreen,
                        ).animate().fadeIn(delay: 100.ms),
                        _settingsTile(
                          context,
                          icon: Icons.phone_outlined,
                          iconColor: const Color(0xFF0288D1),
                          title: l.phoneNumber,
                          subtitle: user?.phone ?? '',
                          onTap: null,
                          isSmallScreen: isSmallScreen,
                        ).animate().fadeIn(delay: 150.ms),

                        const SizedBox(height: 20),

                        // Preferences section
                        _sectionTitle(
                            context, l.t('preferences'), isSmallScreen),
                        const SizedBox(height: 12),
                        _settingsTile(
                          context,
                          icon: Icons.language_rounded,
                          iconColor: const Color(0xFF5D4037),
                          title: AppLocalizations.of(context).language,
                          subtitle: localeNotifier.currentLanguageName,
                          trailing: const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 14,
                            color: Color(0xFF9E9E9E),
                          ),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LanguageSelectionScreen(
                                  isOnboarding: false),
                            ),
                          ),
                          isSmallScreen: isSmallScreen,
                        ).animate().fadeIn(delay: 200.ms),
                        _settingsTile(
                          context,
                          icon: Icons.notifications_outlined,
                          iconColor: const Color(0xFFF9A825),
                          title: l.notifications,
                          subtitle: l.t('notification_alerts'),
                          trailing: Switch(
                            value: true,
                            onChanged: (_) {},
                            activeThumbColor: const Color(0xFF2E7D32),
                            activeTrackColor:
                                const Color(0xFF2E7D32).withValues(alpha: 0.3),
                          ),
                          onTap: null,
                          isSmallScreen: isSmallScreen,
                        ).animate().fadeIn(delay: 250.ms),

                        const SizedBox(height: 20),

                        // Credits section
                        _sectionTitle(
                            context, l.t('credits_billing'), isSmallScreen),
                        const SizedBox(height: 12),
                        _settingsTile(
                          context,
                          icon: Icons.account_balance_wallet_outlined,
                          iconColor: const Color(0xFF2E7D32),
                          title: AppLocalizations.of(context).myCredits,
                          subtitle:
                              "${user?.credits ?? 0} ${l.t('credits_available_suffix')}",
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFF9A825), Color(0xFFFFB74D)],
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              l.t('add_short'),
                              style: GoogleFonts.nunito(
                                color: const Color(0xFF5D4037),
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const WalletScreen(),
                            ),
                          ),
                          isSmallScreen: isSmallScreen,
                        ).animate().fadeIn(delay: 300.ms),

                        const SizedBox(height: 20),

                        // About section
                        _sectionTitle(context, l.t('about'), isSmallScreen),
                        const SizedBox(height: 12),
                        _settingsTile(
                          context,
                          icon: Icons.privacy_tip_outlined,
                          iconColor: const Color(0xFF5D4037),
                          title: AppLocalizations.of(context).privacyPolicy,
                          trailing: const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 14,
                            color: Color(0xFF9E9E9E),
                          ),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => LegalDocumentScreen(
                                title:
                                    AppLocalizations.of(context).privacyPolicy,
                                sections: _privacySections(),
                              ),
                            ),
                          ),
                          isSmallScreen: isSmallScreen,
                        ).animate().fadeIn(delay: 350.ms),
                        _settingsTile(
                          context,
                          icon: Icons.description_outlined,
                          iconColor: const Color(0xFF5D4037),
                          title: AppLocalizations.of(context).terms,
                          trailing: const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 14,
                            color: Color(0xFF9E9E9E),
                          ),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => LegalDocumentScreen(
                                title: AppLocalizations.of(context).terms,
                                sections: _termsSections(),
                              ),
                            ),
                          ),
                          isSmallScreen: isSmallScreen,
                        ).animate().fadeIn(delay: 400.ms),

                        const SizedBox(height: 20),

                        // Logout
                        _logoutButton(context, ref, isSmallScreen)
                            .animate()
                            .fadeIn(delay: 500.ms),

                        const SizedBox(height: 40),

                        // Footer
                        Center(
                          child: Column(
                            children: [
                              const Text('🌱', style: TextStyle(fontSize: 32)),
                              const SizedBox(height: 8),
                              Text(
                                l.appName,
                                style: GoogleFonts.nunito(
                                  fontSize: isSmallScreen ? 14 : 16,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF2E7D32),
                                ),
                              ),
                              Text(
                                l.madeForFarmers,
                                style: GoogleFonts.nunito(
                                  fontSize: isSmallScreen ? 10 : 12,
                                  color: const Color(0xFF5D4037),
                                ),
                              ),
                            ],
                          ),
                        ).animate().fadeIn(delay: 600.ms),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _profileCard(BuildContext context, WidgetRef ref, UserModel? user,
      bool isSmallScreen) {
    final avatarSize = isSmallScreen ? 64.0 : 80.0;
    final fontSize = isSmallScreen ? 18.0 : 20.0;

    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E7D32).withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _pickProfileImage(context, ref),
            child: Container(
              width: avatarSize,
              height: avatarSize,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.5),
                  width: 2,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipOval(
                child: user?.profileImagePath?.trim().isNotEmpty == true
                    ? Image.file(
                        File(user!.profileImagePath!),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _defaultAvatar(user, avatarSize),
                      )
                    : _defaultAvatar(user, avatarSize),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Flexible(
                  child: Text(
                    user?.name ?? AppLocalizations.of(context).t('farmer'),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.nunito(
                      color: Colors.white,
                      fontSize: fontSize,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Flexible(
                  child: Text(
                    user?.phone ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.nunito(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('💰', style: TextStyle(fontSize: 12)),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          '${user?.credits ?? 0} ${AppLocalizations.of(context).credits}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.nunito(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title, bool isSmallScreen) {
    return Row(
      children: [
        Container(
          width: 4,
          height: isSmallScreen ? 16 : 20,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFF9A825), Color(0xFF2E7D32)],
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: GoogleFonts.nunito(
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
            fontSize: isSmallScreen ? 12 : 14,
            color: const Color(0xFF2E7D32),
          ),
        ),
      ],
    );
  }

  Widget _defaultAvatar(UserModel? user, double avatarSize) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF9A825), Color(0xFFFFB74D)],
        ),
      ),
      child: Center(
        child: Text(
          (user?.name.isNotEmpty == true)
              ? user!.name[0].toUpperCase()
              : '👨‍🌾',
          style: TextStyle(fontSize: avatarSize * 0.45),
        ),
      ),
    );
  }

  Future<void> _pickProfileImage(BuildContext context, WidgetRef ref) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1024,
      );
      if (picked == null) return;

      final currentName = ref.read(authProvider).user?.name ?? '';
      await ref.read(authProvider.notifier).updateProfile(
            name: currentName,
            profileImagePath: picked.path,
          );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).t('profile_photo_updated'),
            ),
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).t('profile_photo_failed'),
            ),
          ),
        );
      }
    }
  }

  Widget _settingsTile(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    Widget? trailing,
    required VoidCallback? onTap,
    required bool isSmallScreen,
  }) {
    final iconSize = isSmallScreen ? 40.0 : 48.0;
    final titleSize = isSmallScreen ? 14.0 : 16.0;
    final subtitleSize = isSmallScreen ? 11.0 : 13.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 12 : 16,
          vertical: isSmallScreen ? 10 : 14,
        ),
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
              width: iconSize,
              height: iconSize,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    iconColor.withValues(alpha: 0.1),
                    iconColor.withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: iconColor, size: iconSize * 0.5),
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
                      fontSize: titleSize,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF2E7D32),
                    ),
                  ),
                  if (subtitle != null && subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.nunito(
                        fontSize: subtitleSize,
                        color: const Color(0xFF5D4037),
                      ),
                    ),
                ],
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  Widget _logoutButton(
      BuildContext context, WidgetRef ref, bool isSmallScreen) {
    return GestureDetector(
      onTap: () => _confirmLogout(context, ref),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 12 : 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFFFFF3E0),
              const Color(0xFFFFE0B2),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFF9A825).withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.logout_rounded,
              color: Color(0xFFF9A825),
              size: 22,
            ),
            const SizedBox(width: 10),
            Text(
              AppLocalizations.of(context).logout,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.nunito(
                color: const Color(0xFFF9A825),
                fontWeight: FontWeight.w800,
                fontSize: isSmallScreen ? 14 : 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: const Color(0xFFFAFAF5),
        title: Text(
          AppLocalizations.of(context).t('logout_question'),
          style: GoogleFonts.nunito(
            fontWeight: FontWeight.w800,
            color: const Color(0xFF2E7D32),
          ),
        ),
        content: Text(
          AppLocalizations.of(context).logoutConfirm,
          style: GoogleFonts.nunito(
            color: const Color(0xFF5D4037),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              AppLocalizations.of(context).cancel,
              style: GoogleFonts.nunito(
                color: const Color(0xFF5D4037),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (_) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF9A825),
              foregroundColor: const Color(0xFF5D4037),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              AppLocalizations.of(context).logout,
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context, WidgetRef ref) {
    final user = ref.read(authProvider).user;
    final controller = TextEditingController(text: user?.name ?? '');
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 380;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: const Color(0xFFFAFAF5),
        title: Text(
          AppLocalizations.of(context).editProfile,
          style: GoogleFonts.nunito(
            fontWeight: FontWeight.w800,
            color: const Color(0xFF2E7D32),
          ),
        ),
        content: Container(
          width: isSmallScreen ? double.infinity : 400,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context).fullName,
              prefixIcon: const Icon(Icons.person_outline_rounded),
              labelStyle: GoogleFonts.nunito(
                color: const Color(0xFF5D4037),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: const Color(0xFF2E7D32).withValues(alpha: 0.2),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: const Color(0xFF2E7D32).withValues(alpha: 0.2),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFF2E7D32)),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            textCapitalization: TextCapitalization.words,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              AppLocalizations.of(context).cancel,
              style: GoogleFonts.nunito(
                color: const Color(0xFF5D4037),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                final ok = await ref.read(authProvider.notifier).updateProfile(
                      name: controller.text.trim(),
                    );
                if (!context.mounted) return;
                if (ok) {
                  Navigator.pop(context);
                  return;
                }
                final error = ref.read(authProvider).error ?? 'Could not update profile';
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(error)),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              AppLocalizations.of(context).save,
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, String>> _privacySections() => const [
        {
          'title': 'Information We Collect',
          'body':
              'Farmlyt AI stores the information you provide during sign up such as your name, email, phone number, language preference, wallet balance, and profile photo. The app also processes crop images you upload for disease analysis and can read device location only for weather and nearby farming context.',
        },
        {
          'title': 'How We Use Information',
          'body':
              'We use your details to authenticate your account, verify OTP login, show wallet balance, power crop detection, improve app reliability, and deliver a personalized language experience throughout the app.',
        },
        {
          'title': 'Images And Predictions',
          'body':
              'Uploaded crop images and prediction outputs may be stored on the connected backend so that analysis history, result images, and treatment recommendations can be shown back inside the app.',
        },
        {
          'title': 'Payments',
          'body':
              'Wallet top-ups are processed through Razorpay. Farmlyt AI does not intentionally store your full card or banking details inside the app.',
        },
        {
          'title': 'User Control',
          'body':
              'You can log out at any time, update your profile name and photo, and change language preferences from Settings. If you need account support, contact the app operator managing the backend services.',
        },
      ];

  List<Map<String, String>> _termsSections() => const [
        {
          'title': 'Service Scope',
          'body':
              'Farmlyt AI provides crop detection, farming tips, weather context, wallet credits, and account tools to support farmers. The app is designed to assist decision making and should not replace professional agricultural advice in critical cases.',
        },
        {
          'title': 'Account Access',
          'body':
              'Users must provide valid information during registration or login. OTP verification is required for email or phone based access. Once logged in, the app may keep the session active on the device until logout.',
        },
        {
          'title': 'Credits And Billing',
          'body':
              'Crop analysis may consume wallet credits. Recharge amounts, scan costs, and payment verification depend on the live backend configuration available at the time of use.',
        },
        {
          'title': 'Uploads',
          'body':
              'By uploading crop images, you confirm that you have permission to use the images for analysis. The service may store original and predicted images to return results and maintain scan history.',
        },
        {
          'title': 'Availability',
          'body':
              'Features depending on internet connectivity, third-party services, or backend APIs may occasionally be unavailable. Farmlyt AI may add or remove supported categories and crops as backend services evolve.',
        },
      ];
}

class _CurvedBottomClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 20);
    path.quadraticBezierTo(
      size.width / 2,
      size.height,
      size.width,
      size.height - 20,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
