import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../l10n/app_localizations.dart';
import '../models/app_models.dart';
import '../providers/auth_provider.dart';
import '../providers/categories_provider.dart';
import '../providers/wallet_provider.dart';
import '../utils/api_text_formatter.dart';
import '../utils/detection_localizer.dart';
import '../widgets/api_fit_image.dart';
import 'crop_detection_screen.dart';

class DetectionScreen extends ConsumerStatefulWidget {
  final DetectionCategory category;

  const DetectionScreen({super.key, required this.category});

  @override
  ConsumerState<DetectionScreen> createState() => _DetectionScreenState();
}

class _DetectionScreenState extends ConsumerState<DetectionScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentState = ref.read(categoriesProvider);

      final hasData = currentState.categories
          .any((c) => (c.id == widget.category.id) && c.cropOptions.isNotEmpty);

      if (!hasData) {
        ref.read(categoriesProvider.notifier).fetch(
            agriId: widget.category.agriId > 0 ? widget.category.agriId : null);
      }
    });
  }

  Future<void> _refreshCategory() {
    return ref.read(categoriesProvider.notifier).fetch(
        agriId: widget.category.agriId > 0 ? widget.category.agriId : null);
  }

  DetectionCategory _resolveCategory(CategoriesState state) {
    DetectionCategory? byBackendId;
    DetectionCategory? byKeyMatch;
    DetectionCategory? byId;

    for (final item in state.categories) {
      if (widget.category.backendId > 0 &&
          item.backendId == widget.category.backendId) {
        byBackendId = item;
        break;
      }
      if (item.id == widget.category.id &&
          item.apiPath == widget.category.apiPath) {
        byKeyMatch ??= item;
      }
      if (item.id == widget.category.id) {
        byId ??= item;
      }
    }

    return byBackendId ?? byKeyMatch ?? byId ?? widget.category;
  }

  String _categoryTitle(BuildContext context, DetectionCategory category) =>
      DetectionLocalizer.categoryTitle(
        context,
        category.id,
        fallbackTitle: category.title,
      );

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final walletState = ref.watch(walletProvider);
    final categoriesState = ref.watch(categoriesProvider);
    final category = _resolveCategory(categoriesState);
    final l = AppLocalizations.of(context);
    final credits = walletState.credits > 0
        ? walletState.credits
        : (authState.user?.credits ?? 0);
    final headerColor = Color(category.color);
    final headerColorEnd = Color.alphaBlend(
      Colors.white.withValues(alpha: 0.22),
      headerColor,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F5),
      body: RefreshIndicator(
        onRefresh: _refreshCategory,
        color: const Color(0xFF2E7D32),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              expandedHeight: 170,
              floating: false,
              pinned: true,
              backgroundColor: headerColor,
              leading: Container(
                margin: const EdgeInsets.only(left: 8, top: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              actions: [
                Container(
                  margin: const EdgeInsets.only(right: 12, top: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF9A825), Color(0xFFFFB74D)],
                    ),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    children: [
                      const Text('💰', style: TextStyle(fontSize: 13)),
                      const SizedBox(width: 4),
                      Text(
                        '$credits',
                        style: GoogleFonts.nunito(
                          color: const Color(0xFF5D4037),
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: ClipPath(
                  clipper: _CurvedClipper(),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [headerColor, headerColorEnd],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(72, 8, 20, 34),
                        child: Align(
                          alignment: Alignment.bottomLeft,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  _CategoryVisual(category: category),
                                  const SizedBox(width: 10),
                                  Flexible(
                                    child: Text(
                                      _categoryTitle(context, category),
                                      style: GoogleFonts.nunito(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                category.cropOptions.isEmpty
                                    ? l.t('no_crops_available')
                                    : l.selectCrop,
                                style: GoogleFonts.nunito(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 13,
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
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('🌾', style: TextStyle(fontSize: 20)),
                        const SizedBox(width: 8),
                        Text(
                          l.selectCrop,
                          style: GoogleFonts.nunito(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF2E7D32),
                          ),
                        ),
                      ],
                    ).animate().fadeIn(duration: 300.ms),
                    const SizedBox(height: 4),
                    Container(
                      width: 50,
                      height: 3,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFF9A825), Color(0xFF2E7D32)],
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ).animate().fadeIn(delay: 50.ms),
                    const SizedBox(height: 12),
                    Text(
                      category.cropOptions.isEmpty
                          ? l.t('no_crops_available')
                          : l.t('choose_crop_hint'),
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        color: const Color(0xFF5D4037),
                      ),
                    ).animate().fadeIn(delay: 80.ms),
                    const SizedBox(height: 20),
                    if (category.cropOptions.isEmpty)
                      _EmptyCropState(color: headerColor)
                          .animate()
                          .fadeIn(delay: 120.ms)
                    else
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 14,
                          crossAxisSpacing: 14,
                          childAspectRatio: 0.76,
                        ),
                        itemCount: category.cropOptions.length,
                        itemBuilder: (context, index) {
                          final crop = category.cropOptions[index];
                          return _CropOptionCard(
                            crop: crop,
                            color: headerColor,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CropDetectionScreen(
                                  category: category,
                                  crop: crop,
                                ),
                              ),
                            ),
                          )
                              .animate(
                                  delay: Duration(milliseconds: 80 * index))
                              .fadeIn(duration: 320.ms)
                              .slideY(begin: 0.12, end: 0);
                        },
                      ),
                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CropOptionCard extends StatelessWidget {
  final CropOption crop;
  final Color color;
  final VoidCallback onTap;

  const _CropOptionCard({
    required this.crop,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final localizedTitle = crop.title.trim().isNotEmpty
        ? crop.title
        : DetectionLocalizer.cropLabel(
            context,
            crop.cropKey,
            fallbackLabel: crop.title,
          );

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: color.withValues(alpha: 0.12)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.12),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            children: [
              Positioned(
                right: -22,
                bottom: -22,
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(alpha: 0.06),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: 92,
                          height: 92,
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: ApiFitImage(
                              imageUrl: crop.imageUrl,
                              fit: BoxFit.cover,
                              fallback: const Icon(
                                Icons.image_not_supported_rounded,
                                size: 38,
                              ),
                            ),
                          ),
                        ),
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 15,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      ApiTextFormatter.format(localizedTitle),
                      softWrap: true,
                      style: GoogleFonts.nunito(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppLocalizations.of(context).tapUpload,
                      softWrap: true,
                      style: GoogleFonts.nunito(
                        fontSize: 11,
                        color: const Color(0xFF5D4037),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryVisual extends StatelessWidget {
  final DetectionCategory category;

  const _CategoryVisual({required this.category});

  @override
  Widget build(BuildContext context) {
    final imageUrl = category.imageUrl?.trim();
    if (imageUrl == null || imageUrl.isEmpty) {
      return const Icon(
        Icons.image_not_supported_rounded,
        color: Colors.white,
        size: 28,
      );
    }

    return Container(
      width: 52,
      height: 52,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: ApiFitImage(
          imageUrl: imageUrl,
          fit: BoxFit.contain,
          fallback: const Icon(
            Icons.image_not_supported_rounded,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
    );
  }
}

class _EmptyCropState extends StatelessWidget {
  final Color color;

  const _EmptyCropState({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.info_outline_rounded, color: color, size: 36),
          ),
          const SizedBox(height: 14),
          Text(
            AppLocalizations.of(context).t('no_crops_available'),
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF5D4037),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context).t('backend_crop_pending'),
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontSize: 12,
              color: const Color(0xFF5D4037),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _CurvedClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 28);
    path.quadraticBezierTo(
      size.width / 2,
      size.height,
      size.width,
      size.height - 28,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
