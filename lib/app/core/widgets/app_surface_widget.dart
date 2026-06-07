import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppSurface extends StatelessWidget {
  final Widget child;

  /// Shape
  final double radius;

  /// Elevation (shadow intensity)
  final double elevation;

  /// Blur intensity (0 = no blur)
  final double blur;

  /// Background color
  final Color color;

  /// Border (optional glass style)
  final Border? border;

  /// Padding
  final EdgeInsetsGeometry? padding;

  /// Margin
  final EdgeInsetsGeometry? margin;

  const AppSurface({
    super.key,
    required this.child,
    this.radius = 8,
    this.elevation = 8,
    this.blur = 0,
    this.color = Colors.white,
    this.border,
    this.padding,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(radius);

    Widget content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: blur > 0 ? color.withOpacity(0.6) : color,
        borderRadius: borderRadius.r,
        border: border,
      ),
      child: child,
    );

    // Apply blur if needed
    if (blur > 0) {
      content = ClipRRect(
        borderRadius: borderRadius.r,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: content,
        ),
      );
    } else {
      content = ClipRRect(
        borderRadius: borderRadius.r,
        child: content,
      );
    }

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: borderRadius.r,
        boxShadow: elevation > 0
            ? const [
                BoxShadow(
                  color: Color(0x14000000),
                  offset: Offset(2, 2),
                  blurRadius: 12,
                  spreadRadius: 0,
                ),
              ]
            : null,
      ),
      child: content,
    );
  }
}
