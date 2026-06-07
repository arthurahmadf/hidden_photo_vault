import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:hidden_photo_vault/app/data/models/gallery_media_model.dart';
import 'package:hidden_photo_vault/app/data/services/gallery_service.dart';
import 'package:hidden_photo_vault/app/modules/home/controllers/home_controller.dart';
import 'package:hidden_photo_vault/app/modules/media_viewer/arguments/view_media_argument.dart';

class MediaViewerController extends GetxController {
  final HomeController home = Get.find<HomeController>();

  late final PageController pageController;

  final currentIndex = 0.obs;
  final overlayVisible = true.obs;
  final isDeleting = false.obs;

  // Cache: id → decrypted full bytes
  final _cache = <String, Uint8List>{};

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as ViewMediaArgument;
    currentIndex.value = args.initialIndex;
    pageController = PageController(initialPage: args.initialIndex);

    // Hide status bar for immersive view
    // SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void onClose() {
    pageController.dispose();
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

  void onPageChanged(int index) {
    currentIndex.value = index;
    // Preload adjacent images
    _preload(index - 1);
    _preload(index + 1);
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
}
