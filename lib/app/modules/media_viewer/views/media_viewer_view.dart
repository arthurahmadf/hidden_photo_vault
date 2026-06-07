import 'dart:typed_data';

import 'package:flutter/material.dart';
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
              offset: controller.overlayVisible.value
                  ? Offset.zero
                  : const Offset(0, -1),
              child: _TopBar(controller: controller),
            )),
 
            // ── Bottom overlay ──────────────────────────────────────────────
            Obx(() => AnimatedSlide(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              offset: controller.overlayVisible.value
                  ? Offset.zero
                  : const Offset(0, 1),
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
 
class _MediaPage extends StatelessWidget {
  final GalleryMedia media;
  final MediaViewerController controller;
 
  const _MediaPage({
    super.key,
    required this.media,
    required this.controller,
  });
 
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: controller.loadMedia(media),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white54),
          );
        }
        return Hero(
          tag: 'media_${media.id}',
          child: InteractiveViewer(
            minScale: 0.8,
            maxScale: 5.0,
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
        top: MediaQuery.of(context).padding.top + 8,
        left: 8,
        right: 8,
        bottom: 24,
      ),
      child: Obx(() => Row(
        children: [
          // Back
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
            onPressed: Get.back,
          ),
 
          const Spacer(),
 
          // Counter
          Text(
            '${controller.currentIndex.value + 1} / ${controller.mediaList.length}',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
 
          const Spacer(),
 
          // Placeholder to balance the back button width
          const SizedBox(width: 48),
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
        bottom: MediaQuery.of(context).padding.bottom + 16,
        left: 24,
        right: 24,
        top: 32,
      ),
      child: Obx(() {
        final media = controller.current;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // File info
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
                  const SizedBox(height: 2),
                  Text(
                    _formatDate(media.importedAt),
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
 
            const SizedBox(width: 16),
 
            // Delete button
            Obx(() => controller.isDeleting.value
                ? const SizedBox(
                    width: 44,
                    height: 44,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                  )
                : IconButton(
                    onPressed: () => _confirmDelete(context),
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
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
            child: Text(
              'Delete',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
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
 