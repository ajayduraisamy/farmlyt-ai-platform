import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../l10n/app_localizations.dart';
import '../models/app_models.dart';
import '../providers/agri_titles_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/farming_tips_provider.dart';
import '../providers/notifications_provider.dart';
import '../providers/wallet_provider.dart';
import '../providers/weather_provider.dart';
import '../utils/api_text_formatter.dart';
import '../widgets/api_fit_image.dart';
import '../widgets/app_skeleton.dart';
import '../widgets/fitted_app_text.dart';
import '../widgets/weather_card.dart';
import 'agri_categories_screen.dart';
import 'agri_placeholder_screen.dart';
import 'notifications_screen.dart';
import 'settings_screen.dart';
import 'wallet_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Use forceRefresh: false so that data freshly loaded during splash
      // is NOT re-fetched.  Only stale data triggers a network call.
      ref.read(weatherProvider.notifier).fetchWeather(forceRefresh: false);
      ref.read(walletProvider.notifier).fetchWallet();
    });
  }

  Future<void> _refreshHomeTab() async {
    await Future.wait<void>([
      ref.read(weatherProvider.notifier).fetchWeather(forceRefresh: true),
      ref.read(walletProvider.notifier).fetchWallet(),
      ref.read(agriTitlesProvider.notifier).fetch(),
      ref.read(farmingTipsProvider.notifier).refetch(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    // ── Use select() to only rebuild when the specific field changes ─────
    final user = ref.watch(authProvider.select((s) => s.user));
    final credits = ref.watch(walletProvider
        .select((s) => s.credits > 0 ? s.credits : (user?.credits ?? 0)));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F5),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildHomeTab(user, credits),
          const WalletScreen(),
          const NotificationsScreen(),
          const SettingsScreen(),
        ],
      ),
      bottomNavigationBar: _BottomNav(
        selectedIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
      ),
    );
  }

  // ── Home tab ──────────────────────────────────────────────────────────────
  Widget _buildHomeTab(UserModel? user, int credits) {
    final l = AppLocalizations.of(context);
    final topPadding = MediaQuery.of(context).padding.top;

    return RefreshIndicator(
      onRefresh: _refreshHomeTab,
      color: const Color(0xFF2E7D32),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: ClipPath(
              clipper: const _CurvedClipper(),
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                padding: EdgeInsets.only(
                  top: topPadding + 10,
                  left: 16,
                  right: 16,
                  bottom: 20,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _HeaderAvatar(user: user),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          RichText(
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            text: TextSpan(
                              style: GoogleFonts.nunito(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                              children: [
                                TextSpan(text: '${l.hi}, '),
                                TextSpan(
                                  text: user?.name.trim().isNotEmpty == true
                                      ? user!.name.trim()
                                      : l.t('farmer'),
                                ),
                                const TextSpan(text: ' 👋'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            l.letsCheck,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: GoogleFonts.nunito(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => setState(() => _selectedIndex = 1),
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 130),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('💰', style: TextStyle(fontSize: 12)),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                '${l.credits}: $credits',
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                style: GoogleFonts.nunito(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const WeatherCardWidget()
                    .animate()
                    .fadeIn(duration: 400.ms)
                    .slideY(begin: 0.1),
                const SizedBox(height: 6),
                _QuickStats(credits: credits),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 2),
                  child: Row(children: [
                    const Text('🔍', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 6),
                    Text(
                      AppLocalizations.of(context).diseaseDetection,
                      style: GoogleFonts.nunito(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF2E7D32),
                      ),
                    ),
                  ]),
                ),
                _CategoriesGrid(
                  onNavigate: (agriTitle) => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => agriTitle.isAgricultureDiseaseScan
                          ? AgriCategoriesScreen(agriTitle: agriTitle)
                          : AgriPlaceholderScreen.buildDirectDetectionScreen(
                              agriTitle),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const _TipsSection(),
                const SizedBox(height: 60),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Bottom nav — extracted to prevent full screen rebuild on tab change ──────
class _BottomNav extends ConsumerWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _BottomNav({required this.selectedIndex, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final unreadCount =
        ref.watch(notificationsProvider.select((s) => s.unreadCount));

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 64,
          child: Row(children: [
            _NavItem(0, Icons.home_rounded, l.home, selectedIndex, onTap, 0),
            _NavItem(1, Icons.account_balance_wallet_rounded, l.wallet,
                selectedIndex, onTap, 0),
            _NavItem(2, Icons.notifications_rounded, l.alerts, selectedIndex,
                onTap, unreadCount),
            _NavItem(
                3, Icons.settings_rounded, l.settings, selectedIndex, onTap, 0),
          ]),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final int index;
  final IconData icon;
  final String label;
  final int selectedIndex;
  final ValueChanged<int> onTap;
  final int badgeCount;

  const _NavItem(this.index, this.icon, this.label, this.selectedIndex,
      this.onTap, this.badgeCount);

  @override
  Widget build(BuildContext context) {
    final isSelected = selectedIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF2E7D32).withValues(alpha: 0.12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    icon,
                    color: isSelected
                        ? const Color(0xFF2E7D32)
                        : const Color(0xFF9E9E9E),
                    size: 22,
                  ),
                ),
                if (badgeCount > 0)
                  Positioned(
                    top: -2,
                    right: -4,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF9A825),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        badgeCount > 9 ? '9+' : '$badgeCount',
                        style: GoogleFonts.nunito(
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: FittedAppText(
                label,
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  fontSize: 9.5,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected
                      ? const Color(0xFF2E7D32)
                      : const Color(0xFF9E9E9E),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Header avatar — extracts heavy file I/O out of the main build ────────────
class _HeaderAvatar extends StatelessWidget {
  final UserModel? user;
  const _HeaderAvatar({required this.user});

  @override
  Widget build(BuildContext context) {
    final profileImagePath = user?.profileImagePath?.trim();
    final hasLocalImage =
        profileImagePath != null && profileImagePath.isNotEmpty;

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.6),
          width: 2,
        ),
      ),
      child: ClipOval(
        child: hasLocalImage
            ? Image.file(
                File(profileImagePath),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _DefaultAvatar(user: user),
              )
            : _DefaultAvatar(user: user),
      ),
    );
  }
}

class _DefaultAvatar extends StatelessWidget {
  final UserModel? user;
  const _DefaultAvatar({required this.user});

  @override
  Widget build(BuildContext context) {
    final initial = user?.name.trim().isNotEmpty == true
        ? user!.name.trim()[0].toUpperCase()
        : '👨‍🌾';
    return ColoredBox(
      color: const Color(0xFFF9A825),
      child: Center(child: Text(initial, style: const TextStyle(fontSize: 20))),
    );
  }
}

// ─── Quick stats — separated widget so it doesn't rebuild with parent ─────────
class _QuickStats extends StatelessWidget {
  final int credits;
  const _QuickStats({required this.credits});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(children: [
        Expanded(
            child: _StatCard(
                '💰', '$credits', l.credits, const Color(0xFFF9A825))),
        const SizedBox(width: 10),
        Expanded(
            child: _StatCard('🔍', '0', l.scansToday, const Color(0xFF0288D1))),
        const SizedBox(width: 10),
        Expanded(
            child: _StatCard('✅', '0', l.healthy, const Color(0xFF2E7D32))),
      ]),
    ).animate().fadeIn(delay: 100.ms);
  }
}

class _StatCard extends StatelessWidget {
  final String emoji;
  final String value;
  final String label;
  final Color color;

  const _StatCard(this.emoji, this.value, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 2),
          Text(value,
              style: GoogleFonts.nunito(
                  fontSize: 16, fontWeight: FontWeight.w900, color: color)),
          Text(label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.nunito(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF5D4037))),
        ],
      ),
    );
  }
}

// ─── Categories grid — own Consumer so only it rebuilds on state change ───────
class _CategoriesGrid extends ConsumerWidget {
  final void Function(AgriTitle) onNavigate;
  const _CategoriesGrid({required this.onNavigate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(agriTitlesProvider);

    if (state.isLoading && state.agriTitles.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: AppShimmer(
          child: GridView(
            shrinkWrap: true,
            padding: EdgeInsets.zero, // 📉 Gap logic fixed here too
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.08, // 📉 Tighter cards
            ),
            children: const [
              _AgriTitleCardSkeleton(),
              _AgriTitleCardSkeleton(),
              _AgriTitleCardSkeleton(),
              _AgriTitleCardSkeleton(),
            ],
          ),
        ),
      );
    }

    if (state.agriTitles.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Column(
            children: [
              Text(
                state.error?.trim().isNotEmpty == true
                    ? state.error!
                    : AppLocalizations.of(context).t('no_categories_available'),
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(color: const Color(0xFF9E9E9E)),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: () => ref.read(agriTitlesProvider.notifier).fetch(),
                child: Text(AppLocalizations.of(context).t('retry')),
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      // 📉 ITHU THAAN FIX: Padding-ah zero panni horizontal mattum kuduthuruken
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 8, // 📉 Space reduced
        crossAxisSpacing: 8,
        childAspectRatio: 1.08, // 📉 Cards logic: higher value = shorter height
      ),
      itemCount: state.agriTitles.length,
      itemBuilder: (context, index) {
        final agriTitle = state.agriTitles[index];
        return _AgriTitleCard(
          agriTitle: agriTitle,
          onTap: () => onNavigate(agriTitle),
        )
            .animate(delay: Duration(milliseconds: 100 * index))
            .fadeIn(duration: 400.ms)
            .slideY(begin: 0.1, end: 0); // Subtle animation to keep it tight
      },
    );
  }
}

// ─── Tips section — own Consumer ──────────────────────────────────────────────
class _TipsSection extends ConsumerWidget {
  const _TipsSection();

  static const List<Map<String, String>> _staticTips = [
    {'icon': '💧', 'titleKey': 'wateringTip', 'bodyKey': 'wateringBody'},
    {'icon': '🌞', 'titleKey': 'sunlightTip', 'bodyKey': 'sunlightBody'},
    {'icon': '🌿', 'titleKey': 'organicTip', 'bodyKey': 'organicBody'},
  ];

  static const List<String> _icons = [
    '💧',
    '🌞',
    '🌿',
    '🌱',
    '🌾',
    '💊',
    '🔬',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tipsState = ref.watch(farmingTipsProvider);
    final l = AppLocalizations.of(context);
    final hasTips = tipsState.tips.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
          child: Row(children: [
            const Text('💡', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text(l.farmingTips,
                style: GoogleFonts.nunito(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF2E7D32),
                )),
          ]),
        ),
        if (tipsState.isLoading && !hasTips)
          const SizedBox(
            height: 160,
            child: AppShimmer(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Row(children: [
                  _DashboardTipSkeletonCard(),
                  SizedBox(width: 12),
                  _DashboardTipSkeletonCard(),
                  SizedBox(width: 12),
                  _DashboardTipSkeletonCard(),
                ]),
              ),
            ),
          )
        else
          SizedBox(
            height: 160,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: hasTips ? tipsState.tips.length : 3,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final String icon, title, body;
                if (hasTips) {
                  final tip = tipsState.tips[index];
                  icon = _icons[index % _icons.length];
                  title = tip.title;
                  body = tip.description;
                } else {
                  final s = _staticTips[index];
                  icon = s['icon']!;
                  title = l.t(s['titleKey']!);
                  body = l.t(s['bodyKey']!);
                }

                return _TipCard(icon: icon, title: title, body: body);
              },
            ),
          ),
      ],
    );
  }
}

class _TipCard extends StatelessWidget {
  final String icon;
  final String title;
  final String body;

  const _TipCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: const Color(0xFF2E7D32).withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(icon, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.nunito(
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF2E7D32),
                  fontSize: 13,
                ),
              ),
            ),
          ]),
          const SizedBox(height: 8),
          Expanded(
            child: Text(
              body,
              style: GoogleFonts.nunito(
                fontSize: 11,
                color: const Color(0xFF5D4037),
                height: 1.4,
              ),
              maxLines: 6,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Skeleton / card widgets ──────────────────────────────────────────────────

class _AgriTitleCardSkeleton extends StatelessWidget {
  const _AgriTitleCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E7D32).withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(children: [
          Positioned(
            right: -15,
            bottom: -15,
            child: Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFF3F7F3),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AppSkeletonBox(width: 52, height: 52),
                    AppSkeletonBox(width: 28, height: 28),
                  ],
                ),
                Spacer(),
                AppSkeletonBox(width: 120, height: 14),
                SizedBox(height: 6),
                AppSkeletonBox(width: 90, height: 10),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

class _DashboardTipSkeletonCard extends StatelessWidget {
  const _DashboardTipSkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: const Color(0xFF2E7D32).withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            AppSkeletonBox(width: 20, height: 20, shape: BoxShape.circle),
            SizedBox(width: 8),
            Expanded(child: AppSkeletonBox(height: 14)),
          ]),
          SizedBox(height: 10),
          AppSkeletonBox(width: double.infinity, height: 10),
          SizedBox(height: 8),
          AppSkeletonBox(width: 150, height: 10),
          SizedBox(height: 8),
          AppSkeletonBox(width: 170, height: 10),
        ],
      ),
    );
  }
}

class _AgriTitleCard extends StatelessWidget {
  final AgriTitle agriTitle;
  final VoidCallback onTap;

  const _AgriTitleCard({required this.agriTitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = Color(agriTitle.color);
    final subtitle = agriTitle.subtitle;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.12),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(children: [
            Positioned(
              right: -15,
              bottom: -15,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.07),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Stack(children: [
                      Container(
                        width: double.infinity,
                        height: double.infinity,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Transform.scale(
                            scale: 1.24,
                            child: ApiFitImage(
                              imageUrl: agriTitle.imageUrl,
                              fit: BoxFit.contain,
                              fallback: Center(
                                child: Icon(
                                  Icons.image_not_supported_rounded,
                                  color: color.withValues(alpha: 0.55),
                                  size: 38,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.arrow_forward_rounded,
                              color: Colors.white, size: 12),
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    ApiTextFormatter.format(agriTitle.title),
                    softWrap: true,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      ApiTextFormatter.format(subtitle),
                      softWrap: true,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.nunito(
                        fontSize: 9.5,
                        color: const Color(0xFF9E9E9E),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _CurvedClipper extends CustomClipper<Path> {
  const _CurvedClipper();

  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 24);
    path.quadraticBezierTo(
        size.width / 2, size.height, size.width, size.height - 24);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
