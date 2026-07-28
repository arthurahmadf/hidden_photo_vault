import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:hidden_photo_vault/app/core/consts/app_icons.dart';
import 'package:hidden_photo_vault/app/core/style/app_colors.dart';
import 'package:hidden_photo_vault/app/core/style/app_fonts.dart';
import 'package:hidden_photo_vault/app/data/models/gallery_media_model.dart';
import 'package:hidden_photo_vault/app/modules/home/views/home_appbar.dart';

import '../controllers/home_controller.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) => controller.onBackPressed(didPop, context),
      child: Scaffold(
        backgroundColor: AppColors.background,
        floatingActionButton: FloatingActionButton.small(
          onPressed: () => controller.onAddMediaPressed(),
          backgroundColor: AppColors.iconPrimary,
          elevation: 3,
          child: Icon(Icons.add, size: 28.w, color: AppColors.background),
        ).paddingOnly(right: 16.w, bottom: 24.w),
        body: SizedBox(
          width: 1.sw,
          height: 1.sh,
          child: Column(
            children: [
              // ── App bar ───────────────────────────────────────────────────
              // GetBuilder<HomeController>(
              //   builder: (controller) {
              //     final isPrivate = controller.selectedVault.value.id != "public";
              //     return SafeArea(
              //       child: Container(
              //         decoration: BoxDecoration(
              //           color: AppColors.secondary,
              //           border: Border(
              //             bottom: BorderSide(
              //               color: isPrivate ? Colors.red : Colors.transparent,
              //               width: 2.w,
              //             ),
              //           ),
              //         ),
              //         padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.w),
              //         child: Row(
              //           children: [
              //             GestureDetector(
              //               onTap: () => controller.onVaultTapped(),
              //               child: Container(
              //                 padding: EdgeInsets.all(8.w),
              //                 decoration: BoxDecoration(
              //                   color: AppColors.background,
              //                   borderRadius: BorderRadius.circular(8.r),
              //                 ),
              //                 child: Icon(
              //                   isPrivate ? Icons.security_rounded : Icons.view_in_ar_outlined,
              //                   size: 16.w,
              //                   color: isPrivate ? Colors.red : AppColors.primary,
              //                 ),
              //               ),
              //             ),
              //             8.horizontalSpace,
              //             Text(
              //               isPrivate ? controller.selectedVault.value.name ?? "mY Gallery (P)" : "mY Gallery",
              //               style: AppFonts.bold18.copyWith(color: AppColors.background),
              //             ),
              //             const Spacer(),
              //             Obx(() {
              //               final isPrivate = controller.selectedVault.value.id != "public";
              //               return Row(
              //                 children: [
              //                   // Group toggle
              //                   GestureDetector(
              //                     onTap: () => controller.isGrouped.toggle(),
              //                     child: Icon(
              //                       controller.isGrouped.value ? Icons.tag : Icons.tag_outlined,
              //                       size: 20.w,
              //                       color: controller.isGrouped.value ? AppColors.success : AppColors.background,
              //                     ),
              //                   ),
              //                   12.horizontalSpace,
              //                   GestureDetector(
              //                     onTap: () => controller.onSettingTapped(),
              //                     child: Icon(Icons.settings, size: 20.w, color: AppColors.background),
              //                   ),
              //                   if (isPrivate) ...[
              //                     12.horizontalSpace,
              //                     GestureDetector(
              //                       onTap: () => controller.onCloseVaultTapped(),
              //                       child: Icon(Icons.exit_to_app, size: 20.w, color: AppColors.error),
              //                     ),
              //                   ],
              //                 ],
              //               );
              //             }),
              //           ],
              //         ),
              //       ),
              //     );
              //   },
              // ),
              const HomeAppBar(),
              // ── Body ──────────────────────────────────────────────────────
              Expanded(
                child: GetBuilder<HomeController>(
                  builder: (_) {
                    return Container(
                      color: AppColors.secondary,
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
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.w),
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
    final onlyDefault = grouped.length == 1 && grouped.containsKey('default');

    return ListView.builder(
      padding: EdgeInsets.only(
        top: onlyDefault ? 12.w : 6.w,
        bottom: 100.w,
      ),
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
  final List<GalleryMedia> mediaList;
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
                  style: AppFonts.bold14.copyWith(color: AppColors.textPrimary),
                ),
                6.horizontalSpace,
                Text(
                  '${mediaList.length}',
                  style: AppFonts.medium14.copyWith(
                    color: AppColors.textPrimary.withOpacity(0.4),
                  ),
                ),
              ],
            ),
          ),

        // Grid
        Obx(() => GridView.builder(
              padding: EdgeInsets.symmetric(horizontal: 12.w),
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
  final GalleryMedia media;
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
        child: Container(color: AppColors.surfaceHigh),
      );
    }
    return GestureDetector(
      onTap: () => controller.onMediaTapped(media, globalIndex),
      child: Hero(
        tag: "media_${media.id}",
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4.r),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(
                color: AppColors.surface,
                child: Image.memory(bytes, fit: BoxFit.cover),
              ),
              if (media.isVideo) ...[
                const ColoredBox(color: Colors.black26),
                Center(
                  child: Container(
                    padding: EdgeInsets.all(6.w),
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 24.w,
                    ),
                  ),
                ),
                if (media.durationMs != null)
                  Positioned(
                    right: 5.w,
                    bottom: 4.w,
                    child: Text(
                      _formatMediaDuration(media.durationMs!),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w600,
                        shadows: const [
                          Shadow(color: Colors.black, blurRadius: 3),
                        ],
                      ),
                    ),
                  ),
              ] else if (media.isGif)
                Positioned(
                  top: 5.w,
                  right: 5.w,
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.w),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                    child: Text(
                      'GIF',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
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
          Container(
            padding: EdgeInsets.all(20.w),
            decoration: const BoxDecoration(
              color: AppColors.surfaceHighest,
              shape: BoxShape.circle,
            ),
            child: Image.asset(
              AppIcons.no_image,
              width: .2.sw,
              color: AppColors.iconPrimary,
            ),
          ),
          24.verticalSpace,
          Text(
            "Nothing here yet. Capture or upload your first photo, GIF, or video.",
            style: AppFonts.medium14.copyWith(color: AppColors.textPrimary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

String _formatMediaDuration(int milliseconds) {
  final duration = Duration(milliseconds: milliseconds);
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return hours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
}
