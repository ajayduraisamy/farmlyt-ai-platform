import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../l10n/app_localizations.dart';
import '../models/app_models.dart';
import '../providers/categories_provider.dart';
import '../utils/api_text_formatter.dart';
import '../utils/detection_localizer.dart';
import '../widgets/api_fit_image.dart';
import '../widgets/app_skeleton.dart';
import 'detection_screen.dart';

class AgriCategoriesScreen extends ConsumerStatefulWidget {
  final AgriTitle agriTitle;

  const AgriCategoriesScreen({
    super.key,
    required this.agriTitle,
  });

  @override
  ConsumerState<AgriCategoriesScreen> createState() =>
      _AgriCategoriesScreenState();
}

class _AgriCategoriesScreenState extends ConsumerState<AgriCategoriesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(categoriesProvider.notifier).fetch(agriId: widget.agriTitle.id);
    });
  }

  Future<void> _refreshCategories() {
    return ref
        .read(categoriesProvider.notifier)
        .fetch(agriId: widget.agriTitle.id);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(categoriesProvider);
    final color = Color(widget.agriTitle.color);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F5),
      body: RefreshIndicator(
        onRefresh: _refreshCategories,
        color: const Color(0xFF2E7D32),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              expandedHeight: 170,
              floating: false,
              pinned: true,
              backgroundColor: color,
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
              flexibleSpace: FlexibleSpaceBar(
                background: ClipPath(
                  clipper: _CurvedClipper(),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          color,
                          Color.alphaBlend(
                              Colors.white.withValues(alpha: 0.22), color),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(72, 8, 20, 34),
                        child: Align(
                          alignment: Alignment.bottomLeft,
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: ApiFitImage(
                                    imageUrl: widget.agriTitle.imageUrl,
                                    fit: BoxFit.contain,
                                    fallback: const Icon(
                                      Icons.image_not_supported_rounded,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  widget.agriTitle.title,
                                  style: GoogleFonts.nunito(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
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
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: _buildBody(state),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(CategoriesState state) {
    final l = AppLocalizations.of(context);

    if (state.isLoading) {
      return AppShimmer(
        child: GridView(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.76,
          ),
          children: [
            _CategoryCardSkeleton(),
            _CategoryCardSkeleton(),
            _CategoryCardSkeleton(),
            _CategoryCardSkeleton(),
          ],
        ),
      );
    }

    if (state.categories.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Column(
            children: [
              Text(
                state.error?.trim().isNotEmpty == true
                    ? state.error!
                    : l.t('no_categories_available'),
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(color: const Color(0xFF9E9E9E)),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: () =>
                    ref.read(categoriesProvider.notifier).refetch(),
                child: Text(l.t('retry')),
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.76,
      ),
      itemCount: state.categories.length,
      itemBuilder: (context, index) {
        final cat = state.categories[index];
        return _CategoryCard(
          category: cat,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => DetectionScreen(category: cat)),
          ),
        )
            .animate(delay: Duration(milliseconds: 100 * index))
            .fadeIn(duration: 400.ms)
            .slideY(begin: 0.2, end: 0);
      },
    );
  }
}

class _CategoryCardSkeleton extends StatelessWidget {
  const _CategoryCardSkeleton();

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
        child: Stack(
          children: [
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
              padding: EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      AppSkeletonBox(width: 84, height: 84),
                      AppSkeletonBox(width: 34, height: 34),
                    ],
                  ),
                  Spacer(),
                  AppSkeletonBox(width: 120, height: 14),
                  SizedBox(height: 6),
                  AppSkeletonBox(width: 90, height: 10),
                  SizedBox(height: 8),
                  AppSkeletonBox(width: 150, height: 10),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final DetectionCategory category;
  final VoidCallback onTap;

  const _CategoryCard({required this.category, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = Color(category.color);
    final localizedTitle = DetectionLocalizer.categoryTitle(
      context,
      category.id,
      fallbackTitle: category.title,
    );
    final subtitle = category.cropOptions.isEmpty
        ? AppLocalizations.of(context).t('no_crops_available')
        : category.cropOptions
                .take(3)
                .map((crop) => DetectionLocalizer.cropLabel(
                      context,
                      crop.cropKey,
                      fallbackLabel: crop.title,
                    ))
                .join(', ') +
            (category.cropOptions.length > 3 ? '...' : '');
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
          child: Stack(
            children: [
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
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: ApiFitImage(
                              imageUrl: category.imageUrl,
                              fit: BoxFit.cover,
                              fallback: Center(
                                child: Icon(
                                  Icons.image_not_supported_rounded,
                                  color: color.withValues(alpha: 0.55),
                                  size: 36,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      ApiTextFormatter.format(localizedTitle),
                      softWrap: true,
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      ApiTextFormatter.format(subtitle),
                      softWrap: true,
                      style: GoogleFonts.nunito(
                        fontSize: 10,
                        color: const Color(0xFF9E9E9E),
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
