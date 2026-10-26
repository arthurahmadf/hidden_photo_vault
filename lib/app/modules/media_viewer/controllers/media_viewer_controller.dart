import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hidden_photo_vault/app/data/models/gallery_media_model.dart';
import 'package:hidden_photo_vault/app/data/services/gallery_service.dart';
import 'package:hidden_photo_vault/app/modules/home/controllers/home_controller.dart';
import 'package:hidden_photo_vault/app/modules/media_viewer/arguments/view_media_argument.dart';
import 'package:hidden_photo_vault/app/core/services/sensitive_cache_service.dart';
import 'package:path/path.dart' as p;
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
  late final List<String> _mediaIds;

  static const _maxCachedBytes = 64 * 1024 * 1024;
  static const _maxCachedPhotos = 4;
  // The insertion order is the least recently used order.
  final _cache = <String, Uint8List>{};
  final _inFlight = <String, Future<Uint8List>>{};
  final _decoding = <String, Future<void>>{};
  int _cachedBytes = 0;
  int _cacheGeneration = 0;
  bool _initialWarmStarted = false;
  final _videoFiles = <String, Future<File>>{};
  final _playbackSessionName =
      'session_${DateTime.now().microsecondsSinceEpoch}';

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as ViewMediaArgument;
    _mediaIds = List<String>.of(args.mediaIds);
    final initialMediaId = _mediaIds[args.initialIndex];
    final resolvedInitialIndex =
        mediaList.indexWhere((media) => media.id == initialMediaId);
    currentIndex.value = resolvedInitialIndex < 0 ? 0 : resolvedInitialIndex;
    pageController = PageController(initialPage: currentIndex.value);
    tagTextController = TextEditingController();
    unawaited(_removeStalePlaybackFiles());

    // Hide status bar for immersive view
    // SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void onClose() {
    clearSensitiveCache();
    pageController.dispose();
    tagTextController.dispose();
    unawaited(_deletePlaybackSession());
    // Restore system UI on exit
    // SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.onClose();
  }

  void clearSensitiveCache() {
    _cacheGeneration++;
    _cache.clear();
    _cachedBytes = 0;
    _inFlight.clear();
    _decoding.clear();
    PaintingBinding.instance.imageCache
      ..clear()
      ..clearLiveImages();
    unawaited(_deletePlaybackSession());
    unawaited(
      SensitiveCacheService.clearPlaintextTemporaryFiles(
        includeActiveShares: !home.isBusy,
      ),
    );
  }

  // ── Data helpers ─────────────────────────────────────────────────────────

  List<GalleryMedia> get mediaList {
    final mediaById = <String, GalleryMedia>{
      for (final media in home.images)
        if (media.id != null) media.id!: media,
    };
    return _mediaIds
        .map((id) => mediaById[id])
        .whereType<GalleryMedia>()
        .toList(growable: false);
  }

  GalleryMedia get current => mediaList[currentIndex.value];

  String get _encKey => home.selectedVaultPin ?? GalleryService.publicKey;

  ImageProvider previewProvider(Uint8List bytes, BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final ratio = MediaQuery.devicePixelRatioOf(context);
    return ResizeImage(
      MemoryImage(bytes),
      width: (size.width * ratio).ceil().clamp(1, 8192),
      height: (size.height * ratio).ceil().clamp(1, 8192),
      policy: ResizeImagePolicy.fit,
    );
  }

  void warmInitial(BuildContext context) {
    if (_initialWarmStarted) return;
    _initialWarmStarted = true;
    unawaited(_preloadAround(currentIndex.value, context, 1));
  }

  Future<Uint8List> loadMedia(GalleryMedia media) {
    final id = media.id!;
    final cached = _cache.remove(id);
    if (cached != null) {
      _cache[id] = cached;
      return Future.value(cached);
    }
    final pending = _inFlight[id];
    if (pending != null) return pending;

    final generation = _cacheGeneration;
    late final Future<Uint8List> request;
    request = home.gs.loadFull(media, encryptionKey: _encKey).then((bytes) {
      if (isClosed || generation != _cacheGeneration) {
        throw StateError('Viewer session has ended');
      }
      if (bytes.lengthInBytes <= _maxCachedBytes) {
        _cache[id] = bytes;
        _cachedBytes += bytes.lengthInBytes;
        while (_cache.length > _maxCachedPhotos ||
            _cachedBytes > _maxCachedBytes) {
          final oldest = _cache.keys.first;
          _cachedBytes -= _cache.remove(oldest)!.lengthInBytes;
        }
      }
      return bytes;
    }).whenComplete(() {
      if (identical(_inFlight[id], request)) _inFlight.remove(id);
    });
    _inFlight[id] = request;
    return request;
  }

  Future<String> prepareVideo(GalleryMedia media) async {
    final id = media.id!;
    final fileFuture = _videoFiles.putIfAbsent(id, () async {
      final bytes = await home.gs.loadFull(media, encryptionKey: _encKey);
      final base = await getTemporaryDirectory();
      final sessionDir = Directory(
        p.join(base.path, 'hidden_photo_vault_playback', _playbackSessionName),
      );
      await sessionDir.create(recursive: true);

      var extension = p.extension(media.originalName ?? '').toLowerCase();
      if (extension.isEmpty || extension.length > 8) extension = '.mp4';
      final output = File(p.join(sessionDir.path, '$id$extension'));
      await output.writeAsBytes(bytes, flush: true);
      return output;
    });
    return (await fileFuture).path;
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
    final newTag = tagTextController.text.trim().isEmpty
        ? 'default'
        : tagTextController.text.trim();
    if (newTag == (current.tag ?? 'default')) return; // no change
    await home.gs.updateTag(current, newTag);
    await home.refreshImages();
  }

  void onPageChanged(int index, BuildContext context) {
    final direction = index >= currentIndex.value ? 1 : -1;
    currentIndex.value = index;
    unawaited(_preloadAround(index, context, direction));
  }

  Future<void> _preloadAround(
      int index, BuildContext context, int direction) async {
    final items = mediaList;
    if (index < 0 || index >= items.length) return;
    // Start the visible page first, then warm both sides and one page ahead.
    await Future.wait([
      _preload(index, context),
      _preload(index + direction, context),
      _preload(index - direction, context),
      _preload(index + direction * 2, context),
    ]);
  }

  Future<void> _preload(int index, BuildContext context) async {
    final items = mediaList;
    if (index < 0 || index >= items.length || isClosed || !context.mounted) {
      return;
    }
    final media = items[index];
    if (media.isVideo) return;
    try {
      final bytes = await loadMedia(media);
      if (isClosed || !context.mounted) return;
      final provider = previewProvider(bytes, context);
      final id = media.id!;
      final generation = _cacheGeneration;
      final existing = _decoding[id];
      if (existing != null) return existing;
      late final Future<void> decoding;
      decoding = precacheImage(provider, context).whenComplete(() async {
        if (isClosed || generation != _cacheGeneration) {
          await provider.evict();
        }
        if (identical(_decoding[id], decoding)) _decoding.remove(id);
      });
      _decoding[id] = decoding;
      await decoding;
    } catch (_) {
      // Prefetch failures are handled when the user opens that page.
    }
  }

  Future<void> deleteCurrentMedia() async {
    if (isDeleting.value) return;
    isDeleting.value = true;

    final indexToDelete = currentIndex.value;
    final mediaToDelete = mediaList[indexToDelete];

    final success = await home.gs.moveToTrash(mediaToDelete);
    if (!success) {
      isDeleting.value = false;
      Get.snackbar('Error', 'Failed to move media to Trash.');
      return;
    }

    // Remove from cache
    final cached = _cache.remove(mediaToDelete.id);
    if (cached != null) _cachedBytes -= cached.lengthInBytes;
    await _deletePreparedVideo(mediaToDelete.id);

    // Notify HomeController to refresh its list
    await home.refreshImages();

    // If list is now empty, go back
    if (mediaList.isEmpty) {
      isDeleting.value = false;
      Get.back();
      _showTrashUndo(mediaToDelete);
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

    _showTrashUndo(mediaToDelete);
  }

  void _showTrashUndo(GalleryMedia media) {
    Get.snackbar(
      'Moved to Trash',
      'This item will be deleted permanently after 7 days.',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 5),
      mainButton: TextButton(
        onPressed: () async {
          await home.gs.restoreFromTrash(media);
          await home.refreshImages();
          Get.closeCurrentSnackbar();
        },
        child: const Text('UNDO'),
      ),
    );
  }

  Future<void> shareCurrentMedia() async {
    try {
      final media = current;
      final plainBytes = await home.gs.loadFull(media, encryptionKey: _encKey);

      // write to temp cache, share, cleanup after
      final cacheDir = await getTemporaryDirectory();
      final shareDir =
          Directory(p.join(cacheDir.path, 'hidden_photo_vault_share'));
      await shareDir.create(recursive: true);
      final fileName = p.windows
          .basename(p.posix.basename(media.originalName ?? '${media.id}.jpg'));
      final tempFile = File(p.join(shareDir.path, fileName));
      await tempFile.writeAsBytes(plainBytes, flush: true);
      home.isBusy = true;
      await Share.shareXFiles(
        [XFile(tempFile.path, mimeType: media.mimeType ?? 'image/jpeg')],
      );

      if (await tempFile.exists()) await tempFile.delete();
      home.isBusy = false;
    } catch (e) {
      home.isBusy = false;
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

      final fileName = p.basename(media.originalName ?? '${media.id}.jpg');
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

  Future<void> _deletePreparedVideo(String? id) async {
    if (id == null) return;
    final future = _videoFiles.remove(id);
    if (future == null) return;
    try {
      final file = await future;
      if (await file.exists()) await file.delete();
    } catch (_) {
      // A failed preparation has no plaintext file to clean up.
    }
  }

  Future<void> _removeStalePlaybackFiles() async {
    try {
      final base = await getTemporaryDirectory();
      final root = Directory(p.join(base.path, 'hidden_photo_vault_playback'));
      if (!await root.exists()) return;
      await for (final entity in root.list()) {
        if (entity is Directory &&
            p.basename(entity.path) != _playbackSessionName) {
          await entity.delete(recursive: true);
        }
      }
    } catch (_) {
      // Cache cleanup must never prevent the viewer from opening.
    }
  }

  Future<void> _deletePlaybackSession() async {
    try {
      final base = await getTemporaryDirectory();
      final session = Directory(
        p.join(base.path, 'hidden_photo_vault_playback', _playbackSessionName),
      );
      if (await session.exists()) await session.delete(recursive: true);
      _videoFiles.clear();
    } catch (_) {
      // The next viewer session also removes stale playback directories.
    }
  }
}
