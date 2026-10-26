import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:hidden_photo_vault/app/core/widgets/dark_video_player.dart';
import 'package:hidden_photo_vault/app/data/models/gallery_media_model.dart';
import 'package:hidden_photo_vault/app/modules/media_viewer/controllers/media_viewer_controller.dart';

class MediaViewerView extends GetView<MediaViewerController> {
  const MediaViewerView({super.key});

  @override
  Widget build(BuildContext context) {
    controller.warmInitial(context);
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: controller.toggleOverlay,
        behavior: HitTestBehavior.opaque,
        child: Stack(
          children: [
            // ── Media PageView ──────────────────────────────────────────────
            Obx(() {
              final immersionMode = !controller.overlayVisible.value;
              final items = controller.mediaList;
              return IgnorePointer(
                ignoring: immersionMode,
                child: PageView.builder(
                  controller: controller.pageController,
                  // Freeze the PageView when zoomed or in immersion mode.
                  physics: (controller.isZoomed.value || immersionMode)
                      ? const NeverScrollableScrollPhysics()
                      : const PageScrollPhysics(),
                  itemCount: items.length,
                  onPageChanged: (index) =>
                      controller.onPageChanged(index, context),
                  itemBuilder: (context, index) {
                    final media = items[index];
                    return _MediaPage(
                      key: ValueKey(media.id),
                      media: media,
                      index: index,
                      controller: controller,
                    );
                  },
                ),
              );
            }),

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

class _MediaPage extends StatefulWidget {
  final GalleryMedia media;
  final int index;
  final MediaViewerController controller;

  const _MediaPage({
    super.key,
    required this.media,
    required this.index,
    required this.controller,
  });

  @override
  State<_MediaPage> createState() => _MediaPageState();
}

class _MediaPageState extends State<_MediaPage>
    with SingleTickerProviderStateMixin {
  static const double _doubleTapScale = 2.5;
  static const Duration _doubleTapZoomDuration = Duration(milliseconds: 220);

  late final TransformationController _transformController;
  late final AnimationController _zoomAnimationController;
  Animation<Matrix4>? _zoomAnimation;
  Offset _doubleTapPosition = Offset.zero;
  bool _useFullResolution = false;
  late Future<Uint8List> _imageFuture;
  late Future<String> _videoFuture;

  void _startLoading() {
    if (widget.media.isVideo) {
      _videoFuture = widget.controller.prepareVideo(widget.media);
    } else {
      _imageFuture = widget.controller.loadMedia(widget.media);
    }
  }

  @override
  void initState() {
    super.initState();
    _startLoading();
    _transformController = TransformationController();
    _transformController.addListener(() {
      final scale = _transformController.value.getMaxScaleOnAxis();
      final zoomed = scale > 1.05;
      widget.controller.isZoomed.value = zoomed;
      if (zoomed != _useFullResolution) {
        setState(() => _useFullResolution = zoomed);
      }
    });
    _zoomAnimationController = AnimationController(
      vsync: this,
      duration: _doubleTapZoomDuration,
    )..addListener(() {
        final animation = _zoomAnimation;
        if (animation != null) {
          _transformController.value = animation.value;
        }
      });
  }

  @override
  void didUpdateWidget(covariant _MediaPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.media.id != widget.media.id) _startLoading();
  }

  @override
  void dispose() {
    // Reset zoom state when this page is disposed (swiped away)
    widget.controller.isZoomed.value = false;
    _zoomAnimationController.dispose();
    _transformController.dispose();
    super.dispose();
  }

  void _handleDoubleTapDown(TapDownDetails details) {
    _doubleTapPosition = details.localPosition;
  }

  void _handleDoubleTap() {
    final currentScale = _transformController.value.getMaxScaleOnAxis();
    final target = currentScale > 1.05
        ? Matrix4.identity()
        : (Matrix4.identity()
          ..setEntry(0, 0, _doubleTapScale)
          ..setEntry(1, 1, _doubleTapScale)
          ..setEntry(2, 2, _doubleTapScale)
          ..setEntry(
            0,
            3,
            -_doubleTapPosition.dx * (_doubleTapScale - 1),
          )
          ..setEntry(
            1,
            3,
            -_doubleTapPosition.dy * (_doubleTapScale - 1),
          ));

    _zoomAnimationController.stop();
    _zoomAnimation = Matrix4Tween(
      begin: Matrix4.copy(_transformController.value),
      end: target,
    ).animate(
      CurvedAnimation(
        parent: _zoomAnimationController,
        curve: Curves.easeOutCubic,
      ),
    );
    _zoomAnimationController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.media.isVideo) {
      return FutureBuilder<String>(
        future: _videoFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'This video could not be opened.',
                style: TextStyle(color: Colors.white70),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white54),
            );
          }
          return Obx(
            () => DarkVideoPlayer(
              sourcePath: snapshot.data!,
              active: widget.controller.currentIndex.value == widget.index,
              autoplay: widget.controller.currentIndex.value == widget.index,
              fit: BoxFit.contain,
              controlsBottomInset: widget.controller.overlayVisible.value
                  ? MediaQuery.of(context).padding.bottom + 112.w
                  : MediaQuery.of(context).padding.bottom + 8.w,
            ),
          );
        },
      );
    }

    return FutureBuilder<Uint8List>(
      future: _imageFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Text('This photo could not be opened.',
                style: TextStyle(color: Colors.white70)),
          );
        }
        if (!snapshot.hasData) {
          final thumb = widget.controller.home.thumbCache[widget.media.id];
          return Stack(
            fit: StackFit.expand,
            children: [
              if (thumb != null) Image.memory(thumb, fit: BoxFit.contain),
              const Center(
                child: CircularProgressIndicator(color: Colors.white54),
              ),
            ],
          );
        }
        return Hero(
          tag: 'media_${widget.media.id}',
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onDoubleTapDown: _handleDoubleTapDown,
            onDoubleTap: _handleDoubleTap,
            child: InteractiveViewer(
              transformationController: _transformController,
              minScale: 0.8,
              maxScale: 5.0,
              panEnabled: true,
              onInteractionStart: (_) => _zoomAnimationController.stop(),
              child: Center(
                child: Image(
                  image: _useFullResolution
                      ? MemoryImage(snapshot.data!)
                      : widget.controller
                          .previewProvider(snapshot.data!, context),
                  fit: BoxFit.contain,
                  gaplessPlayback: true,
                ),
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
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white),
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
                            style: const TextStyle(
                                color: Colors.white, fontSize: 12),
                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 8.w, vertical: 4.w),
                              filled: true,
                              fillColor: Colors.white12,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                                borderSide: BorderSide.none,
                              ),
                              suffixIcon: GestureDetector(
                                onTap: controller.saveTag,
                                child: Icon(Icons.check_rounded,
                                    color: Colors.white70, size: 16.w),
                              ),
                            ),
                          ),
                        )
                      : GestureDetector(
                          onTap: controller.startEditingTag,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.label_outline_rounded,
                                  color: Colors.white54, size: 12.w),
                              4.horizontalSpace,
                              Text(
                                media.tag ?? 'default',
                                style: const TextStyle(
                                    color: Colors.white54, fontSize: 12),
                              ),
                              4.horizontalSpace,
                              Icon(Icons.edit_outlined,
                                  color: Colors.white38, size: 11.w),
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
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    onPressed: () => _confirmDelete(context),
                    icon: Icon(Icons.delete_outline_rounded,
                        color: Colors.white, size: 26.w),
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
        title: const Text('Move to Trash?'),
        content: const Text(
          'The encrypted file can be restored for 7 days before permanent deletion.',
        ),
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
            child: Text('Move to Trash',
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
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
