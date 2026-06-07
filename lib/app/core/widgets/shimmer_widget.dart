import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';

class Skeleton extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const Skeleton({
    super.key,
    this.width = double.infinity,
    this.height = 15,
    this.borderRadius,
  });

  /// Constructor for a **square Skeleton**
  const Skeleton.square({
    Key? key,
    required double size,
    BorderRadius? borderRadius,
  }) : this(
          key: key,
          width: size,
          height: size,
          borderRadius: borderRadius,
        );

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[350]!,
      highlightColor: Colors.grey[200]!,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: borderRadius ?? BorderRadius.circular(6.r),
        ),
      ),
    );
  }
}
