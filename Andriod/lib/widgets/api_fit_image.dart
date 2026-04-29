import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

class ApiFitImage extends StatelessWidget {
  final String? imageUrl;
  final BoxFit fit;
  final Alignment alignment;
  final FilterQuality filterQuality;
  final Widget fallback;

  const ApiFitImage({
    super.key,
    required this.imageUrl,
    required this.fallback,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.filterQuality = FilterQuality.high,
  });

  @override
  Widget build(BuildContext context) {
    final resolved = imageUrl?.trim();
    if (resolved == null || resolved.isEmpty) {
      return fallback;
    }

    return CachedNetworkImage(
      imageUrl: resolved,
      width: double.infinity,
      height: double.infinity,
      fit: fit,
      alignment: alignment,
      filterQuality: filterQuality,
      // Memory management: Saves RAM by not loading full-res image if not needed
      memCacheHeight: 800,

      // 1. Loading State: Glassmorphism + Shimmer
      placeholder: (context, url) => _buildGlassyLoader(),

      // 2. Error State
      errorWidget: (context, url, error) => fallback,

      // 3. Smooth Fade-in Animation
      fadeInDuration: const Duration(milliseconds: 500),
    );
  }

  Widget _buildGlassyLoader() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12), // Consistent with your UI
      child: Stack(
        children: [
          // Glass Background
          Positioned.fill(
            // Stack full-ah cover panna safe
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                color: Colors.white.withAlpha((0.1 * 255).toInt()),
              ),
            ),
          ),
          // Shimmer Effect
          Shimmer.fromColors(
            baseColor: Colors.white.withAlpha((0.1 * 255).toInt()),
            highlightColor: Colors.white.withAlpha((0.3 * 255).toInt()),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withAlpha((0.2 * 255).toInt()),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const Center(
            child: Icon(Icons.image_outlined, color: Colors.white24, size: 30),
          ),
        ],
      ),
    );
  }
}
