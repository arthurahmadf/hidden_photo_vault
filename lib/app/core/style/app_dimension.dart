import 'package:flutter/widgets.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppDimension {
  static double horizontalPaddingContent = 16.w;
  static double verticalPaddingContent = 12.w;

  // Padding
  static double paddingVerySmall = 4.w;
  static double paddingSmall = 8.w;
  static double paddingMedium = 12.w;
  static double paddingLarge = 16.w;

  // Border Radius
  static double borderRadiusSmall = 4.r;
  static double borderRadiusMedium = 8.r;
  static double borderRadiusLarge = 12.r;
  static double borderRadiusAppBar = 10.r;

  // Spacing
  static double spaceSmall = 8.h;
  static double spaceMedium = 12.h;
  static double spaceLarge = 16.h;

  // EdgeInset
  static EdgeInsetsGeometry containerPadding = EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.w);
  static EdgeInsetsGeometry buttonPadding = EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.w);
  static EdgeInsetsGeometry pagePadding = EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.w);

  // BorderRadius
  static BorderRadius borderRadius = BorderRadius.circular(6.r);
}
