// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../style/app_colors.dart';
import '../style/app_fonts.dart';



/// A service to manage different types of dialogs in the application.
///
/// This service provides various types of dialogs, including loading dialogs,
/// confirmation dialogs, and alert dialogs with single or double buttons.
abstract class DialogService {
  /// **Default background color for dialogs**
  static const Color defaultBackgroundColor = Colors.white;

  /// **Default overlay color for dimming the background**
  static const Color defaultOverlayColor = Colors.black54;

  /// **Default border radius for dialog containers**
  static final double defaultBorderRadius = 12.0.r;

  /// **Default padding inside dialogs**
  static final EdgeInsets defaultPadding = EdgeInsets.symmetric(
    vertical: 16.h,
    horizontal: 32.w,
  );

  /// **Unified text styles using default Flutter fonts**
  /// - `titleLarge`: Used for dialog titles (bold, 18.sp)
  /// - `bodyMedium`: Used for general body text (14.sp)
  /// - `labelLarge`: Used for buttons or highlighted text (14.sp, semi-bold)
  static TextTheme textTheme = TextTheme(
    titleLarge: AppFonts.bold18,
    bodyMedium: AppFonts.medium14,
    labelLarge: AppFonts.regular14,
  );

  static void unauthorized({String? info, String? title}) {
    var infoString = info != null ? "Anda tidak mempunyai izin.\n($info)" : "Anda tidak mempunyai izin.";
    showSingleButtonDialog(message: infoString, title: title ?? "Gagal", isWarning: true);
  }

  /// Displays a loading dialog with customization options.
  ///
  /// - [dismissible]: If `true`, the dialog can be dismissed by tapping outside.
  /// - [label]: Custom label text for the loading dialog.
  /// - [backgroundColor]: Background color of the loading widget.
  /// - [overlayColor]: Background overlay color (default is provided by `).
  /// - [borderRadius]: Custom border radius for the loading dialog.
  /// - [padding]: Padding around the loading widget.
  static void showLoading({
    bool dismissible = true,
    String? label,
    Color? backgroundColor,
    double? borderRadius,
    EdgeInsets? padding,
  }) {
    closeDialog();
    Get.dialog(
      PopScope(
        canPop: dismissible,
        child: Dialog(
          insetPadding: EdgeInsets.symmetric(horizontal: 60.w),
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                padding: EdgeInsets.symmetric(horizontal: 40.w, vertical: 20.w),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 4.w,
                    ),
                    if (label != null) ...[
                      15.verticalSpace,
                      Text(
                        label,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: AppFonts.bold16.copyWith(color: Colors.white),
                      ),
                    ]
                  ],
                ),
              )
            ],
          ),
        ),
      ),
      barrierDismissible: dismissible,
      barrierColor: Colors.black.withOpacity(.4),
    );
  }

  static void showCustom({
    bool dismissible = true,
    required Widget child,
  }) {
    closeDialog();
    Get.dialog(
      WillPopScope(
        onWillPop: () async => dismissible,
        child: Dialog(
          // insetPadding: EdgeInsets.symmetric(horizontal: 60.w),
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          child: Wrap(
            children: [
              Center(
                child: child,
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: dismissible,
      barrierColor: Colors.black.withOpacity(.4),
    );
  }

  static void showBarrier({
    bool dismissible = true,
    Color? backgroundColor,
  }) {
    closeDialog();
    Get.dialog(
      WillPopScope(
        onWillPop: () async => dismissible,
        child: Dialog(
          insetPadding: EdgeInsets.symmetric(horizontal: 60.w),
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          child: const SizedBox(),
        ),
      ),
      barrierDismissible: dismissible,
      barrierColor: backgroundColor ?? Colors.black.withOpacity(.1),
    );
  }

  /// Closes any currently open dialog.
  static void closeDialog() {
    if (Get.isDialogOpen ?? false) {
      Get.back();
    }
  }

  /// Shows a date picker dialog and returns the selected date.
  ///
  /// - [initialDate]: The default date shown when the picker opens.
  /// - [onDateSelected]: A callback function that receives the selected date.
  static Future<void> showDatePickerDialog({
    required DateTime initialDate,
    required Function(DateTime selectedDate) onDateSelected,
    required BuildContext context,
  }) async {
    DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now().subtract(const Duration(days: 36500)),
      lastDate: DateTime.now().add(const Duration(days: 36500)),
      confirmText: "Simpan",
      cancelText: "Batal",
      locale: Get.locale,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            datePickerTheme: DatePickerThemeData(
              headerBackgroundColor: AppColors.primary,
              headerForegroundColor: Colors.white,
              todayForegroundColor: const WidgetStatePropertyAll(Colors.white),
              todayBackgroundColor: const WidgetStatePropertyAll(AppColors.primary),
              headerHelpStyle: AppFonts.medium12.copyWith(color: Colors.white),
              headerHeadlineStyle: AppFonts.bold16.copyWith(color: Colors.white),
              dayStyle: AppFonts.medium14.copyWith(color: Colors.grey),
              weekdayStyle: AppFonts.medium14,
              confirmButtonStyle: ButtonStyle(
                elevation: const WidgetStatePropertyAll(1),
                foregroundColor: const WidgetStatePropertyAll(AppColors.primary),
                textStyle: WidgetStatePropertyAll(
                  AppFonts.bold14,
                ),
              ),
              cancelButtonStyle: ButtonStyle(
                elevation: const WidgetStatePropertyAll(1),
                foregroundColor: const WidgetStatePropertyAll(Colors.grey),
                textStyle: WidgetStatePropertyAll(
                  AppFonts.bold14,
                ),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (selectedDate != null) {
      onDateSelected(selectedDate);
    }
  }

  /// Shows a month picker dialog (select month + year only).
  ///
  /// - [initialDate]: Starting point (default current month).
  /// - [onMonthSelected]: Returns DateTime with selected year/month.
  static Future<void> showMonthPickerDialog({
    required BuildContext context,
    required DateTime initialDate,
    required Function(DateTime selectedDate) onMonthSelected,
  }) async {
    int selectedYear = initialDate.year;
    int selectedMonth = initialDate.month;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          titlePadding: EdgeInsets.only(top: 12.w, left: 16.w, right: 16.w),
          contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.w),
          actionsPadding: EdgeInsets.only(bottom: 8.w, right: 8.w),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Pilih Bulan", style: AppFonts.semibold16),
              DropdownButton<int>(
                value: selectedYear,
                items: List.generate(20, (index) {
                  int year = DateTime.now().year - 10 + index;
                  return DropdownMenuItem(
                      value: year,
                      child: Text(
                        "$year",
                        style: AppFonts.medium14,
                      ));
                }),
                onChanged: (val) {
                  if (val != null) {
                    selectedYear = val;
                    (context as Element).markNeedsBuild();
                  }
                },
              ),
            ],
          ),
          content: SizedBox(
            width: 300.w,
            child: GridView.builder(
              shrinkWrap: true,
              itemCount: 12,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemBuilder: (context, index) {
                final month = index + 1;
                final isSelected = month == selectedMonth && selectedYear == initialDate.year;
                return InkWell(
                  borderRadius: BorderRadius.circular(8.r),
                  onTap: () {
                    selectedMonth = month;
                    onMonthSelected(DateTime(selectedYear, selectedMonth));
                    Navigator.pop(context);
                  },
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.blue : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? Colors.blue : Colors.grey.shade300,
                      ),
                    ),
                    child: Text(
                      DateFormat.MMM(Get.locale?.toString()).format(DateTime(0, month)),
                      style: AppFonts.medium12.copyWith(color: isSelected ? Colors.white : Colors.black87),
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Batal",
                style: AppFonts.medium12.copyWith(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Displays a confirmation dialog with two customizable buttons.
  ///
  /// - [title]: The dialog title.
  /// - [message]: The main content message.
  /// - [positiveText]: The text for the confirmation button.
  /// - [onPositive]: Function executed when the confirmation button is pressed.
  /// - [negativeText]: The text for the cancel button.
  /// - [onNegative]: Function executed when the cancel button is pressed.
  static showDoubleButtonDialog({
    required String title,
    required String message,
    required String positiveText,
    required VoidCallback onPositive,
    required String negativeText,
    required VoidCallback onNegative,
    Widget? titleIcon,
    IconData? titleIconPath,
  }) {
    final BuildContext? context = Get.context;
    if (context == null) return;
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
        backgroundColor: Colors.white,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: AppFonts.medium18,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  titleIcon ??
                      Icon(
                        titleIconPath ?? Icons.warning,
                        color: Colors.red,
                        size: AppFonts.bold18.fontSize!.w,
                      ),
                ],
              ),
              6.verticalSpace,
              Divider(
                color: Colors.black12,
                thickness: 2.w,
              ),
              6.verticalSpace,
              Text(
                message,
                style: AppFonts.regular14,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.start,
              ).paddingZero,
              30.verticalSpace,
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SizedBox(
                    width: .25.sw,
                    child: ElevatedButton(
                      style: ButtonStyle(
                        visualDensity: VisualDensity.compact,
                        backgroundColor: const WidgetStatePropertyAll(AppColors.background),
                        padding: WidgetStatePropertyAll(
                          EdgeInsets.symmetric(horizontal: 4.w, vertical: 4.w),
                        ),
                      ),
                      onPressed: onNegative,
                      child: Text(
                        negativeText,
                        style: AppFonts.semibold14.copyWith(color: Colors.black),
                      ),
                    ),
                  ),
                  6.horizontalSpace,
                  SizedBox(
                    width: .25.sw,
                    child: ElevatedButton(
                      style: ButtonStyle(
                        visualDensity: VisualDensity.compact,
                        backgroundColor: const WidgetStatePropertyAll(AppColors.error),
                        padding: WidgetStatePropertyAll(
                          EdgeInsets.symmetric(horizontal: 4.w, vertical: 4.w),
                        ),
                      ),
                      onPressed: onPositive,
                      child: Text(
                        positiveText,
                        style: AppFonts.semibold14.copyWith(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  /// Displays an alert dialog with a single button.
  ///
  /// - [title]: The title of the dialog (defaults to "Info" or "Warning").
  /// - [message]: The main content message.
  /// - [buttonText]: The label for the action button.
  /// - [onButtonPressed]: Function executed when the action button is pressed.
  /// - [isWarning]: If `true`, applies warning colors (default: `false` for info dialogs).
  static void showSingleButtonDialog({
    required String message,
    String buttonText = "OK",
    VoidCallback? onButtonPressed,
    required String title,
    bool dismissable = true,
    bool isWarning = false,
    Widget? titleIcon,
    IconData? titleIconPath,
  }) {
    final BuildContext? context = Get.context;
    if (context == null) return;

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6.r)),
        backgroundColor: Colors.white,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: AppFonts.semibold18,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (titleIcon != null) ...[
                    titleIcon
                  ] else ...[
                    if (titleIconPath != null) ...[
                      Icon(
                        titleIconPath,
                        color: AppColors.primary,
                        size: AppFonts.bold18.fontSize!.w,
                      )
                    ] else ...[
                      Icon(
                        isWarning ? Icons.warning_amber_rounded : Icons.check,
                        color: isWarning ? AppColors.error : AppColors.primary,
                        size: AppFonts.bold18.fontSize!.w,
                      )
                    ]
                  ]
                ],
              ),
              6.verticalSpace,
              Divider(
                color: Colors.black12,
                thickness: 2.w,
              ),
              6.verticalSpace,
              Text(
                message,
                style: AppFonts.regular14,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.start,
              ).paddingZero,
              32.verticalSpace,
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    style: ButtonStyle(
                        minimumSize: WidgetStatePropertyAll(
                          Size(.2.sw, 40.w),
                        ),
                        backgroundColor: WidgetStatePropertyAll(isWarning ? AppColors.error : AppColors.primary)),
                    onPressed: () => onButtonPressed != null ? onButtonPressed() : Get.back(),
                    child: Text(
                      buttonText,
                      style: AppFonts.semibold14.copyWith(color: Colors.white),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
      barrierDismissible: dismissable,
      barrierColor: Colors.black45,
    );
  }
}
