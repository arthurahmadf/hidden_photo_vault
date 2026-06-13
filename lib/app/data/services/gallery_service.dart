// gallery_service.dart
//
// Dependencies:
//   flutter_image_compress: ^2.3.0
//   encrypt: ^5.0.3
//   path_provider: ^2.1.4
//   path: ^1.9.0
//   uuid: ^4.5.1

import 'dart:io';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart' as aes;
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:hidden_photo_vault/app/data/models/gallery_media_model.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/services/data_service.dart';
import '../../core/services/media_picker_service.dart';

class _DecryptParams {
  final Uint8List bytes;
  final String key;
  const _DecryptParams(this.bytes, this.key);
}

Uint8List _decryptIsolate(_DecryptParams params) {
  // same AES-CBC logic as _decrypt
  final aesKey = aes.Key.fromUtf8(_padKey(params.key));
  final iv = aes.IV(params.bytes.sublist(0, 16));
  final ciphertext = aes.Encrypted(params.bytes.sublist(16));
  final encrypter = aes.Encrypter(aes.AES(aesKey, mode: aes.AESMode.cbc));
  return Uint8List.fromList(encrypter.decryptBytes(ciphertext, iv: iv));
}

String _padKey(String key) {
  if (key.length >= 32) return key.substring(0, 32);
  return key.padRight(32, '0');
}

class GalleryService {
  static const _uuid = Uuid();
  static const _vaultDir = 'vault';
  static const _encExt = '.enc';
  static const _thumbSuffix = '_thumb';
  static const _thumbSize = 350;
  static const publicKey = 'public'; // hardcoded key for public vault

  // ── Public API ──────────────────────────────────────────────────────────────

  /// Encrypt and store [file] under [vaultId].
  /// Use [publicKey] for home images, vault PIN for secret vault images.
  /// Returns true on success.
  Future<bool> insertMedia(
    XFile file,
    MediaType mediaType,
    String vaultId, {
    String encryptionKey = publicKey,
    String tag = "default",
  }) async {
    try {
      final id = _uuid.v4();
      final dir = await _vaultDirectory();
      final sourceBytes = await file.readAsBytes();

      // Generate thumbnail (images only)
      final thumbBytes =
          mediaType == MediaType.image ? await _generateThumb(sourceBytes) : _videoThumbPlaceholder();

      // Encrypt both
      final encFull = _encrypt(sourceBytes, encryptionKey);
      final encThumb = _encrypt(thumbBytes, encryptionKey);

      // Write to disk
      final fullPath = p.join(dir.path, '$id$_encExt');
      final thumbPath = p.join(dir.path, '$id$_thumbSuffix$_encExt');

      await File(fullPath).writeAsBytes(encFull, flush: true);
      await File(thumbPath).writeAsBytes(encThumb, flush: true);

      // Persist metadata to Hive
      final image = GalleryMedia(
        id: id,
        filePath: fullPath,
        thumbPath: thumbPath,
        originalName: p.basename(file.path),
        mimeType: _resolveMime(mediaType, file.path),
        fileSize: sourceBytes.length,
        importedAt: DateTime.now(),
        vaultId: vaultId,
        tag: tag,
      );

      await DataService.gallery.put(id, image);
      return true;
    } catch (_) {
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

  Future<bool> updateTag(GalleryMedia media, String tag) async {
    final updated = media.copyWith(tag: tag.trim().isEmpty ? 'default' : tag.trim());
    await DataService.gallery.update(media.id!, updated);
    return true;
  }

  /// Return all images belonging to [vaultId], sorted newest first.
  Future<List<GalleryMedia>> getImages(String vaultId) async {
    final list = DataService.gallery.where((img) => img.vaultId == vaultId);

    list.sort((a, b) => (b.importedAt ?? DateTime(0)).compareTo(a.importedAt ?? DateTime(0)));

    return list;
  }

  /// Decrypt and return thumbnail bytes for grid display.
  /// Pass [encryptionKey] matching the one used at insert time.
  Future<Uint8List> loadThumb(GalleryMedia media, {String encryptionKey = publicKey}) async {
    final encBytes = await File(media.thumbPath!).readAsBytes();
    return await compute(_decryptIsolate, _DecryptParams(encBytes, encryptionKey));
  }

  /// Decrypt and return full image bytes for the viewer.
  /// Pass [encryptionKey] matching the one used at insert time.
  Future<Uint8List> loadFull(GalleryMedia media, {String encryptionKey = publicKey}) async {
    final encBytes = await File(media.filePath!).readAsBytes();
    // run decrypt off main thread
    return await compute(_decryptIsolate, _DecryptParams(encBytes, encryptionKey));
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

  /// AES-CBC encrypt [plainBytes] using [key] padded to 32 bytes.
  /// Output format: [16B IV][ciphertext]
  Uint8List _encrypt(Uint8List plainBytes, String key) {
    final aesKey = aes.Key.fromUtf8(_padKey(key));
    final iv = aes.IV.fromSecureRandom(16);
    final encrypter = aes.Encrypter(aes.AES(aesKey, mode: aes.AESMode.cbc));
    final encrypted = encrypter.encryptBytes(plainBytes, iv: iv);

    final out = BytesBuilder();
    out.add(iv.bytes);
    out.add(encrypted.bytes);
    return out.toBytes();
  }

  /// AES-CBC decrypt [encBytes] (format: [16B IV][ciphertext]) using [key].
  Uint8List _decrypt(Uint8List encBytes, String key) {
    final aesKey = aes.Key.fromUtf8(_padKey(key));
    final iv = aes.IV(encBytes.sublist(0, 16));
    final ciphertext = aes.Encrypted(encBytes.sublist(16));
    final encrypter = aes.Encrypter(aes.AES(aesKey, mode: aes.AESMode.cbc));
    return Uint8List.fromList(encrypter.decryptBytes(ciphertext, iv: iv));
  }

  /// Pad or truncate [key] to exactly 32 chars (AES-256 needs 32B key).
  String _padKey(String key) {
    if (key.length >= 32) return key.substring(0, 32);
    return key.padRight(32, '0');
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

  String _resolveMime(MediaType type, String path) {
    if (type == MediaType.video) return 'video/mp4';
    const map = {
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'png': 'image/png',
      'gif': 'image/gif',
      'webp': 'image/webp',
      'heic': 'image/heic',
    };
    return map[p.extension(path).toLowerCase().replaceAll('.', '')] ?? 'image/jpeg';
  }
  // ── Exposed for VaultService (changePin, export, import) ───────────────────

  /// Public wrapper around [_encrypt] — used by VaultService for re-encryption.
  Uint8List encryptBytes(Uint8List bytes, String key) => _encrypt(bytes, key);

  /// Public wrapper around [_decrypt] — used by VaultService for re-encryption.
  Uint8List decryptBytes(Uint8List bytes, String key) => _decrypt(bytes, key);
}
