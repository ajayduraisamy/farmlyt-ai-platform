import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../l10n/app_localizations.dart';
import '../utils/detection_localizer.dart';
import 'api_fit_image.dart';

class DetectionCard extends StatelessWidget {
  final Map<String, dynamic> category;
  final VoidCallback onTap;

  const DetectionCard({
    super.key,
    required this.category,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final categoryId = category['id'] as String;
    final color = Color(category['color'] as int);
    final rawCrops = (category['crops'] as List?) ?? const [];
    final crops = rawCrops.map((item) {
      if (item is Map && item['key'] != null) {
        return DetectionLocalizer.cropLabel(context, item['key'].toString());
      }
      return item is Map && item['label'] != null
          ? item['label'].toString()
          : item.toString();
    }).toList();
    final imageUrl =
        (category['imageUrl'] as String?) ?? (category['image_url'] as String?);
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 380;
    final iconSize = isSmallScreen ? 44.0 : 52.0;
    final iconTextSize = isSmallScreen ? 24.0 : 28.0;
    final titleSize = isSmallScreen ? 13.0 : 15.0;
    final subtitleSize = isSmallScreen ? 10.0 : 11.0;
    final padding = isSmallScreen ? 12.0 : 16.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Background decoration
              Positioned(
                right: -20,
                bottom: -20,
                child: Container(
                  width: isSmallScreen ? 80 : 100,
                  height: isSmallScreen ? 80 : 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(alpha: 0.08),
                  ),
                ),
              ),
              Positioned(
                left: -20,
                top: -20,
                child: Container(
                  width: isSmallScreen ? 60 : 80,
                  height: isSmallScreen ? 60 : 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(alpha: 0.04),
                  ),
                ),
              ),

              // Content
              Padding(
                padding: EdgeInsets.all(padding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon + arrow
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: iconSize,
                          height: iconSize,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                color.withValues(alpha: 0.15),
                                color.withValues(alpha: 0.05),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: imageUrl != null && imageUrl.trim().isNotEmpty
                              ? Padding(
                                  padding: const EdgeInsets.all(6),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: ApiFitImage(
                                      imageUrl: imageUrl,
                                      fit: BoxFit.cover,
                                      fallback: Center(
                                        child: Text(
                                          category['icon'] as String,
                                          style:
                                              TextStyle(fontSize: iconTextSize),
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                              : Center(
                                  child: Text(
                                    category['icon'] as String,
                                    style: TextStyle(fontSize: iconTextSize),
                                  ),
                                ),
                        ),
                        Container(
                          width: isSmallScreen ? 26 : 30,
                          height: isSmallScreen ? 26 : 30,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [color, color.withValues(alpha: 0.8)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ],
                    ),

                    const Spacer(),

                    // Title
                    Flexible(
                      child: Text(
                        DetectionLocalizer.categoryTitle(
                          context,
                          categoryId,
                          fallbackTitle: category['title'] as String?,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.nunito(
                          fontSize: titleSize,
                          fontWeight: FontWeight.w800,
                          color: color,
                        ),
                      ),
                    ),

                    const SizedBox(height: 4),

                    // Crops list
                    Flexible(
                      child: Text(
                        crops.isEmpty
                            ? AppLocalizations.of(context)
                                .t('no_crops_available')
                            : crops.take(3).join(', ') +
                                (crops.length > 3 ? '...' : ''),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.nunito(
                          fontSize: subtitleSize,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF5D4037),
                        ),
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
