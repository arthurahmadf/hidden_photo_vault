// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';


import '../consts/app_svg.dart';
import '../style/app_colors.dart';
import '../style/app_fonts.dart';
import 'app_surface_widget.dart';

// Default styling variables for easy modification
EdgeInsets defaultPadding = EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.w);
final TextStyle defaultLabelStyle = AppFonts.regular13;
final TextStyle defaultTextStyle = AppFonts.regular13.copyWith(color: Colors.black);
final TextStyle defaultHintStyle = AppFonts.regular13.copyWith(color: AppColors.textSecondary);

InputDecoration appInputDecoration({
  String? hintText,
  Widget? prefixIcon,
  Widget? suffixIcon,
  bool enabled = true,
  bool useBorder = false,
  bool filled = true,
  // Widget? label,
  String? label,
  bool isMandatory = false,
}) {
  return InputDecoration(
    hintText: hintText,
    labelText: label,
    // label: isMandatory
    //     ? RichText(
    //         text: TextSpan(
    //           children: [
    //             TextSpan(text: label, style: AppFonts.regular12.copyWith(color: null)),
    //             TextSpan(text: " *", style: AppFonts.regular14.copyWith(color: AppColors.error))
    //           ],
    //         ),
    //       )
    //     : Text(
    //         label ?? "",
    //         style: AppFonts.regular12.copyWith(color: null),
    //       ),
    labelStyle: AppFonts.regular12.copyWith(
      color: AppColors.textSecondary,
    ),
    floatingLabelStyle: AppFonts.regular15.copyWith(
      color: Colors.black,
    ),
    hintStyle: defaultHintStyle,
    suffixIcon: Padding(
      padding: EdgeInsets.only(left: 8.w, right: 12.w),
      child: suffixIcon,
    ),
    suffixIconColor: AppColors.iconPrimary,
    suffixIconConstraints: BoxConstraints(minHeight: 15.w, minWidth: 15.w),
    prefixIcon: Padding(
      padding: EdgeInsets.only(left: 12.w, right: 8.w),
      child: prefixIcon,
    ),
    prefixIconColor: AppColors.iconPrimary,
    prefixIconConstraints: BoxConstraints(minHeight: 15.w, minWidth: 15.w),
    border: OutlineInputBorder(
      borderSide: useBorder ? const BorderSide(color: AppColors.primary) : BorderSide.none,
      borderRadius: BorderRadius.circular(8.r),
    ),
    enabledBorder: OutlineInputBorder(
      borderSide: useBorder ? const BorderSide(color: Color(0xFFE6E6E6)) : BorderSide.none,
      borderRadius: BorderRadius.circular(8.r),
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: const BorderSide(color: AppColors.primary),
      borderRadius: BorderRadius.circular(8.r),
    ),
    disabledBorder: OutlineInputBorder(
      borderSide: useBorder ? const BorderSide(color: AppColors.textDisabled) : BorderSide.none,
      borderRadius: BorderRadius.circular(8.r),
    ),
    errorBorder: OutlineInputBorder(
      borderSide: const BorderSide(color: AppColors.error),
      borderRadius: BorderRadius.circular(8.r),
    ),
    fillColor: enabled ? Colors.white : Colors.grey[300],
    filled: filled,
    contentPadding: EdgeInsets.symmetric(
      horizontal: 12.w,
      vertical: 12.w,
    ),
  );
}

/// A reusable form widget with default padding
/// Usage Example:
/// ```dart
/// AppForm(
///   formKey: _formKey,
///   children: [
///     AppTextField(controller: _controller, label: 'Name'),
///     AppDropdown(items: ['Option 1', 'Option 2'], onChanged: (val) {}),
///   ],
/// )
/// ```
class AppForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final List<Widget> children;
  final EdgeInsetsGeometry? padding;

  const AppForm({
    required this.formKey,
    required this.children,
    this.padding,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Padding(
        padding: padding ?? defaultPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: children,
        ),
      ),
    );
  }
}

/// A reusable text field with optional label, prefix, and suffix icons
/// Usage Example:
/// ```dart
/// AppTextField(
///   controller: _controller,
///   label: 'Email',
///   hintText: 'Enter your email',
///   prefixIcon: Icon(Icons.email),
/// )
/// ```
class AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String? label;
  final String? hintText;
  final String? tip;
  final bool obscureText;
  final bool enabled;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final String? Function(String? value)? validator;
  final TextStyle? textStyle;
  final Function(String value)? onUnfocus;
  final int? maxLines;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final Function(String value)? onChanged;
  final bool useBorder;
  final bool readOnly;
  final Function()? onTap;
  final EdgeInsetsGeometry? padding;
  final List<Color>? innerGradient;
  final bool isMandatory;

  const AppTextField({
    required this.controller,
    this.label,
    this.hintText,
    this.tip,
    this.obscureText = false,
    this.enabled = true,
    this.prefixIcon,
    this.suffixIcon,
    this.validator,
    this.textStyle,
    this.onUnfocus,
    this.maxLines = 1,
    this.keyboardType,
    this.inputFormatters,
    this.onChanged,
    this.useBorder = true,
    this.readOnly = false,
    this.onTap,
    this.padding,
    this.innerGradient,
    this.isMandatory = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        FocusScope.of(context).unfocus();
        if (onUnfocus != null) {
          onUnfocus!(controller.text);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6.r),
        ),
        // padding: padding ?? AppDimension.containerPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: controller,
              keyboardType: keyboardType,
              inputFormatters: inputFormatters,
              readOnly: readOnly,
              onTap: onTap,
              decoration: appInputDecoration(
                hintText: hintText ?? "Masukkan ${label?.toLowerCase()} ...",
                prefixIcon: prefixIcon,
                suffixIcon: suffixIcon,
                enabled: enabled,
                useBorder: useBorder,
                filled: false,
                isMandatory: isMandatory,
                label: isMandatory ? "$label *" : label,
                // label: isMandatory
                //     ? RichText(
                //         text: TextSpan(
                //           children: [
                //             TextSpan(text: label, style: AppFonts.regular12.copyWith(color: null)),
                //             TextSpan(text: " *", style: AppFonts.regular14.copyWith(color: AppColors.error))
                //           ],
                //         ),
                //       )
                //     : Text(
                //         label ?? "",
                //         style: AppFonts.regular12.copyWith(color: null),
                //       ),
              ),
              obscureText: obscureText,
              validator: validator,
              style: textStyle ?? defaultTextStyle,
              maxLines: maxLines,
              onChanged: onChanged ?? (_) {},
            ),
            if (tip != null) ...[
              6.verticalSpace,
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.tips_and_updates_rounded,
                    color: AppColors.primary,
                    size: AppFonts.medium10.fontSize!.w,
                  ),
                  4.horizontalSpace,
                  Expanded(
                    child: Text(
                      tip!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppFonts.medium10.copyWith(color: AppColors.primary),
                    ),
                  )
                ],
              )
            ]
          ],
        ),
      ),
    );
  }
}

/// A reusable dropdown with support for object lists
/// Usage Example:
/// ```dart
/// Obx(() => AppDropdown(
///   items: myList,
///   itemLabel: (item) => item.name,
///   value: controller.selectedItem.value,
///   onChanged: (val) => controller.selectedItem.value = val,
/// ))
/// ```
class AppDropdown<T> extends StatelessWidget {
  final List<T> items;
  final T? value;
  final String? label;
  final String Function(T item)? itemLabel;
  final void Function(T? value)? onChanged;
  final bool enabled;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final bool isMandatory;

  const AppDropdown({
    required this.items,
    required this.itemLabel,
    this.suffixIcon,
    this.prefixIcon,
    this.value,
    this.label,
    this.onChanged,
    this.enabled = true,
    this.isMandatory = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6.r)),
      width: 1.sw,
      child: DropdownButtonFormField<T>(
        value: value,
        elevation: 0,
        padding: EdgeInsets.zero,
        isExpanded: true,
        iconSize: 0.w,
        selectedItemBuilder: (context) {
          return items.map((T item) {
            return Align(
              alignment: Alignment.centerLeft,
              child: Text(
                itemLabel!(item),
                style: defaultTextStyle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList();
        },
        items: items.map((T item) {
          return DropdownMenuItem<T>(
            value: item,
            child: AppSurface(
              elevation: 2,
              radius: 8,
              child: Container(
                width: 1.sw,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.w),
                child: Text(
                  itemLabel!(item),
                  style: AppFonts.medium12,
                ),
              ),
            ),
          );
        }).toList(),
        onChanged: enabled ? onChanged : null,
        dropdownColor: AppColors.background,
        decoration: appInputDecoration(
          label: isMandatory ? "$label *" : label,
          suffixIcon: suffixIcon ??
              SvgPicture.asset(
                AppSvg.chevron_down,
                color: AppColors.primary,
                width: 15.w,
                height: 15.w,
              ),
          prefixIcon: prefixIcon,
          isMandatory: isMandatory,
          filled: false,
          hintText: "Pilih ${label?.toLowerCase()} ...",
          enabled: enabled,
          useBorder: true,
        ),
      ),
    );
  }
}
