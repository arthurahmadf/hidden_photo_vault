import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'app_colors.dart';
import 'app_dimension.dart';
import 'app_fonts.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.background,
    cardTheme: _cardThemeData(),
    textSelectionTheme: _textSelectionThemeData(),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.primary,
      toolbarHeight: 55.w,
      elevation: 0,
      titleTextStyle: AppFonts.bold18.copyWith(color: AppColors.appBarTitle),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.success,
      foregroundColor: Colors.white,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        disabledBackgroundColor: AppColors.buttonDisabled,
        disabledForegroundColor: Colors.white,
        textStyle: AppFonts.medium14,
        padding: EdgeInsets.symmetric(
          vertical: AppDimension.paddingVerySmall.w,
          horizontal: AppDimension.paddingMedium.w,
        ),
        minimumSize: Size(1.sw, 40.w),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6.r),
        ),
      ),
    ),
  );

  // static ThemeData darkTheme = ThemeData(
  //   brightness: Brightness.dark, // 🌙 Dark Mode
  //   elevatedButtonTheme: ElevatedButtonThemeData(
  //     style: ElevatedButton.styleFrom(
  //       backgroundColor: AppColors.primaryDark, // 🔵 Dark mode primary color
  //       foregroundColor: Colors.black, // ⚫ Text color
  //       textStyle: AppFonts.medium16,
  //       padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 20.w),
  //       minimumSize: Size(double.infinity, 48.h),
  //       shape: RoundedRectangleBorder(
  //         borderRadius: BorderRadius.circular(AppDimension.borderRadiusMedium),
  //       ),
  //     ),
  //   ),
  // );
}

TextSelectionThemeData _textSelectionThemeData() {
  return const TextSelectionThemeData(
    cursorColor: AppColors.primary,
  );
}

CardTheme _cardThemeData() {
  return CardTheme(
    color: AppColors.primary,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
    ),
    elevation: 0,
    margin: EdgeInsets.zero,
  );
}
