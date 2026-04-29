import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class CreditsChip extends StatelessWidget {
  final int credits;

  const CreditsChip({super.key, required this.credits});

  @override
  Widget build(BuildContext context) {
    final isLow = credits < 10;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isLow
            ? AppColors.warning.withValues(alpha: 0.2)
            : Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isLow
              ? AppColors.warning.withValues(alpha: 0.5)
              : Colors.white.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            isLow ? '⚠️' : '💰',
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(width: 4),
          Text(
            '$credits',
            style: TextStyle(
              color: isLow ? AppColors.warning : Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}
