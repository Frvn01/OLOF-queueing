import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Reusable OLOF Logo widget with asset loader & graceful fallback
class OlofLogo extends StatelessWidget {
  final double size;
  final bool showBorder;
  final Color? backgroundColor;

  const OlofLogo({
    super.key,
    this.size = 56,
    this.showBorder = true,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: backgroundColor ?? (isDark ? AppColors.surfaceMid : Colors.white),
        border: showBorder
            ? Border.all(
                color: AppColors.primary.withValues(alpha: isDark ? 0.6 : 0.35),
                width: 2.0,
              )
            : null,
        boxShadow: showBorder
            ? [
                BoxShadow(
                  color: (isDark ? Colors.black : AppColors.primary)
                      .withValues(alpha: isDark ? 0.35 : 0.18),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/logo.jpg',
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Image.asset(
              'assets/logo.png',
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (context, error2, stackTrace2) {
                // Fallback if neither logo file is found
                return Center(
                  child: Icon(
                    Icons.visibility_rounded,
                    size: size * 0.52,
                    color: AppColors.primary,
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
