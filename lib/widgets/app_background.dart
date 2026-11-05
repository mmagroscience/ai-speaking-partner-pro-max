import 'package:flutter/material.dart';

import '../core/app_theme.dart';

class AppBackground extends StatelessWidget {
  const AppBackground({
    super.key,
    required this.child,
    this.padding,
    this.dark = false,
    this.showBlobs = true,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final bool dark;
  final bool showBlobs;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: dark
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1B0B36), Color(0xFF2A0E5C), Color(0xFF3B1578)],
              )
            : AppColors.screenGradient,
      ),
      child: Stack(
        children: [
          if (showBlobs) ...[
            Positioned(
              top: -120,
              right: -90,
              child: _Blob(
                size: 300,
                color: dark
                    ? AppColors.violet.withValues(alpha: 0.28)
                    : AppColors.lavender.withValues(alpha: 0.20),
              ),
            ),
            Positioned(
              top: 220,
              left: -140,
              child: _Blob(
                size: 320,
                color: dark
                    ? AppColors.mint.withValues(alpha: 0.10)
                    : AppColors.mint.withValues(alpha: 0.09),
              ),
            ),
            Positioned(
              bottom: -160,
              right: -80,
              child: _Blob(
                size: 360,
                color: dark
                    ? AppColors.lavender.withValues(alpha: 0.12)
                    : AppColors.pale.withValues(alpha: 0.8),
              ),
            ),
          ],
          Padding(
            padding: padding ?? EdgeInsets.zero,
            child: child,
          ),
        ],
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }
}
