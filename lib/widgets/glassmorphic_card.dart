import 'dart:ui';
import 'package:flutter/material.dart';
import '../constants/colors.dart';

class GlassmorphicCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final Color? borderColor;
  final Color? backgroundColor;
  final double blur;
  final List<BoxShadow>? shadows;

  const GlassmorphicCard({
    super.key,
    required this.child,
    this.borderRadius = 20,
    this.padding,
    this.borderColor,
    this.backgroundColor,
    this.blur = 16,
    this.shadows,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding ?? const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: backgroundColor ?? kSurface1.withOpacity(0.8),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: borderColor ?? kDivider,
              width: 1,
            ),
            boxShadow: shadows,
          ),
          child: child,
        ),
      ),
    );
  }
}
