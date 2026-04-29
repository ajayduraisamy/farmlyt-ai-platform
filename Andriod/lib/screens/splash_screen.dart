import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/agri_titles_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/farming_tips_provider.dart';
import '../providers/wallet_provider.dart';
import '../providers/weather_provider.dart';
import '../utils/app_constants.dart';
import '../l10n/app_localizations.dart';
import 'login_screen.dart';
import 'language_selection_screen.dart';
import 'dashboard_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _preloadAndNavigate();
  }

  /// Restores the auth session, then fires all critical API preloads in
  /// PARALLEL alongside the minimum splash delay.  The dashboard therefore
  /// opens with data already in cache — no skeleton flash on first load.
  Future<void> _preloadAndNavigate() async {
    // Restore session first (sync read from SharedPreferences — very fast)
    await ref.read(authProvider.notifier).refreshSession();
    final authState = ref.read(authProvider);

    // Build parallel future list.
    // The minimum display time runs concurrently with the network calls so
    // the total wait is max(splashDelay, slowestApiCall) instead of their sum.
    final futures = <Future<void>>[
      // Minimum splash display time (gives animations time to complete)
      Future<void>.delayed(const Duration(milliseconds: 2800)),
      // Always preload — needed on dashboard regardless of login state
      ref.read(agriTitlesProvider.notifier).fetch(),
      ref.read(farmingTipsProvider.notifier).fetch(),
    ];

    // Only preload auth-gated data when user is already logged in
    if (authState.isLoggedIn) {
      futures.addAll([
        ref.read(walletProvider.notifier).fetchWallet(),
        ref.read(weatherProvider.notifier).fetchWeather(),
      ]);
    }

    // Wait for everything in parallel.
    // Hard 4-second timeout so a slow connection never hangs the app on
    // the splash screen indefinitely.
    await Future.wait(futures).timeout(
      const Duration(seconds: 4),
      onTimeout: () => [], // proceed even if some calls are still in flight
    );

    if (!mounted) return;

    final prefs = ref.read(sharedPreferencesProvider);

    if (authState.isLoggedIn) {
      final hasLang = prefs.getString(AppConstants.keyLanguage) != null;
      _pushReplacement(
        hasLang
            ? const DashboardScreen()
            : const LanguageSelectionScreen(isOnboarding: true),
      );
    } else {
      _pushReplacement(const LoginScreen());
    }
  }

  void _pushReplacement(Widget screen) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => screen,
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 380;
    final logoSize = isSmallScreen ? 120.0 : 140.0;
    final appNameSize = isSmallScreen ? 32.0 : 42.0;
    final taglineSize = isSmallScreen ? 12.0 : 14.0;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF1B5E20),
              Color(0xFF2E7D32),
              Color(0xFF388E3C),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  // ── Decorative background emoji pattern ──────────────────
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Opacity(
                        opacity: 0.08,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final emojiSize = constraints.maxWidth * 0.12;
                            return Wrap(
                              children: [
                                Text('🌾',
                                    style: TextStyle(fontSize: emojiSize)),
                                Text('🌱',
                                    style:
                                        TextStyle(fontSize: emojiSize * 1.2)),
                                Text('🍃',
                                    style:
                                        TextStyle(fontSize: emojiSize * 0.9)),
                                Text('🌿',
                                    style:
                                        TextStyle(fontSize: emojiSize * 1.1)),
                                Text('🌾',
                                    style:
                                        TextStyle(fontSize: emojiSize * 0.8)),
                                Text('🍃',
                                    style:
                                        TextStyle(fontSize: emojiSize * 1.3)),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ),

                  // ── Floating animated emojis ─────────────────────────────
                  Positioned(
                    top: screenHeight * 0.12,
                    left: screenWidth * 0.05,
                    child: Text(
                      '🌾',
                      style: TextStyle(
                        fontSize: screenWidth * 0.12,
                        color: Colors.white.withValues(alpha: 0.15),
                      ),
                    )
                        .animate(
                          onPlay: (c) => c.repeat(reverse: true),
                        )
                        .moveY(
                          begin: 0,
                          end: -12,
                          duration: 2.5.seconds,
                          curve: Curves.easeInOut,
                        ),
                  ),
                  Positioned(
                    top: screenHeight * 0.18,
                    right: screenWidth * 0.05,
                    child: Text(
                      '🌱',
                      style: TextStyle(
                        fontSize: screenWidth * 0.10,
                        color: Colors.white.withValues(alpha: 0.15),
                      ),
                    )
                        .animate(
                          onPlay: (c) => c.repeat(reverse: true),
                        )
                        .moveY(
                          begin: 0,
                          end: -8,
                          duration: 2.seconds,
                          curve: Curves.easeInOut,
                        ),
                  ),
                  Positioned(
                    bottom: screenHeight * 0.15,
                    left: screenWidth * 0.05,
                    child: Text(
                      '🍃',
                      style: TextStyle(
                        fontSize: screenWidth * 0.13,
                        color: Colors.white.withValues(alpha: 0.15),
                      ),
                    )
                        .animate(
                          onPlay: (c) => c.repeat(reverse: true),
                        )
                        .moveY(
                          begin: 0,
                          end: -10,
                          duration: 2.8.seconds,
                          curve: Curves.easeInOut,
                        ),
                  ),
                  Positioned(
                    bottom: screenHeight * 0.22,
                    right: screenWidth * 0.08,
                    child: Text(
                      '🌿',
                      style: TextStyle(
                        fontSize: screenWidth * 0.11,
                        color: Colors.white.withValues(alpha: 0.15),
                      ),
                    )
                        .animate(
                          onPlay: (c) => c.repeat(reverse: true),
                        )
                        .moveY(
                          begin: 0,
                          end: -9,
                          duration: 2.2.seconds,
                          curve: Curves.easeInOut,
                        ),
                  ),

                  // ── Main content ─────────────────────────────────────────
                  Center(
                    child: SingleChildScrollView(
                      physics: const NeverScrollableScrollPhysics(),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Pulsing logo
                          AnimatedBuilder(
                            animation: _pulseController,
                            builder: (context, child) {
                              return Container(
                                width: logoSize + (_pulseController.value * 8),
                                height: logoSize + (_pulseController.value * 8),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFF9A825)
                                          .withValues(alpha: 0.4),
                                      blurRadius: 30,
                                      spreadRadius: 5,
                                    ),
                                  ],
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color:
                                          Colors.white.withValues(alpha: 0.6),
                                      width: 3,
                                    ),
                                  ),
                                  child: ClipOval(
                                    child: Image.asset(
                                      'assets/images/logo.png',
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        decoration: const BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Color(0xFFF9A825),
                                              Color(0xFFFFB74D),
                                            ],
                                          ),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: Text(
                                            '🌱',
                                            style: TextStyle(
                                                fontSize: logoSize * 0.45),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ).animate().scale(
                                duration: 800.ms,
                                curve: Curves.elasticOut,
                              ),

                          const SizedBox(height: 32),

                          // App name
                          Flexible(
                            child: Text(
                              l.appName,
                              maxLines: 2,
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.nunito(
                                fontSize: appNameSize,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 1.2,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                          )
                              .animate()
                              .fadeIn(delay: 400.ms)
                              .slideY(begin: 0.3, end: 0),

                          const SizedBox(height: 12),

                          // Tagline badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Text(
                              l.tagline,
                              maxLines: 2,
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.nunito(
                                fontSize: taglineSize,
                                color: Colors.white.withValues(alpha: 0.95),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                              .animate()
                              .fadeIn(delay: 600.ms)
                              .slideY(begin: 0.2, end: 0),

                          const SizedBox(height: 80),

                          // Progress bar — duration matches the 2.8 s minimum
                          // delay so the bar fills just as the app navigates.
                          Container(
                            width: screenWidth * 0.5,
                            height: 4,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(2),
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                            child: TweenAnimationBuilder(
                              tween: Tween<double>(begin: 0, end: 1),
                              duration: const Duration(milliseconds: 2800),
                              builder: (context, value, child) {
                                return FractionallySizedBox(
                                  alignment: Alignment.centerLeft,
                                  widthFactor: value,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFFF9A825),
                                          Colors.white,
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ).animate().fadeIn(delay: 800.ms),

                          const SizedBox(height: 24),

                          Text(
                            l.t('powered_by_aislyn'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.nunito(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: isSmallScreen ? 10 : 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ).animate().fadeIn(delay: 1000.ms),

                          const SizedBox(height: 12),

                          // "Made for farmers" row — safe split guard added
                          Builder(builder: (context) {
                            final text = l.madeForFarmers;
                            final parts = text.split('💚');
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  parts.isNotEmpty ? parts[0] : '',
                                  style: GoogleFonts.nunito(
                                    color: Colors.white.withValues(alpha: 0.6),
                                    fontSize: isSmallScreen ? 10 : 12,
                                  ),
                                ),
                                const Text(
                                  '💚',
                                  style: TextStyle(fontSize: 14),
                                ),
                                Text(
                                  parts.length > 1 ? parts[1] : '',
                                  style: GoogleFonts.nunito(
                                    color: Colors.white.withValues(alpha: 0.6),
                                    fontSize: isSmallScreen ? 10 : 12,
                                  ),
                                ),
                              ],
                            );
                          }).animate().fadeIn(delay: 1200.ms),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
