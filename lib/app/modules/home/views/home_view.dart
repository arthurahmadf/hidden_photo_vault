import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:hidden_photo_vault/app/core/style/app_colors.dart';
import 'package:hidden_photo_vault/app/core/style/app_fonts.dart';

import '../controllers/home_controller.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.small(
        onPressed: () => controller.onAddMediaPressed(),
        backgroundColor: AppColors.secondary,
        elevation: 3,
        child: Icon(
          Icons.add,
          size: 28.w,
          color: AppColors.background,
        ),
      ).paddingOnly(right: 16.w, bottom: 24.w),
      body: SizedBox(
        width: 1.sw,
        height: 1.sh,
        child: Column(
          children: [
            SafeArea(
              child: Container(
                color: AppColors.background,
                padding: EdgeInsets.all(12.w),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => controller.onVaultTapped(),
                      child: Icon(
                        Icons.view_in_ar_outlined,
                        size: 24.w,
                        color: AppColors.secondary,
                      ),
                    ),
                    8.horizontalSpace,
                    GestureDetector(
                      onTap: controller.getImages,
                      child: Text(
                        "mY Gallery",
                        style: AppFonts.bold18.copyWith(color: Colors.white),
                      ),
                    ),
                    const Spacer(),
                    Obx(
                      () {
                        if (controller.selectedVault.value.id != "public") {
                          return GestureDetector(
                            onTap: () => controller.onCloseVaultTapped(),
                            child: Icon(
                              Icons.exit_to_app,
                              size: 18.w,
                              color: AppColors.error,
                            ),
                          );
                        }
                        return const SizedBox();
                      },
                    )
                  ],
                ),
              ),
            ),
            Expanded(
              child: GetBuilder<HomeController>(
                init: HomeController(),
                initState: (_) {},
                builder: (_) {
                  return Obx(
                    () => GridView.builder(
                      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 6.w),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        crossAxisSpacing: 6.w,
                        mainAxisSpacing: 6.w,
                      ),
                      itemCount: controller.images.length,
                      itemBuilder: (context, index) {
                        final imageMeta = controller.images[index];
                        final bytes = controller.thumbCache[imageMeta.id];
                        if (bytes == null) return Container(color: Colors.grey.shade200);
                        return GestureDetector(
                          onTap: () => controller.onMediaTapped(imageMeta, index),
                          child: Hero(
                            tag: "media_${imageMeta.id}",
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4.r),
                              child: Image.memory(
                                bytes,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
