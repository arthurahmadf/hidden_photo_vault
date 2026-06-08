// vault_service.dart
//
// Handles all vault operations — auth, creation, and future export/import.
//
// Dependencies (already in project):
//   hive_flutter, encrypt, path_provider, path, uuid, crypto

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/services/data_service.dart';
import '../models/gallery_media_model.dart';
import '../models/vault_model.dart';
import '../services/gallery_service.dart';

class VaultService {
  static const _uuid = Uuid();

  // .hpv binary format constants
  static const _magic = [0x48, 0x56, 0x4C, 0x54]; // "HVLT"
  static const _version = 0x01;
  static const _hpvExtension = '.hpv';

  // ── PIN hashing ─────────────────────────────────────────────────────────────

  /// SHA-256 hash of [pin]. Stored in Hive, never the raw PIN.
  String hashPin(String pin) {
    final bytes = utf8.encode(pin);
    return sha256.convert(bytes).toString();
  }

  // ── V1: Auth & Creation ─────────────────────────────────────────────────────

  /// Find a vault whose pinHash matches [pin].
  /// Returns null if no match — caller treats this as wrong PIN.
  Vault? findVaultByPin(String pin) {
    final hash = hashPin(pin);
    return DataService.vault.find((v) => v.pinHash == hash);
  }

  /// Create a new vault with [pin] and [name].
  /// Returns the created [Vault].
  Future<Vault> createVault(String pin, String name) async {
    final vault = Vault(
      id: _uuid.v4(),
      name: name,
      pinHash: hashPin(pin),
      createdAt: DateTime.now(),
    );
    await DataService.vault.put(vault.id!, vault);
    return vault;
  }

  /// Delete [vault] and all its media from disk + Hive.
  /// Called by splash cleanup for empty vaults older than [gracePeriod].
  Future<void> deleteVault(Vault vault) async {
    // Delete all associated media
    final media = DataService.gallery.where((m) => m.vaultId == vault.id);
    final gs = GalleryService();
    for (final m in media) {
      await gs.deleteMedia(m);
    }
    // Delete vault record
    await DataService.vault.deleteById(vault.id!);
  }

  /// Splash cleanup — wipe empty vaults older than [gracePeriod].
  /// Safe to call on every app launch.
  Future<void> cleanupEmptyVaults({
    Duration gracePeriod = const Duration(hours: 24),
  }) async {
    final allVaults = DataService.vault.list;
    final cutoff = DateTime.now().subtract(gracePeriod);

    for (final vault in allVaults) {
      if (vault.id == 'public') continue; // never wipe public

      final hasMedia = DataService.gallery.exists((m) => m.vaultId == vault.id);
      final isOldEnough = vault.createdAt != null && vault.createdAt!.isBefore(cutoff);

      if (!hasMedia && isOldEnough) {
        await deleteVault(vault);
      }
    }
  }

  // ── Future: Rename & Change PIN ─────────────────────────────────────────────

  /// Rename [vault] to [newName].
  Future<bool> renameVault(Vault vault, String newName) async {
    try {
      final updated = vault.copyWith(name: newName);
      await DataService.vault.update(vault.id!, updated);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Change PIN for [vault] from [oldPin] to [newPin].
  /// Re-encrypts every media file belonging to this vault.
  Future<bool> changePin(
    Vault vault,
    String oldPin,
    String newPin,
  ) async {
    // Verify old PIN
    if (vault.pinHash != hashPin(oldPin)) return false;

    try {
      final gs = GalleryService();
      final media = DataService.gallery.where((m) => m.vaultId == vault.id);

      for (final item in media) {
        // Decrypt full file with old key
        final fullEnc = await File(item.filePath!).readAsBytes();
        final thumbEnc = await File(item.thumbPath!).readAsBytes();

        final fullPlain = gs.decryptBytes(fullEnc, oldPin);
        final thumbPlain = gs.decryptBytes(thumbEnc, oldPin);

        // Re-encrypt with new key
        final newFullEnc = gs.encryptBytes(fullPlain, newPin);
        final newThumbEnc = gs.encryptBytes(thumbPlain, newPin);

        // Overwrite files
        await File(item.filePath!).writeAsBytes(newFullEnc, flush: true);
        await File(item.thumbPath!).writeAsBytes(newThumbEnc, flush: true);
      }

      // Update vault PIN hash
      final updated = vault.copyWith(pinHash: hashPin(newPin));
      await DataService.vault.update(vault.id!, updated);
      return true;
    } catch (_) {
      return false;
    }
  }

  // ── Future: Export (.hpv) ───────────────────────────────────────────────────
  //
  // .hpv binary layout:
  //
  //  Offset   Size     Field
  //  ──────   ──────   ──────────────────────────────────────────────────
  //  0        4        Magic: "HVLT"
  //  4        1        Version: 0x01
  //  5        4        Manifest length (uint32, big-endian)
  //  9        N        Manifest — AES-CBC encrypted JSON (see below)
  //  9+N      ...      Media blobs, concatenated:
  //                      [4B full size][full .enc bytes]
  //                      [4B thumb size][thumb .enc bytes]
  //                    One pair per media item, same order as manifest.
  //
  // Manifest JSON (encrypted with vault PIN, same key as media):
  //  {
  //    "vaultId":    "...",
  //    "vaultName":  "...",
  //    "exportedAt": "ISO8601",
  //    "media": [
  //      { "id", "originalName", "mimeType", "fileSize", "importedAt",
  //        "fullSize", "thumbSize" }
  //    ]
  //  }

  /// Export [vault] to a `.hpv` file in the app cache directory.
  /// Returns the [File] on success, null on failure.
  Future<File?> exportVault(Vault vault, String pin) async {
    if (vault.pinHash != hashPin(pin)) return null;

    try {
      final gs = GalleryService();
      final media = DataService.gallery.where((m) => m.vaultId == vault.id)
        ..sort((a, b) => (a.importedAt ?? DateTime(0)).compareTo(b.importedAt ?? DateTime(0)));

      // Build manifest
      final manifestMap = {
        'vaultId': vault.id,
        'vaultName': vault.name,
        'exportedAt': DateTime.now().toIso8601String(),
        'media': media.map((m) {
          final fullFile = File(m.filePath!);
          final thumbFile = File(m.thumbPath!);
          return {
            'id': m.id,
            'originalName': m.originalName,
            'mimeType': m.mimeType,
            'fileSize': m.fileSize,
            'importedAt': m.importedAt?.toIso8601String(),
            'fullSize': fullFile.lengthSync(),
            'thumbSize': thumbFile.lengthSync(),
            'tag': m.tag ?? 'default',
          };
        }).toList(),
      };

      final manifestJson = jsonEncode(manifestMap);
      final manifestEnc = gs.encryptBytes(utf8.encode(manifestJson), pin);

      // Assemble binary
      final out = BytesBuilder();

      // Magic + version
      out.add(_magic);
      out.addByte(_version);

      // Manifest length + manifest
      final mLen = manifestEnc.length;
      out.add([
        (mLen >> 24) & 0xFF,
        (mLen >> 16) & 0xFF,
        (mLen >> 8) & 0xFF,
        mLen & 0xFF,
      ]);
      out.add(manifestEnc);

      // Media blobs
      for (final m in media) {
        final fullBytes = await File(m.filePath!).readAsBytes();
        final thumbBytes = await File(m.thumbPath!).readAsBytes();

        _writeBlob(out, fullBytes);
        _writeBlob(out, thumbBytes);
      }

      // Write to cache
      final cacheDir = await getTemporaryDirectory();
      final fileName = '${vault.name?.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_') ?? 'vault'}$_hpvExtension';
      final file = File(p.join(cacheDir.path, fileName));
      await file.writeAsBytes(out.toBytes(), flush: true);
      return file;
    } catch (_) {
      return null;
    }
  }

  /// Import a `.hpv` file using [pin].
  /// Creates a new vault and restores all media.
  /// Returns the imported [Vault] on success, null on failure/wrong PIN.
  Future<Vault?> importVault(File hpvFile, String pin) async {
    try {
      final gs = GalleryService();
      final raw = await hpvFile.readAsBytes();
      int offset = 0;

      // Verify magic
      for (int i = 0; i < 4; i++) {
        if (raw[i] != _magic[i]) return null;
      }
      offset += 4;

      // Version (reserved for future compat)
      // ignore: unused_local_variable
      final version = raw[offset];
      offset += 1;

      // Manifest length
      final mLen = (raw[offset] << 24) | (raw[offset + 1] << 16) | (raw[offset + 2] << 8) | raw[offset + 3];
      offset += 4;

      // Decrypt manifest
      final manifestEnc = raw.sublist(offset, offset + mLen);
      offset += mLen;

      late Map<String, dynamic> manifest;
      try {
        final manifestBytes = gs.decryptBytes(manifestEnc, pin);
        manifest = jsonDecode(utf8.decode(manifestBytes));
      } catch (_) {
        return null; // wrong PIN
      }

      // Create new vault (new id, same name)
      final vault = await createVault(pin, manifest['vaultName'] ?? 'Imported');

      // Restore media
      final vaultDir = await _vaultDirectory();
      final mediaList = manifest['media'] as List<dynamic>;

      for (final meta in mediaList) {
        final id = _uuid.v4(); // new id for the restored media
        final fullSize = meta['fullSize'] as int;
        final thumbSize = meta['thumbSize'] as int;

        offset += 4;
        final fullEnc = raw.sublist(offset, offset + fullSize);
        offset += fullSize;
        offset += 4;
        final thumbEnc = raw.sublist(offset, offset + thumbSize);
        offset += thumbSize;

        // Write .enc files
        final fullPath = p.join(vaultDir.path, '$id.enc');
        final thumbPath = p.join(vaultDir.path, '${id}_thumb.enc');
        await File(fullPath).writeAsBytes(fullEnc, flush: true);
        await File(thumbPath).writeAsBytes(thumbEnc, flush: true);

        // Restore Hive record
        final image = GalleryMedia(
          id: id,
          filePath: fullPath,
          thumbPath: thumbPath,
          originalName: meta['originalName'],
          mimeType: meta['mimeType'],
          fileSize: meta['fileSize'],
          importedAt: meta['importedAt'] != null ? DateTime.parse(meta['importedAt']) : DateTime.now(),
          vaultId: vault.id,
          tag: meta['tag'] ?? 'default',
        );
        await DataService.gallery.put(id, image);
      }

      return vault;
    } catch (_) {
      return null;
    }
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  void _writeBlob(BytesBuilder out, Uint8List bytes) {
    final len = bytes.length;
    out.add([
      (len >> 24) & 0xFF,
      (len >> 16) & 0xFF,
      (len >> 8) & 0xFF,
      len & 0xFF,
    ]);
    out.add(bytes);
  }

  Future<Directory> _vaultDirectory() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(base.path, 'vault'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }
}
