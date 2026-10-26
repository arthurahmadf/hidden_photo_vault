// gallery_service.dart
//
// Dependencies:
//   flutter_image_compress: ^2.3.0
//   encrypt: ^5.0.3
//   path_provider: ^2.1.4
//   path: ^1.9.0
//   uuid: ^4.5.1

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:cryptography_flutter/cryptography_flutter.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:hidden_photo_vault/app/data/models/gallery_media_model.dart';
import 'package:media_kit/media_kit.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/services/data_service.dart';
import '../../core/services/media_picker_service.dart';
import 'vault_crypto.dart';

class GalleryService {
  static const _uuid = Uuid();
  static const _vaultDir = 'vault';
  static const _encExt = '.enc';
  static const _thumbSuffix = '_thumb';
  static const _thumbSize = 350;
  static const publicKey =
      'public'; // public vault identifier, never an AES key

  // ── Public API ──────────────────────────────────────────────────────────────

  /// Encrypt and store [file] under [vaultId].
  /// The vault must be unlocked before inserting private media.
  /// Returns true on success.
  Future<bool> insertMedia(
    XFile file,
    MediaType mediaType,
    String vaultId, {
    String tag = "default",
  }) async {
    File? fullFile;
    File? thumbFile;
    try {
      final id = _uuid.v4();
      final dir = await _vaultDirectory();
      final sourceBytes = await file.readAsBytes();
      final resolvedType = resolveMediaType(
        file.path,
        mimeType: file.mimeType,
        headerBytes: sourceBytes.take(64).toList(),
      );
      final effectiveType =
          mediaType == MediaType.any ? resolvedType : mediaType;
      final mimeType = resolveMediaMimeType(
        file.path,
        mediaType: effectiveType,
        suppliedMimeType: file.mimeType,
        headerBytes: sourceBytes.take(64).toList(),
      );

      _VideoInfo? videoInfo;
      Uint8List thumbBytes;
      if (effectiveType == MediaType.video) {
        videoInfo = await _inspectVideo(file.path);
        thumbBytes = videoInfo?.thumbnail == null
            ? _videoThumbPlaceholder()
            : await _generateThumb(videoInfo!.thumbnail!);
      } else {
        thumbBytes = await _generateThumb(sourceBytes);
      }

      // Encrypt both
      final key = await _keyFor(vaultId);
      final encFull = await VaultCrypto.encrypt(sourceBytes, key,
          context: 'media:$id:full');
      final encThumb = await VaultCrypto.encrypt(thumbBytes, key,
          context: 'media:$id:thumb');

      // Write to disk
      final fullPath = p.join(dir.path, '$id$_encExt');
      final thumbPath = p.join(dir.path, '$id$_thumbSuffix$_encExt');

      fullFile = File(fullPath);
      thumbFile = File(thumbPath);
      await fullFile.writeAsBytes(encFull, flush: true);
      await thumbFile.writeAsBytes(encThumb, flush: true);

      // Persist metadata to Hive
      final image = GalleryMedia(
        id: id,
        filePath: fullPath,
        thumbPath: thumbPath,
        originalName: p.basename(file.path),
        mimeType: mimeType,
        fileSize: sourceBytes.length,
        importedAt: DateTime.now(),
        vaultId: vaultId,
        tag: tag,
        durationMs: videoInfo?.duration.inMilliseconds,
        width: videoInfo?.width,
        height: videoInfo?.height,
      );

      await DataService.gallery.put(id, image);
      return true;
    } catch (_) {
      if (fullFile != null && await fullFile.exists()) await fullFile.delete();
      if (thumbFile != null && await thumbFile.exists()) {
        await thumbFile.delete();
      }
      return false;
    }
  }

  /// Delete [image] — removes both .enc files from disk and Hive record.
  Future<bool> deleteMedia(GalleryMedia image) async {
    try {
      // Delete full file
      if (image.filePath != null) {
        final full = File(image.filePath!);
        if (await full.exists()) await full.delete();
      }

      // Delete thumb file
      if (image.thumbPath != null) {
        final thumb = File(image.thumbPath!);
        if (await thumb.exists()) await thumb.delete();
      }

      // Remove from Hive
      await DataService.gallery.deleteById(image.id!);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Soft-delete media while leaving its files encrypted in place.
  Future<bool> moveToTrash(GalleryMedia media) async {
    try {
      await DataService.gallery.update(
        media.id!,
        media.copyWith(deletedAt: DateTime.now()),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> restoreFromTrash(GalleryMedia media) async {
    try {
      await DataService.gallery
          .update(media.id!, media.copyWith(restore: true));
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<int> purgeExpiredTrash({
    Duration retention = const Duration(days: 7),
  }) async {
    final cutoff = DateTime.now().subtract(retention);
    final expired = DataService.gallery.where(
      (item) => item.deletedAt != null && item.deletedAt!.isBefore(cutoff),
    );
    var count = 0;
    for (final item in expired) {
      if (await deleteMedia(item)) count++;
    }
    return count;
  }

  Future<bool> updateTag(GalleryMedia media, String tag) async {
    final updated =
        media.copyWith(tag: tag.trim().isEmpty ? 'default' : tag.trim());
    await DataService.gallery.update(media.id!, updated);
    return true;
  }

  /// Return all images belonging to [vaultId], sorted newest first.
  Future<List<GalleryMedia>> getImages(String vaultId) async {
    final list = DataService.gallery.where(
      (img) => img.vaultId == vaultId && img.deletedAt == null,
    );

    list.sort((a, b) =>
        (b.importedAt ?? DateTime(0)).compareTo(a.importedAt ?? DateTime(0)));

    return list;
  }

  /// Decrypt and return thumbnail bytes for grid display.
  /// Pass [encryptionKey] matching the one used at insert time.
  Future<Uint8List> loadThumb(GalleryMedia media,
      {String encryptionKey = publicKey}) async {
    final encBytes = await File(media.thumbPath!).readAsBytes();
    return _decryptMedia(encBytes, media.thumbPath!, media.vaultId!, media.id!,
        'thumb', encryptionKey);
  }

  /// Decrypt and return full image bytes for the viewer.
  /// Pass [encryptionKey] matching the one used at insert time.
  Future<Uint8List> loadFull(GalleryMedia media,
      {String encryptionKey = publicKey}) async {
    final encBytes = await File(media.filePath!).readAsBytes();
    return _decryptMedia(encBytes, media.filePath!, media.vaultId!, media.id!,
        'full', encryptionKey);
  }

  // ── Private ─────────────────────────────────────────────────────────────────

  /// Compress [sourceBytes] to a [_thumbSize]x[_thumbSize] jpeg.
  Future<Uint8List> _generateThumb(Uint8List sourceBytes) async {
    return await FlutterImageCompress.compressWithList(
      sourceBytes,
      minWidth: _thumbSize,
      minHeight: _thumbSize,
      quality: 90,
      format: CompressFormat.jpeg,
    );
  }

  Future<Uint8List> _keyFor(String vaultId) async {
    if (vaultId == 'public') return VaultCrypto.publicKey();
    final key = VaultCrypto.unlockedKey(vaultId);
    if (key == null) throw StateError('Vault is locked');
    return key;
  }

  Future<Uint8List> _decryptMedia(Uint8List bytes, String path, String vaultId,
      String mediaId, String kind, String pin) async {
    final context = 'media:$mediaId:$kind';
    if (VaultCrypto.isModern(bytes)) {
      final key = await _keyFor(vaultId);
      if (kind != 'full') {
        return VaultCrypto.decrypt(bytes, key, context: context);
      }
      if (FlutterCryptography.isPluginPresent &&
          (Platform.isAndroid || Platform.isIOS || Platform.isMacOS)) {
        return VaultCrypto.decrypt(bytes, key, context: context);
      }
      // Full photos and videos can take long enough to stall a swipe when
      // native AES-GCM is unavailable, so use a worker isolate as a fallback.
      final workerKey = Uint8List.fromList(key);
      try {
        return await compute(
          _decryptFullMedia,
          _FullMediaDecryptRequest(bytes, workerKey, context),
        );
      } finally {
        workerKey.fillRange(0, workerKey.length, 0);
      }
    }
    final clear = VaultCrypto.decryptLegacy(bytes, pin);
    // Upgrade legacy ciphertext only after decryption succeeds. A failed rewrite
    // leaves the old file intact so it can be retried on the next unlock.
    try {
      final key = await _keyFor(vaultId);
      final upgraded = await VaultCrypto.encrypt(clear, key, context: context);
      final temporary = File('$path.migrating');
      await temporary.writeAsBytes(upgraded, flush: true);
      await temporary.rename(path);
    } catch (_) {
      // Reading remains possible if storage is temporarily unwritable.
    }
    return clear;
  }

  /// 1x1 transparent PNG — placeholder for video thumbnails.
  Uint8List _videoThumbPlaceholder() {
    return Uint8List.fromList([
      0x89,
      0x50,
      0x4E,
      0x47,
      0x0D,
      0x0A,
      0x1A,
      0x0A,
      0x00,
      0x00,
      0x00,
      0x0D,
      0x49,
      0x48,
      0x44,
      0x52,
      0x00,
      0x00,
      0x00,
      0x01,
      0x00,
      0x00,
      0x00,
      0x01,
      0x08,
      0x06,
      0x00,
      0x00,
      0x00,
      0x1F,
      0x15,
      0xC4,
      0x89,
      0x00,
      0x00,
      0x00,
      0x0A,
      0x49,
      0x44,
      0x41,
      0x54,
      0x78,
      0x9C,
      0x62,
      0x00,
      0x01,
      0x00,
      0x00,
      0x05,
      0x00,
      0x01,
      0x0D,
      0x0A,
      0x2D,
      0xB4,
      0x00,
      0x00,
      0x00,
      0x00,
      0x49,
      0x45,
      0x4E,
      0x44,
      0xAE,
      0x42,
      0x60,
      0x82,
    ]);
  }

  Future<Directory> _vaultDirectory() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(base.path, _vaultDir));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<_VideoInfo?> _inspectVideo(String path) async {
    final player = Player();
    try {
      await player.open(Media(path), play: false);

      var duration = player.state.duration;
      if (duration == Duration.zero) {
        try {
          duration = await player.stream.duration
              .firstWhere((value) => value > Duration.zero)
              .timeout(const Duration(seconds: 8));
        } catch (_) {
          duration = player.state.duration;
        }
      }

      if (duration > Duration.zero) {
        final previewAt = Duration(
          milliseconds: duration.inMilliseconds.clamp(250, 1000).toInt(),
        );
        await player.seek(previewAt);
      }

      Uint8List? thumbnail;
      try {
        thumbnail = await player.screenshot(format: 'image/jpeg');
      } catch (_) {
        // Some valid codecs do not expose a video frame during import. Playback
        // remains available and the grid will use its video placeholder.
      }

      final width = player.state.width;
      final height = player.state.height;
      return _VideoInfo(
        duration: duration,
        width: width == 0 ? null : width,
        height: height == 0 ? null : height,
        thumbnail: thumbnail,
      );
    } catch (_) {
      return null;
    } finally {
      await player.dispose();
    }
  }
}

class _FullMediaDecryptRequest {
  final Uint8List bytes;
  final Uint8List key;
  final String context;

  _FullMediaDecryptRequest(this.bytes, this.key, this.context);
}

Future<Uint8List> _decryptFullMedia(_FullMediaDecryptRequest request) async {
  try {
    return await VaultCrypto.decrypt(request.bytes, request.key,
        context: request.context);
  } finally {
    request.key.fillRange(0, request.key.length, 0);
  }
}

class _VideoInfo {
  const _VideoInfo({
    required this.duration,
    required this.width,
    required this.height,
    required this.thumbnail,
  });

  final Duration duration;
  final int? width;
  final int? height;
  final Uint8List? thumbnail;
}
