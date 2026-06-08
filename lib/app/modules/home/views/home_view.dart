import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:hidden_photo_vault/app/core/consts/app_icons.dart';
import 'package:hidden_photo_vault/app/core/style/app_colors.dart';
import 'package:hidden_photo_vault/app/core/style/app_fonts.dart';

import '../controllers/home_controller.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) => controller.onBackPressed(didPop, context),
      child: Scaffold(
        backgroundColor: AppColors.secondary,
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
              GetBuilder<HomeController>(
                builder: (controller) {
                  var isPrivate = controller.selectedVault.value.id != "public";
                  return SafeArea(
                    child: Container(
                      color: AppColors.secondary,
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.w),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => controller.onVaultTapped(),
                            child: Container(
                              padding: EdgeInsets.all(8.w),
                              decoration: BoxDecoration(
                                color: isPrivate ? AppColors.background : AppColors.background,
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              child: Icon(
                                isPrivate ? Icons.security_rounded : Icons.view_in_ar_outlined,
                                size: 16.w,
                                color: isPrivate ? Colors.red : AppColors.primary,
                              ),
                            ),
                          ),
                          8.horizontalSpace,
                          GestureDetector(
                            onTap: controller.getImages,
                            child: Text(
                              isPrivate ? controller.selectedVault.value.name ?? "mY Gallery (P)" : "mY Gallery",
                              style: AppFonts.bold18.copyWith(color: AppColors.background),
                            ),
                          ),
                          const Spacer(),
                          Obx(
                            () {
                              if (controller.selectedVault.value.id != "public") {
                                return Row(
                                  children: [
                                    GestureDetector(
                                      onTap: () => controller.onSettingTapped(),
                                      child: Icon(
                                        Icons.settings,
                                        size: 20.w,
                                        color: AppColors.background,
                                      ),
                                    ),
                                    12.horizontalSpace,
                                    GestureDetector(
                                      onTap: () => controller.onCloseVaultTapped(),
                                      child: Icon(
                                        Icons.exit_to_app,
                                        size: 20.w,
                                        color: AppColors.error,
                                      ),
                                    ),
                                  ],
                                );
                              }
                              return Row(
                                children: [
                                  GestureDetector(
                                    onTap: () => controller.onSettingTapped(),
                                    child: Icon(
                                      Icons.settings,
                                      size: 20.w,
                                      color: AppColors.background,
                                    ),
                                  )
                                ],
                              );
                            },
                          )
                        ],
                      ),
                    ),
                  );
                },
              ),
              Expanded(
                child: GetBuilder<HomeController>(
                  init: HomeController(),
                  initState: (_) {},
                  builder: (_) {
                    return Container(
                      color: AppColors.background,
                      child: Obx(
                        () {
                          final isPrivate = controller.selectedVault.value.id != "public";
                          if (controller.images.isEmpty) {
                            return Column(
                              children: [
                                if (isPrivate) ...[
                                  Container(
                                    width: 1.sw,
                                    color: Colors.red,
                                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.w),
                                    child: Text(
                                      "SECRET VAULT ACTIVE",
                                      style: AppFonts.bold14.copyWith(color: Colors.white),
                                    ),
                                  ),
                                  12.verticalSpace,
                                ],
                                Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.w),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Image.asset(
                                          AppIcons.no_image,
                                          width: .3.sw,
                                        ),
                                        12.verticalSpace,
                                        Text(
                                          "Nothing here yet. Capture or upload your first photo to start building your gallery.",
                                          style: AppFonts.medium14,
                                          textAlign: TextAlign.center,
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }

                          return Column(
                            children: [
                              if (isPrivate) ...[
                                Container(
                                  width: 1.sw,
                                  color: Colors.red,
                                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.w),
                                  child: Text(
                                    "SECRET VAULT ACTIVE",
                                    style: AppFonts.bold14.copyWith(color: Colors.white),
                                  ),
                                ),
                                12.verticalSpace,
                              ],
                              Expanded(
                                child: GridView.builder(
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
                              ),
                            ],
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
      ),
    );
  }
}
