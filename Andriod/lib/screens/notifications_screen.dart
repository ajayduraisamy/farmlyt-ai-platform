// lib/screens/notifications_screen.dart
// REPLACE entire file with this

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/notifications_provider.dart';
import '../models/app_models.dart';
import '../l10n/app_localizations.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationsProvider);
    final notifier = ref.read(notificationsProvider.notifier);
    final notifications = state.notifications;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 380;
    final headerFontSize = isSmallScreen ? 24.0 : 28.0;
    final l = AppLocalizations.of(context);

    return Stack(
      children: [
        // Decorative background
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
                // ── Header ────────────────────────────────────────────────
                SliverAppBar(
                  pinned: true,
                  expandedHeight: isSmallScreen ? 100 : 120,
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
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Flexible(
                                child: Row(
                                  children: [
                                    Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        const Text('🔔',
                                            style: TextStyle(fontSize: 28)),
                                        // Unread badge
                                        if (state.unreadCount > 0)
                                          Positioned(
                                            top: -4,
                                            right: -6,
                                            child: Container(
                                              padding: const EdgeInsets.all(3),
                                              decoration: const BoxDecoration(
                                                color: Color(0xFFF9A825),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Text(
                                                '${state.unreadCount > 9 ? '9+' : state.unreadCount}',
                                                style: GoogleFonts.nunito(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w900,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(width: 12),
                                    Flexible(
                                      child: Text(
                                        l.notifications,
                                        maxLines: 2,
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
                              // Mark all read button — only shown if there
                              // are unread notifications
                              if (notifications.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white
                                        .withAlpha((0.2 * 255).toInt()),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: TextButton(
                                    onPressed: () => notifier.markAllRead(),
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: Size.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: Text(
                                      l.markAllRead,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.nunito(
                                        fontSize: isSmallScreen ? 11 : 13,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
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

                // ── Body ──────────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                    child: notifications.isEmpty
                        ? _buildEmpty(context, isSmallScreen)
                        : Column(
                            children:
                                notifications.asMap().entries.map((entry) {
                              final i = entry.key;
                              final n = entry.value;
                              return Dismissible(
                                key: Key(n.id),
                                direction: DismissDirection.endToStart,
                                background: _dismissBackground(),
                                onDismissed: (_) =>
                                    notifier.removeNotification(n.id),
                                child: _notificationTile(
                                        context, n, isSmallScreen,
                                        onTap: () => notifier.markRead(n.id))
                                    .animate(
                                      delay: Duration(milliseconds: 60 * i),
                                    )
                                    .fadeIn(duration: 350.ms)
                                    .slideX(begin: 0.08, end: 0),
                              );
                            }).toList(),
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

  // ── Empty state ────────────────────────────────────────────────────────────
  Widget _buildEmpty(BuildContext context, bool isSmallScreen) {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🔕', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context).t('no_notifications_yet'),
            style: GoogleFonts.nunito(
              fontSize: isSmallScreen ? 16 : 18,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF2E7D32),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context).t('notifications_will_appear_here'),
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontSize: 13,
              color: const Color(0xFF9E9E9E),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ── Swipe-to-dismiss background ───────────────────────────────────────────
  Widget _dismissBackground() {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.red.shade400,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Icon(Icons.delete_rounded, color: Colors.white, size: 26),
    );
  }

  // ── Notification tile ──────────────────────────────────────────────────────
  Widget _notificationTile(
    BuildContext context,
    NotificationModel n,
    bool isSmallScreen, {
    required VoidCallback onTap,
  }) {
    final Color accentColor;
    final IconData icon;
    switch (n.type) {
      case 'rain':
        accentColor = const Color(0xFF0288D1);
        icon = Icons.umbrella_rounded;
        break;
      case 'disease':
        accentColor = const Color(0xFFF9A825);
        icon = Icons.warning_rounded;
        break;
      case 'fertilizer':
        accentColor = const Color(0xFF2E7D32);
        icon = Icons.grass_rounded;
        break;
      default:
        accentColor = const Color(0xFF5D4037);
        icon = Icons.notifications_rounded;
    }

    final timeAgo = _formatTime(context, n.timestamp);
    final iconSize = isSmallScreen ? 48.0 : 56.0;
    final fontSize = isSmallScreen ? 14.0 : 16.0;
    // Unread notifications have a slightly highlighted background
    final bgColor = n.isRead ? Colors.white : const Color(0xFFF1F8E9);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: n.isRead
              ? accentColor.withAlpha((0.15 * 255).toInt())
              : accentColor.withAlpha((0.35 * 255).toInt()),
          width: n.isRead ? 1 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.04 * 255).toInt()),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
          BoxShadow(
            color: accentColor.withAlpha((0.07 * 255).toInt()),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon container
                Container(
                  width: iconSize,
                  height: iconSize,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        accentColor.withAlpha((0.15 * 255).toInt()),
                        accentColor.withAlpha((0.05 * 255).toInt()),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Center(
                    child: Icon(icon, color: accentColor, size: iconSize * 0.5),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              n.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.nunito(
                                fontSize: fontSize,
                                fontWeight: n.isRead
                                    ? FontWeight.w700
                                    : FontWeight.w800,
                                color: const Color(0xFF2E7D32),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: accentColor
                                      .withAlpha((0.1 * 255).toInt()),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  timeAgo,
                                  style: GoogleFonts.nunito(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: accentColor,
                                  ),
                                ),
                              ),
                              // Unread dot
                              if (!n.isRead) ...[
                                const SizedBox(height: 4),
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: accentColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        n.body,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.nunito(
                          fontSize: 13,
                          color: const Color(0xFF5D4037),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Accent line
                      Container(
                        height: 2,
                        width: 40,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [accentColor, Colors.transparent],
                          ),
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(BuildContext context, DateTime time) {
    final diff = DateTime.now().difference(time);
    final l = AppLocalizations.of(context);
    if (diff.inMinutes < 1) return l.t('just_now');
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}${l.t('mins_short')}';
    }
    if (diff.inHours < 24) {
      return '${diff.inHours}${l.t('hours_short')}';
    }
    return '${diff.inDays}${l.t('days_short')}';
  }
}

class _CurvedBottomClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 20);
    path.quadraticBezierTo(
        size.width / 2, size.height, size.width, size.height - 20);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
