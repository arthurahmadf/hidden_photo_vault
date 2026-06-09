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
          child: Icon(Icons.add, size: 28.w, color: AppColors.background),
        ).paddingOnly(right: 16.w, bottom: 24.w),
        body: SizedBox(
          width: 1.sw,
          height: 1.sh,
          child: Column(
            children: [
              // ── App bar ───────────────────────────────────────────────────
              GetBuilder<HomeController>(
                builder: (controller) {
                  final isPrivate = controller.selectedVault.value.id != "public";
                  return SafeArea(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.secondary,
                        border: Border(
                          bottom: BorderSide(
                            color: isPrivate ? Colors.red : Colors.transparent,
                            width: 2.w,
                          ),
                        ),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.w),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => controller.onVaultTapped(),
                            child: Container(
                              padding: EdgeInsets.all(8.w),
                              decoration: BoxDecoration(
                                color: AppColors.background,
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
                          Text(
                            isPrivate ? controller.selectedVault.value.name ?? "mY Gallery (P)" : "mY Gallery",
                            style: AppFonts.bold18.copyWith(color: AppColors.background),
                          ),
                          const Spacer(),
                          Obx(() {
                            final isPrivate = controller.selectedVault.value.id != "public";
                            return Row(
                              children: [
                                // Group toggle
                                GestureDetector(
                                  onTap: () => controller.isGrouped.toggle(),
                                  child: Icon(
                                    controller.isGrouped.value ? Icons.tag : Icons.tag_outlined,
                                    size: 20.w,
                                    color: controller.isGrouped.value ? AppColors.success : AppColors.background,
                                  ),
                                ),
                                12.horizontalSpace,
                                GestureDetector(
                                  onTap: () => controller.onSettingTapped(),
                                  child: Icon(Icons.settings, size: 20.w, color: AppColors.background),
                                ),
                                if (isPrivate) ...[
                                  12.horizontalSpace,
                                  GestureDetector(
                                    onTap: () => controller.onCloseVaultTapped(),
                                    child: Icon(Icons.exit_to_app, size: 20.w, color: AppColors.error),
                                  ),
                                ],
                              ],
                            );
                          }),
                        ],
                      ),
                    ),
                  );
                },
              ),

              // ── Body ──────────────────────────────────────────────────────
              Expanded(
                child: GetBuilder<HomeController>(
                  builder: (_) {
                    return Container(
                      color: AppColors.background,
                      child: Obx(() {
                        final images = controller.images;
                        return Column(
                          children: [
                            // // Secret vault banner
                            // if (isPrivate)
                            //   Container(
                            //     width: 1.sw,
                            //     color: Colors.red,
                            //     padding: EdgeInsets.symmetric(
                            //       horizontal: 12.w,
                            //       vertical: 8.w,
                            //     ),
                            //     child: Text(
                            //       "SECRET VAULT ACTIVE",
                            //       style: AppFonts.bold14.copyWith(color: Colors.white),
                            //     ),
                            //   ),

                            Expanded(
                              child: images.isEmpty
                                  ? const _EmptyState()
                                  : controller.isGrouped.value
                                      ? _GroupedGrid(controller: controller)
                                      : _FlatGrid(controller: controller),
                            ),
                          ],
                        );
                      }),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Flat grid (no grouping)
// ─────────────────────────────────────────────────────────────────────────────

class _FlatGrid extends StatelessWidget {
  final HomeController controller;
  const _FlatGrid({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() => GridView.builder(
          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 6.w),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: controller.gridCount.value,
            crossAxisSpacing: 6.w,
            mainAxisSpacing: 6.w,
          ),
          itemCount: controller.images.length,
          itemBuilder: (context, index) {
            final media = controller.images[index];
            return _GridTile(
              media: media,
              globalIndex: index,
              controller: controller,
            );
          },
        ));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Grouped grid (by tag)
// ─────────────────────────────────────────────────────────────────────────────

class _GroupedGrid extends StatelessWidget {
  final HomeController controller;
  const _GroupedGrid({required this.controller});

  @override
  Widget build(BuildContext context) {
    final grouped = controller.groupedImages;

    return ListView.builder(
      padding: EdgeInsets.only(top: 12.w, bottom: 100.w),
      itemCount: grouped.length,
      itemBuilder: (context, sectionIndex) {
        final tag = grouped.keys.elementAt(sectionIndex);
        final mediaList = grouped[tag]!;
        return _TagSection(
          tag: tag,
          mediaList: mediaList,
          controller: controller,
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tag section — optional header + grid
// ─────────────────────────────────────────────────────────────────────────────

class _TagSection extends StatelessWidget {
  final String tag;
  final List mediaList;
  final HomeController controller;

  const _TagSection({
    required this.tag,
    required this.mediaList,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final showHeader = tag != 'default';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header — hidden for default tag
        if (showHeader)
          Padding(
            padding: EdgeInsets.only(left: 12.w, right: 12.w, bottom: 8.w),
            child: Row(
              children: [
                Icon(Icons.tag, size: 14.w, color: AppColors.primary),
                6.horizontalSpace,
                Text(
                  tag,
                  style: AppFonts.bold14.copyWith(color: AppColors.secondary),
                ),
                6.horizontalSpace,
                Text(
                  '${mediaList.length}',
                  style: AppFonts.medium14.copyWith(
                    color: AppColors.secondary.withOpacity(0.4),
                  ),
                ),
              ],
            ),
          ),

        // Grid
        Obx(() => GridView.builder(
              padding: EdgeInsets.symmetric(horizontal: 6.w),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: controller.gridCount.value,
                crossAxisSpacing: 6.w,
                mainAxisSpacing: 6.w,
              ),
              itemCount: mediaList.length,
              itemBuilder: (context, index) {
                final media = mediaList[index];
                final globalIndex = controller.images.indexOf(media);
                return _GridTile(
                  media: media,
                  globalIndex: globalIndex,
                  controller: controller,
                );
              },
            )),

        SizedBox(height: 20.w),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Grid tile — shared between flat and grouped
// ─────────────────────────────────────────────────────────────────────────────

class _GridTile extends StatelessWidget {
  final dynamic media;
  final int globalIndex;
  final HomeController controller;

  const _GridTile({
    required this.media,
    required this.globalIndex,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final bytes = controller.thumbCache[media.id];
    if (bytes == null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(4.r),
        child: Container(color: Colors.grey.shade200),
      );
    }
    return GestureDetector(
      onTap: () => controller.onMediaTapped(media, globalIndex),
      child: Hero(
        tag: "media_${media.id}",
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4.r),
          child: Image.memory(bytes, fit: BoxFit.cover),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty state
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(AppIcons.no_image, width: .3.sw),
          12.verticalSpace,
          Text(
            "Nothing here yet. Capture or upload your first photo to start building your gallery.",
            style: AppFonts.medium14,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
