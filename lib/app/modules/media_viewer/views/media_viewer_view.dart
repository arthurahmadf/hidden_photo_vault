import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:hidden_photo_vault/app/data/models/gallery_media_model.dart';
import 'package:hidden_photo_vault/app/modules/media_viewer/controllers/media_viewer_controller.dart';

class MediaViewerView extends GetView<MediaViewerController> {
  const MediaViewerView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: controller.toggleOverlay,
        behavior: HitTestBehavior.opaque,
        child: Stack(
          children: [
            // ── Media PageView ──────────────────────────────────────────────
            Obx(() => PageView.builder(
                  controller: controller.pageController,
                  // freeze PageView when zoomed in so pan doesn't fight swipe
                  physics:
                      controller.isZoomed.value ? const NeverScrollableScrollPhysics() : const PageScrollPhysics(),
                  itemCount: controller.mediaList.length,
                  onPageChanged: controller.onPageChanged,
                  itemBuilder: (context, index) {
                    final media = controller.mediaList[index];
                    return _MediaPage(
                      key: ValueKey(media.id),
                      media: media,
                      controller: controller,
                    );
                  },
                )),

            // ── Top overlay ─────────────────────────────────────────────────
            Obx(() => AnimatedSlide(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeInOut,
                  offset: controller.overlayVisible.value ? Offset.zero : const Offset(0, -1),
                  child: _TopBar(controller: controller),
                )),

            // ── Bottom overlay ──────────────────────────────────────────────
            Obx(() => AnimatedSlide(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeInOut,
                  offset: controller.overlayVisible.value ? Offset.zero : const Offset(0, 1),
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: _BottomBar(controller: controller),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Single media page (zoomable)
// ─────────────────────────────────────────────────────────────────────────────

class _MediaPage extends StatefulWidget {
  final GalleryMedia media;
  final MediaViewerController controller;

  const _MediaPage({
    super.key,
    required this.media,
    required this.controller,
  });

  @override
  State<_MediaPage> createState() => _MediaPageState();
}

class _MediaPageState extends State<_MediaPage> {
  late final TransformationController _transformController;

  @override
  void initState() {
    super.initState();
    _transformController = TransformationController();
    _transformController.addListener(() {
      final scale = _transformController.value.getMaxScaleOnAxis();
      widget.controller.isZoomed.value = scale > 1.05;
    });
  }

  @override
  void dispose() {
    // Reset zoom state when this page is disposed (swiped away)
    widget.controller.isZoomed.value = false;
    _transformController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: widget.controller.loadMedia(widget.media),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white54),
          );
        }
        return Hero(
          tag: 'media_${widget.media.id}',
          child: InteractiveViewer(
            transformationController: _transformController,
            minScale: 0.8,
            maxScale: 5.0,
            panEnabled: true,
            child: Center(
              child: Image.memory(
                snapshot.data!,
                fit: BoxFit.contain,
                gaplessPlayback: true,
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Top bar
// ─────────────────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final MediaViewerController controller;
  const _TopBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black87, Colors.transparent],
        ),
      ),
      padding: EdgeInsets.only(
        top: (MediaQuery.of(context).padding.top + 8).w,
        left: 8.w,
        right: 8.w,
        bottom: 24.w,
      ),
      child: Obx(() => Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                onPressed: Get.back,
              ),
              const Spacer(),
              Text(
                '${controller.currentIndex.value + 1} / ${controller.mediaList.length}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              48.horizontalSpace,
            ],
          )),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom bar
// ─────────────────────────────────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  final MediaViewerController controller;
  const _BottomBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.black87, Colors.transparent],
        ),
      ),
      padding: EdgeInsets.only(
        bottom: (MediaQuery.of(context).padding.bottom + 16).w,
        left: 24.w,
        right: 24.w,
        top: 32.w,
      ),
      child: Obx(() {
        final media = controller.current;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    media.originalName ?? 'Unknown',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  4.verticalSpace,
                  Obx(() => controller.isEditingTag.value
                      ? SizedBox(
                          height: 28.w,
                          child: TextField(
                            controller: controller.tagTextController,
                            autofocus: true,
                            onSubmitted: (_) => controller.saveTag(),
                            onTapOutside: (_) => controller.saveTag(),
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.w),
                              filled: true,
                              fillColor: Colors.white12,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                                borderSide: BorderSide.none,
                              ),
                              suffixIcon: GestureDetector(
                                onTap: controller.saveTag,
                                child: Icon(Icons.check_rounded, color: Colors.white70, size: 16.w),
                              ),
                            ),
                          ),
                        )
                      : GestureDetector(
                          onTap: controller.startEditingTag,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.label_outline_rounded, color: Colors.white54, size: 12.w),
                              4.horizontalSpace,
                              Text(
                                media.tag ?? 'default',
                                style: const TextStyle(color: Colors.white54, fontSize: 12),
                              ),
                              4.horizontalSpace,
                              Icon(Icons.edit_outlined, color: Colors.white38, size: 11.w),
                            ],
                          ),
                        )),
                  2.verticalSpace,
                  Text(
                    _formatDate(media.importedAt),
                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                ],
              ),
            ),
            16.horizontalSpace,
            IconButton(
              onPressed: controller.shareCurrentMedia,
              icon: Icon(
                Icons.share_outlined,
                color: Colors.white,
                size: 26.w,
              ),
            ),
            IconButton(
              onPressed: controller.saveCurrentToDownload,
              icon: Icon(
                Icons.download_outlined,
                color: Colors.white,
                size: 26.w,
              ),
            ),
            Obx(() => controller.isDeleting.value
                ? SizedBox(
                    width: 44.w,
                    height: 44.w,
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    onPressed: () => _confirmDelete(context),
                    icon: Icon(Icons.delete_outline_rounded, color: Colors.white, size: 26.w),
                  )),
          ],
        );
      }),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete media'),
        content: const Text('This will permanently delete this file. Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              controller.deleteCurrentMedia();
            },
            child: Text('Delete', style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '';
    return '${dt.day}/${dt.month}/${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
