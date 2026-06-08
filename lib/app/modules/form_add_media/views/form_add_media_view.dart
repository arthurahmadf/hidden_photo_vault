import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:hidden_photo_vault/app/core/services/media_picker_service.dart';
import 'package:hidden_photo_vault/app/core/style/app_colors.dart';
import 'package:hidden_photo_vault/app/core/style/app_fonts.dart';
import 'package:hidden_photo_vault/app/core/widgets/app_form_widget.dart';
import 'package:hidden_photo_vault/app/core/widgets/appbar_custom_widget.dart';
import 'package:hidden_photo_vault/app/core/widgets/media_preview_container.dart';

import '../controllers/form_add_media_controller.dart';

class FormAddMediaView extends GetView<FormAddMediaController> {
  const FormAddMediaView({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppBarCustom(title: "New Media"),
      body: Container(
        width: 1.sw,
        height: 1.sh,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.w),
        child: GetBuilder<FormAddMediaController>(
          init: FormAddMediaController(),
          initState: (_) {},
          builder: (_) {
            return Column(
              children: [
                MediaPreviewContainer(
                  mediaType: controller.mediaType,
                  pickType: MediaType.any,
                  file: controller.file,
                  borderRadius: 8.r,
                  onChanged: (result) {
                    controller.file = result?.file;
                    controller.mediaType = result?.resolvedType;
                    controller.update();
                  },
                ),
                12.verticalSpace,
                if (controller.file != null) ...[
                  Text(
                    controller.file?.name ?? "-",
                    style: AppFonts.medium14,
                  ),
                  8.verticalSpace,
                  Text(
                    controller.file?.path ?? "-",
                    style: AppFonts.regular8.copyWith(
                      color: AppColors.textSubfont,
                    ),
                  ),
                  12.verticalSpace,
                  AppTextField(controller: controller.tagTextController, hintText: "Insert Tag (Optional)"),
                  const Spacer(),
                  GestureDetector(
                    onTap: controller.onSaveMediaPressed,
                    child: Container(
                      width: 1.sw,
                      padding: EdgeInsets.symmetric(vertical: 12.w),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        "Save Media",
                        textAlign: TextAlign.center,
                        style: AppFonts.medium14.copyWith(color: Colors.white),
                      ),
                    ),
                  )
                ] else ...[
                  12.verticalSpace,
                  Text(
                    "No image selected yet\n\nPick a media from your camera or gallery to continue.",
                    style: AppFonts.medium16,
                    textAlign: TextAlign.center,
                  )
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
