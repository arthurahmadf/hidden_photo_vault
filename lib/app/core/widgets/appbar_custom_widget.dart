import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../style/app_colors.dart';
import '../style/app_fonts.dart';

// Global settings for easier editing
const Color appBarBackgroundColor = AppColors.appBarBackground;
const Color appBarTitleColor = AppColors.appBarTitle;
const Color appBarIconColor = AppColors.appBarIcon;
const double elevation = 0;

// Default font style
TextStyle defaultAppBarTitleStyle = AppFonts.bold16.copyWith(color: AppColors.appBarTitle);

class AppBarCustom extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final TextStyle? titleStyle;
  final VoidCallback? onBackPressed;
  final List<Widget>? actions;
  final double height;
  final double? borderRadius;
  final Color? backgroundColor;
  final Widget? leading;
  final bool centerTitle;
  final bool? useLeading;
  final Widget? bottom;
  final Widget? widgetTitle;

  const AppBarCustom.simple({
    super.key,
    this.onBackPressed,
    this.height = 48,
    this.widgetTitle,
    Color? background,
  })  : title = "",
        titleStyle = null,
        actions = const [],
        borderRadius = 0,
        backgroundColor = background ?? AppColors.background,
        leading = null,
        centerTitle = false,
        useLeading = true,
        bottom = null;

  const AppBarCustom({
    super.key,
    required this.title,
    this.titleStyle,
    this.onBackPressed,
    this.actions,
    this.height = 60,
    this.borderRadius,
    this.backgroundColor,
    this.leading,
    this.centerTitle = false,
    this.useLeading,
    this.bottom,
    this.widgetTitle,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: backgroundColor ?? appBarBackgroundColor,
      flexibleSpace: Container(
        width: 1.sw,
        color: backgroundColor ?? appBarBackgroundColor,
      ),
      elevation: elevation,
      centerTitle: centerTitle,
      toolbarHeight: height.w,
      title: widgetTitle ??
          Text(
            title,
            textAlign: TextAlign.center,
            style: titleStyle ?? defaultAppBarTitleStyle.copyWith(color: AppColors.primary, height: 1.w),
          ).paddingOnly(left: useLeading ?? true ? 0.w : 12.w),
      leading: useLeading ?? true
          ? InkWell(
              onTap: onBackPressed ?? () => Get.back(),
              child: leading ??
                  Icon(
                    Icons.chevron_left,
                    size: 24.w,
                    color: AppColors.primary,
                  ).paddingSymmetric(horizontal: 9.w, vertical: 6.w),
            )
          : null,
      // leading: centerTitle
      //     ? leading ??
      //         IconButton(
      //           onPressed: onBackPressed ?? () => Get.back(),
      //           icon: Icon(Icons.arrow_back, color: appBarIconColor, size: 18.w),
      //         )
      //     : null,
      actions: actions ?? [],

      titleSpacing: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(borderRadius?.r ?? 0.r),
        ),
      ),
      bottom: bottom != null
          ? PreferredSize(
              preferredSize: Size.fromHeight(kToolbarHeight.w),
              child: bottom!,
            )
          : null,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(height);
}
