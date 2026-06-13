import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:hidden_photo_vault/app/data/models/gallery_media_model.dart';
import 'package:hidden_photo_vault/app/data/services/gallery_service.dart';
import 'package:hidden_photo_vault/app/modules/home/controllers/home_controller.dart';
import 'package:hidden_photo_vault/app/modules/media_viewer/arguments/view_media_argument.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class MediaViewerController extends GetxController {
  final HomeController home = Get.find<HomeController>();

  late final PageController pageController;

  final currentIndex = 0.obs;
  final overlayVisible = true.obs;
  final isDeleting = false.obs;
  final isEditingTag = false.obs;
  late final TextEditingController tagTextController;
  final isZoomed = false.obs;
  int preloadValue = 3;

  // Cache: id → decrypted full bytes
  final _cache = <String, Uint8List>{};

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as ViewMediaArgument;
    currentIndex.value = args.initialIndex;
    pageController = PageController(initialPage: args.initialIndex);
    tagTextController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (int i = 1; i <= preloadValue; i++) {
        unawaited(_preload(currentIndex.value - i));
        unawaited(_preload(currentIndex.value + i));
      }
    });

    // Hide status bar for immersive view
    // SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void onClose() {
    pageController.dispose();
    tagTextController.dispose();
    // Restore system UI on exit
    // SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.onClose();
  }

  // ── Data helpers ─────────────────────────────────────────────────────────

  List<GalleryMedia> get mediaList => home.images;
  GalleryMedia get current => mediaList[currentIndex.value];

  String get _encKey => home.selectedVaultPin ?? GalleryService.publicKey;

  Future<Uint8List> loadMedia(GalleryMedia media) async {
    if (_cache.containsKey(media.id)) return _cache[media.id]!;
    final bytes = await home.gs.loadFull(media, encryptionKey: _encKey);
    _cache[media.id!] = bytes;
    return bytes;
  }

  // ── Interactions ──────────────────────────────────────────────────────────

  void toggleOverlay() => overlayVisible.toggle();

  void startEditingTag() {
    tagTextController.text = current.tag ?? 'default';
    tagTextController.selection = TextSelection(
      baseOffset: 0,
      extentOffset: tagTextController.text.length,
    );
    isEditingTag.value = true;
  }

  Future<void> saveTag() async {
    if (!isEditingTag.value) return;
    isEditingTag.value = false;
    final newTag = tagTextController.text.trim().isEmpty ? 'default' : tagTextController.text.trim();
    if (newTag == (current.tag ?? 'default')) return; // no change
    await home.gs.updateTag(current, newTag);
    await home.refreshImages();
  }

  void onPageChanged(int index) {
    currentIndex.value = index;
    // Preload adjacent images
    for (int i = 1; i <= preloadValue; i++) {
      unawaited(_preload(index - i));
      unawaited(_preload(index + i));
    }
  }

  Future<void> _preload(int index) async {
    if (index < 0 || index >= mediaList.length) return;
    final media = mediaList[index];
    if (_cache.containsKey(media.id)) return;
    final bytes = await home.gs.loadFull(media, encryptionKey: _encKey);
    _cache[media.id!] = bytes;
  }

  Future<void> deleteCurrentMedia() async {
    if (isDeleting.value) return;
    isDeleting.value = true;

    final indexToDelete = currentIndex.value;
    final mediaToDelete = mediaList[indexToDelete];

    final success = await home.gs.deleteMedia(mediaToDelete);
    if (!success) {
      isDeleting.value = false;
      Get.snackbar('Error', 'Failed to delete media.');
      return;
    }

    // Remove from cache
    _cache.remove(mediaToDelete.id);

    // Notify HomeController to refresh its list
    await home.refreshImages();

    // If list is now empty, go back
    if (mediaList.isEmpty) {
      isDeleting.value = false;
      Get.back();
      return;
    }

    // Stay on same index (now points to next item), or step back if last
    final newIndex = indexToDelete.clamp(0, mediaList.length - 1);

    if (newIndex == indexToDelete) {
      // Jump PageView to updated position without animation
      pageController.jumpToPage(newIndex);
    }

    currentIndex.value = newIndex;
    isDeleting.value = false;
  }

  Future<void> shareCurrentMedia() async {
    try {
      final media = current;
      final plainBytes = await home.gs.loadFull(media, encryptionKey: _encKey);

      // write to temp cache, share, cleanup after
      final cacheDir = await getTemporaryDirectory();
      final fileName = media.originalName ?? '${media.id}.jpg';
      final tempFile = File('${cacheDir.path}/$fileName');
      await tempFile.writeAsBytes(plainBytes, flush: true);
      home.isBusy = true;
      await Share.shareXFiles(
        [XFile(tempFile.path, mimeType: media.mimeType ?? 'image/jpeg')],
      );

      // cleanup after share sheet closes
      Future.delayed(const Duration(seconds: 30), () async {
        if (await tempFile.exists()) await tempFile.delete();
      });
    } catch (e) {
      Get.snackbar(
        'Error',
        'Could not share file.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> saveCurrentToDownload() async {
    try {
      final media = current;
      final plainBytes = await home.gs.loadFull(media, encryptionKey: _encKey);

      const downloadsPath = '/storage/emulated/0/Download';
      final dir = Directory(downloadsPath);
      if (!await dir.exists()) await dir.create(recursive: true);

      final fileName = media.originalName ?? '${media.id}.jpg';
      final dest = File('$downloadsPath/$fileName');
      await dest.writeAsBytes(plainBytes, flush: true);

      Get.snackbar(
        'Saved',
        '$fileName saved to Downloads.',
        backgroundColor: Colors.white,
        colorText: Colors.black,
        snackPosition: SnackPosition.TOP,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Could not save file.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    }
  }
}
