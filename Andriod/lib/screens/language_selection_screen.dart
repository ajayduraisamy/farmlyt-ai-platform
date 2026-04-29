import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../l10n/app_localizations.dart';
import '../utils/app_constants.dart';
import '../providers/locale_provider.dart';
import '../providers/translation_provider.dart';
import '../widgets/fitted_app_text.dart';
import 'dashboard_screen.dart';

class LanguageSelectionScreen extends ConsumerStatefulWidget {
  final bool isOnboarding;

  const LanguageSelectionScreen({super.key, this.isOnboarding = false});

  @override
  ConsumerState<LanguageSelectionScreen> createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState
    extends ConsumerState<LanguageSelectionScreen> {
  String _selectedCode = 'en';
  String _searchQuery = '';
  bool _isLoading = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedCode = ref.read(localeProvider.notifier).currentLanguageCode;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _proceed() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(localeProvider.notifier).setLocale(_selectedCode);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }

    if (!mounted) return;

    if (widget.isOnboarding) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
        (_) => false,
      );
    } else {
      Navigator.pop(context);
    }
  }

  List<Map<String, String>> _filterLanguages(
      List<Map<String, String>> all, String query) {
    if (query.trim().isEmpty) return all;
    final q = query.trim().toLowerCase();
    return all.where((lang) {
      return (lang['name'] ?? '').toLowerCase().contains(q) ||
          (lang['native'] ?? '').toLowerCase().contains(q) ||
          (lang['code'] ?? '').toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 380;
    final supportedLanguagesAsync =
        ref.watch(supportedTranslationLanguagesProvider);
    final allLanguages = supportedLanguagesAsync.asData?.value ??
        AppConstants.supportedLanguages;
    final filteredLanguages = _filterLanguages(allLanguages, _searchQuery);
    final l = AppLocalizations.of(context);
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;
    final horizontalPadding = isSmallScreen ? 16.0 : 24.0;

    return Stack(
      children: [
        // Decorative background emojis
        Positioned.fill(
          child: IgnorePointer(
            child: Opacity(
              opacity: 0.03,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final emojiSize = constraints.maxWidth * 0.15;
                  return Wrap(
                    children: [
                      Text('🌾', style: TextStyle(fontSize: emojiSize)),
                      Text('🌱', style: TextStyle(fontSize: emojiSize * 1.2)),
                      Text('🍃', style: TextStyle(fontSize: emojiSize * 0.9)),
                      Text('🌿', style: TextStyle(fontSize: emojiSize * 1.1)),
                      Text('🌾', style: TextStyle(fontSize: emojiSize * 0.8)),
                      Text('🍃', style: TextStyle(fontSize: emojiSize * 1.3)),
                      Text('🌱', style: TextStyle(fontSize: emojiSize * 0.95)),
                    ],
                  );
                },
              ),
            ),
          ),
        ),

        Scaffold(
          backgroundColor: const Color(0xFFF5F7F5),
          // ── STICKY SAVE BUTTON — always visible, no scroll needed ─────
          bottomNavigationBar: Container(
            color: const Color(0xFFF5F7F5),
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              10,
              horizontalPadding,
              bottomPadding > 0 ? bottomPadding : 16,
            ),
            child: SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _proceed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF9A825),
                  foregroundColor: const Color(0xFF5D4037),
                  disabledBackgroundColor:
                      const Color(0xFFF9A825).withValues(alpha: 0.6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 4,
                  shadowColor: const Color(0xFFF9A825).withValues(alpha: 0.3),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Color(0xFF5D4037),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: FittedAppText(
                              widget.isOnboarding
                                  ? l.getStarted
                                  : l.saveLanguage,
                              style: GoogleFonts.nunito(
                                fontSize: isSmallScreen ? 15 : 17,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF5D4037),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Icon(
                            widget.isOnboarding
                                ? Icons.arrow_forward_rounded
                                : Icons.check_rounded,
                            size: 20,
                            color: const Color(0xFF5D4037),
                          ),
                        ],
                      ),
              ),
            ),
          ),
          body: SafeArea(
            bottom: false, // bottom handled by bottomNavigationBar
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isCompactHeight = constraints.maxHeight < 680;
                final titleFontSize =
                    isCompactHeight ? 22.0 : (isSmallScreen ? 26.0 : 30.0);
                final logoSize =
                    isCompactHeight ? 68.0 : (isSmallScreen ? 84.0 : 100.0);
                final topSpacing =
                    widget.isOnboarding ? (isCompactHeight ? 6.0 : 14.0) : 6.0;
                final logoBottomSpacing =
                    widget.isOnboarding ? (isCompactHeight ? 12.0 : 20.0) : 0.0;
                final sectionSpacing = isCompactHeight ? 10.0 : 14.0;
                final gridSpacing = isSmallScreen ? 10.0 : 14.0;
                // Slightly smaller cards so they always fit without overflow
                final cardHeight =
                    isCompactHeight ? 114.0 : (isSmallScreen ? 124.0 : 140.0);
                final flagSize =
                    isCompactHeight ? 28.0 : (isSmallScreen ? 32.0 : 40.0);
                final nativeFontSize =
                    isCompactHeight ? 11.0 : (isSmallScreen ? 12.0 : 14.0);
                final nameFontSize =
                    isCompactHeight ? 9.0 : (isSmallScreen ? 9.0 : 11.0);

                return CustomScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        topSpacing,
                        horizontalPadding,
                        8,
                      ),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          // ── Logo (onboarding only) ───────────────────
                          if (widget.isOnboarding) ...[
                            Center(
                              child: Container(
                                width: logoSize,
                                height: logoSize,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFFF9A825)
                                        .withValues(alpha: 0.5),
                                    width: 3,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF2E7D32)
                                          .withValues(alpha: 0.2),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: ClipOval(
                                  child: Image.asset(
                                    'assets/images/logo.png',
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      decoration: const BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Color(0xFF2E7D32),
                                            Color(0xFF1B5E20)
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          '🌱',
                                          style: TextStyle(
                                              fontSize: logoSize * 0.5),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ).animate().scale(
                                duration: 600.ms, curve: Curves.elasticOut),
                            SizedBox(height: logoBottomSpacing),
                          ],

                          // ── Back button (settings mode) ──────────────
                          if (!widget.isOnboarding)
                            Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
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

                          // ── Header ───────────────────────────────────
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    if (widget.isOnboarding) ...[
                                      Text(
                                        '🌐',
                                        style: TextStyle(
                                          fontSize: isCompactHeight ? 22 : 28,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                    ],
                                    Flexible(
                                      child: Text(
                                        widget.isOnboarding
                                            ? l.chooseLanguage
                                            : l.language,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.nunito(
                                          fontSize: titleFontSize,
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xFF2E7D32),
                                          height: 1.2,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  width: 70,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFFF9A825),
                                        Color(0xFF2E7D32)
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                SizedBox(height: isCompactHeight ? 6 : 10),
                                Text(
                                  l.languageSubtitle,
                                  style: GoogleFonts.nunito(
                                    fontSize: isCompactHeight ? 12 : 13,
                                    color: const Color(0xFF5D4037),
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ).animate().fadeIn(delay: 200.ms),

                          SizedBox(height: sectionSpacing),

                          // ── SEARCH BAR ───────────────────────────────
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF2E7D32)
                                      .withValues(alpha: 0.08),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: TextField(
                              controller: _searchController,
                              onChanged: (value) =>
                                  setState(() => _searchQuery = value),
                              style: GoogleFonts.nunito(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF2E7D32),
                              ),
                              decoration: InputDecoration(
                                hintText: l.searchLanguage,
                                hintStyle: GoogleFonts.nunito(
                                  fontSize: 13,
                                  color: const Color(0xFF9E9E9E),
                                ),
                                prefixIcon: const Icon(
                                  Icons.search_rounded,
                                  color: Color(0xFF2E7D32),
                                  size: 20,
                                ),
                                suffixIcon: _searchQuery.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(
                                          Icons.close_rounded,
                                          color: Color(0xFF9E9E9E),
                                          size: 18,
                                        ),
                                        onPressed: () {
                                          _searchController.clear();
                                          setState(() => _searchQuery = '');
                                        },
                                      )
                                    : null,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: const Color(0xFF2E7D32)
                                        .withValues(alpha: 0.15),
                                    width: 1.5,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF2E7D32),
                                    width: 1.5,
                                  ),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ).animate().fadeIn(delay: 250.ms),

                          SizedBox(height: sectionSpacing),

                          // ── LANGUAGE GRID ────────────────────────────
                          if (filteredLanguages.isEmpty)
                            Center(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 32),
                                child: Column(
                                  children: [
                                    const Text('🌐',
                                        style: TextStyle(fontSize: 48)),
                                    const SizedBox(height: 12),
                                    Text(
                                      l.noLanguageFound,
                                      style: GoogleFonts.nunito(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF5D4037),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: gridSpacing,
                                crossAxisSpacing: gridSpacing,
                                mainAxisExtent: cardHeight,
                              ),
                              itemCount: filteredLanguages.length,
                              itemBuilder: (context, index) {
                                final lang = filteredLanguages[index];
                                final isSelected =
                                    _selectedCode == lang['code'];

                                return GestureDetector(
                                  onTap: () => setState(
                                      () => _selectedCode = lang['code']!),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    decoration: BoxDecoration(
                                      gradient: isSelected
                                          ? const LinearGradient(
                                              colors: [
                                                Color(0xFF2E7D32),
                                                Color(0xFF1B5E20)
                                              ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            )
                                          : const LinearGradient(
                                              colors: [
                                                Colors.white,
                                                Color(0xFFFAFAF5)
                                              ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: isSelected
                                            ? Colors.transparent
                                            : const Color(0xFF2E7D32)
                                                .withValues(alpha: 0.2),
                                        width: 1.5,
                                      ),
                                      boxShadow: isSelected
                                          ? [
                                              BoxShadow(
                                                color: const Color(0xFF2E7D32)
                                                    .withValues(alpha: 0.25),
                                                blurRadius: 14,
                                                offset: const Offset(0, 5),
                                              ),
                                            ]
                                          : [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withValues(alpha: 0.04),
                                                blurRadius: 8,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                    ),
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: isCompactHeight ? 6 : 8,
                                        vertical: isCompactHeight ? 6 : 8,
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          // Flag
                                          Text(
                                            (lang['flag']?.trim().isNotEmpty ==
                                                    true
                                                ? lang['flag']!
                                                : (lang['code'] ?? '')
                                                    .toUpperCase()),
                                            style:
                                                TextStyle(fontSize: flagSize),
                                          ),
                                          SizedBox(
                                              height: isCompactHeight ? 4 : 6),
                                          // Native name
                                          SizedBox(
                                            width: double.infinity,
                                            child: Text(
                                              lang['native']!,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              textAlign: TextAlign.center,
                                              style: GoogleFonts.nunito(
                                                fontSize: nativeFontSize,
                                                fontWeight: FontWeight.w800,
                                                color: isSelected
                                                    ? Colors.white
                                                    : const Color(0xFF2E7D32),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          // English name
                                          SizedBox(
                                            width: double.infinity,
                                            child: Text(
                                              lang['name']!,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              textAlign: TextAlign.center,
                                              style: GoogleFonts.nunito(
                                                fontSize: nameFontSize,
                                                fontWeight: FontWeight.w500,
                                                color: isSelected
                                                    ? Colors.white
                                                        .withValues(alpha: 0.85)
                                                    : const Color(0xFF9E9E9E),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                )
                                    .animate(
                                        delay:
                                            Duration(milliseconds: 50 * index))
                                    .fadeIn(duration: 250.ms)
                                    .slideY(begin: 0.1, end: 0);
                              },
                            ),

                          const SizedBox(height: 8),
                        ]),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
