import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

// ════════════════════════════════════════════════════════════════════════════
// EXISTING COMPONENTS
// ════════════════════════════════════════════════════════════════════════════

class AppShimmer extends StatelessWidget {
  final Widget child;
  final Color? baseColor;
  final Color? highlightColor;

  const AppShimmer({
    super.key,
    required this.child,
    this.baseColor,
    this.highlightColor,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: baseColor ?? const Color(0xFFE6EEE8),
      highlightColor: highlightColor ?? const Color(0xFFF7FBF7),
      child: child,
    );
  }
}

class AppSkeletonBox extends StatelessWidget {
  final double? width;
  final double? height;
  final BorderRadiusGeometry borderRadius;
  final BoxShape shape;
  final Color? color;
  final EdgeInsetsGeometry? margin;

  const AppSkeletonBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(14)),
    this.shape = BoxShape.rectangle,
    this.color,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        shape: shape,
        borderRadius: shape == BoxShape.circle ? null : borderRadius,
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// NEW: PREMIUM GLASSMORPHISM OVERLAY
// ════════════════════════════════════════════════════════════════════════════

class GlassScanningOverlay extends StatelessWidget {
  final String message;

  const GlassScanningOverlay({
    super.key,
    this.message = "Analyzing Crop Health...",
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: BackdropFilter(
        filter: ImageFilter.blur(
            sigmaX: 12, sigmaY: 12), // High blur for glass effect
        child: Container(
          color: Colors.black.withAlpha(
              (0.2 * 255).toInt()), // Dark backdrop to make scanner pop
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha((0.15 * 255).toInt()),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                    color: Colors.white.withAlpha((0.3 * 255).toInt())),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha((0.15 * 255).toInt()),
                    blurRadius: 20,
                    spreadRadius: 5,
                  )
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Shimmer.fromColors(
                    baseColor: Colors.greenAccent,
                    highlightColor: Colors.white,
                    child: const Icon(
                      Icons.document_scanner_outlined,
                      size: 64,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Shimmer.fromColors(
                    baseColor: Colors.white,
                    highlightColor: Colors.white70,
                    child: Text(
                      message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
