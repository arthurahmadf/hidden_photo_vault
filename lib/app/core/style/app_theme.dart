import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'app_colors.dart';
import 'app_dimension.dart';
import 'app_fonts.dart';

class AppTheme {
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primary,
      secondary: AppColors.onSurface,
      surface: AppColors.surface,
      error: AppColors.error,
      onPrimary: AppColors.background,
      onSecondary: AppColors.background,
      onSurface: AppColors.onBackground,
      onError: Colors.white,
    ),
    scaffoldBackgroundColor: AppColors.background,
    canvasColor: AppColors.surface,
    dialogBackgroundColor: AppColors.surface,
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.surface,
      modalBackgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceHigh,
      hintStyle: AppFonts.regular14.copyWith(color: AppColors.onSurfaceMuted),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
    ),
    cardTheme: _cardThemeData(),
    textSelectionTheme: _textSelectionThemeData(),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.appBarBackground,
      foregroundColor: AppColors.appBarTitle,
      surfaceTintColor: Colors.transparent,
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
        foregroundColor: AppColors.background,
        disabledBackgroundColor: AppColors.textDisabled,
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
    color: AppColors.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
    ),
    elevation: 0,
    margin: EdgeInsets.zero,
  );
}
