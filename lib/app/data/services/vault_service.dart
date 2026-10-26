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
import 'vault_crypto.dart';

class VaultService {
  static const _uuid = Uuid();

  // .hpv binary format constants
  static const _magic = [0x48, 0x56, 0x4C, 0x54]; // "HVLT"
  static const _version = 0x02;
  static const _hpvExtension = '.hpv';

  // ── PIN hashing ─────────────────────────────────────────────────────────────

  /// Legacy verifier, retained only to unlock and upgrade existing vaults.
  String hashPin(String pin) {
    final bytes = utf8.encode(pin);
    return sha256.convert(bytes).toString();
  }

  // ── Auth & creation ─────────────────────────────────────────────────────────

  /// Find a vault whose pinHash matches [pin].
  /// Returns null if no match — caller treats this as wrong PIN.
  Future<Vault?> findVaultByPin(String pin) async {
    final hash = hashPin(pin);
    for (final vault in DataService.vault.list) {
      if (vault.id == null || vault.pinHash == null) continue;
      if (vault.pinHash!.startsWith('v2:')) {
        if (!await VaultCrypto.unlock(vault.id!, vault.pinHash!, pin)) continue;
      } else {
        if (vault.pinHash != hash) continue;
        final credential = await VaultCrypto.createCredential(pin);
        await DataService.vault
            .update(vault.id!, vault.copyWith(pinHash: credential));
        vault.pinHash = credential;
        if (!await VaultCrypto.unlock(vault.id!, credential, pin)) {
          throw StateError('Vault upgrade failed');
        }
      }
      try {
        await _upgradeLegacyMedia(vault, pin);
      } catch (_) {
        // An individual missing or damaged file must not lock out the vault.
        // PIN rotation and export still require every file to migrate.
      }
      return vault;
    }
    return null;
  }

  /// Create a new vault with [pin] and [name].
  /// Returns the created [Vault].
  Future<Vault> createVault(String pin, String name) async {
    final vault = Vault(
      id: _uuid.v4(),
      name: name,
      pinHash: await VaultCrypto.createCredential(pin),
      createdAt: DateTime.now(),
    );
    await DataService.vault.put(vault.id!, vault);
    if (!await VaultCrypto.unlock(vault.id!, vault.pinHash!, pin)) {
      await DataService.vault.deleteById(vault.id!);
      throw StateError('Could not unlock new vault');
    }
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
    VaultCrypto.lock(vault.id!);
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
      final isOldEnough =
          vault.createdAt != null && vault.createdAt!.isBefore(cutoff);

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
  /// Rewraps the random vault key after upgrading any legacy media.
  Future<bool> changePin(
    Vault vault,
    String oldPin,
    String newPin,
  ) async {
    try {
      if (vault.id == null || vault.pinHash == null) return false;
      if (vault.pinHash!.startsWith('v2:')) {
        if (!await VaultCrypto.unlock(vault.id!, vault.pinHash!, oldPin)) {
          return false;
        }
      } else if (vault.pinHash != hashPin(oldPin)) {
        return false;
      } else {
        final upgraded = await VaultCrypto.createCredential(oldPin);
        await DataService.vault
            .update(vault.id!, vault.copyWith(pinHash: upgraded));
        vault.pinHash = upgraded;
        await VaultCrypto.unlock(vault.id!, upgraded, oldPin);
      }
      await _upgradeLegacyMedia(vault, oldPin);
      final key = VaultCrypto.unlockedKey(vault.id!);
      if (key == null) return false;
      final updated = vault.copyWith(
          pinHash: await VaultCrypto.createCredential(newPin, masterKey: key));
      await DataService.vault.update(vault.id!, updated);
      vault.pinHash = updated.pinHash;
      return true;
    } catch (_) {
      return false;
    }
  }

  // V2 archive: HVLT | version | credential length | wrapped master
  // credential | manifest length | authenticated manifest | length-prefixed
  // encrypted blobs. The authenticated manifest includes each blob's SHA-256.

  /// Export [vault] to a `.hpv` file in the app cache directory.
  /// Returns the [File] on success, null on failure.
  Future<File?> exportVault(Vault vault, String pin) async {
    File? archive;
    try {
      if (vault.id == null || vault.pinHash == null) return null;
      if (!await VaultCrypto.unlock(vault.id!, vault.pinHash!, pin)) {
        return null;
      }
      await _upgradeLegacyMedia(vault, pin);
      final media = DataService.gallery.where(
        (m) => m.vaultId == vault.id && m.deletedAt == null,
      )..sort((a, b) =>
          (a.importedAt ?? DateTime(0)).compareTo(b.importedAt ?? DateTime(0)));

      final records = <Map<String, dynamic>>[];
      for (final m in media) {
        final full = await File(m.filePath!).readAsBytes();
        final thumb = await File(m.thumbPath!).readAsBytes();
        if (!VaultCrypto.isModern(full) || !VaultCrypto.isModern(thumb)) {
          throw const FormatException('Legacy media could not be upgraded');
        }
        // Verify authentication before creating a backup.
        final key = VaultCrypto.unlockedKey(vault.id!)!;
        await VaultCrypto.decrypt(full, key, context: 'media:${m.id}:full');
        await VaultCrypto.decrypt(thumb, key, context: 'media:${m.id}:thumb');
        records.add({
          'id': m.id,
          'originalName': m.originalName,
          'mimeType': m.mimeType,
          'fileSize': m.fileSize,
          'importedAt': m.importedAt?.toIso8601String(),
          'fullSize': full.length,
          'fullDigest': sha256.convert(full).toString(),
          'thumbSize': thumb.length,
          'thumbDigest': sha256.convert(thumb).toString(),
          'tag': m.tag ?? 'default',
          'durationMs': m.durationMs,
          'width': m.width,
          'height': m.height,
        });
      }
      final manifestMap = {
        'vaultName': vault.name,
        'exportedAt': DateTime.now().toIso8601String(),
        'media': records,
      };

      final manifestJson = jsonEncode(manifestMap);
      final manifestEnc = await VaultCrypto.encrypt(
          Uint8List.fromList(utf8.encode(manifestJson)),
          VaultCrypto.unlockedKey(vault.id!)!,
          context: 'manifest');

      final credential = Uint8List.fromList(utf8.encode(vault.pinHash!));
      final cacheDir = await getTemporaryDirectory();
      final fileName = '${_uuid.v4()}$_hpvExtension';
      archive = File(p.join(cacheDir.path, fileName));
      final output = await archive.open(mode: FileMode.write);
      try {
        await output.writeFrom([..._magic, _version]);
        await _writeBlobToFile(output, credential);
        await _writeBlobToFile(output, manifestEnc);
        for (var i = 0; i < media.length; i++) {
          final full = await File(media[i].filePath!).readAsBytes();
          final thumb = await File(media[i].thumbPath!).readAsBytes();
          if (sha256.convert(full).toString() != records[i]['fullDigest'] ||
              sha256.convert(thumb).toString() != records[i]['thumbDigest']) {
            throw const FormatException('Media changed during export');
          }
          await _writeBlobToFile(output, full);
          await _writeBlobToFile(output, thumb);
        }
        await output.flush();
      } finally {
        await output.close();
      }
      return archive;
    } catch (_) {
      if (archive != null && await archive.exists()) await archive.delete();
      return null;
    }
  }

  /// Import a `.hpv` file using [pin].
  /// Creates a vault or restores into an existing vault with the same PIN.
  /// Returns the imported [Vault] on success, null on failure/wrong PIN.
  Future<Vault?> importVault(File hpvFile, String pin) async {
    try {
      final input = await hpvFile.open();
      try {
        final length = await input.length();
        final header = await input.read(5);
        if (header.length != 5 ||
            !List.generate(4, (i) => header[i] == _magic[i]).every((b) => b)) {
          return null;
        }
        if (header[4] == 1) {
          return _importLegacy(await hpvFile.readAsBytes(), pin);
        }
        if (header[4] != _version) return null;
        final credential =
            utf8.decode(await _readBlobFromFile(input, length, maxLength: 512));
        final key = await VaultCrypto.unwrap(credential, pin);
        if (key == null) return null;
        final manifestEnc =
            await _readBlobFromFile(input, length, maxLength: 64 * 1024 * 1024);
        final manifest = jsonDecode(utf8.decode(
            await VaultCrypto.decrypt(manifestEnc, key, context: 'manifest')));
        if (manifest is! Map<String, dynamic> || manifest['media'] is! List) {
          return null;
        }
        final mediaList = manifest['media'] as List;
        if (mediaList.length > 100000) return null;
        final pending = <(Map<String, dynamic>, int, int)>[];
        for (final entry in mediaList) {
          if (entry is! Map<String, dynamic>) return null;
          if (entry['id'] is! String || (entry['id'] as String).isEmpty) {
            return null;
          }
          final fullOffset = await input.position();
          final full = await _readBlobFromFile(input, length);
          final thumbOffset = await input.position();
          final thumb = await _readBlobFromFile(input, length);
          if (entry['fullSize'] != full.length ||
              entry['thumbSize'] != thumb.length ||
              entry['fullDigest'] != sha256.convert(full).toString() ||
              entry['thumbDigest'] != sha256.convert(thumb).toString()) {
            return null;
          }
          await VaultCrypto.decrypt(full, key,
              context: 'media:${entry['id']}:full');
          await VaultCrypto.decrypt(thumb, key,
              context: 'media:${entry['id']}:thumb');
          pending.add((entry, fullOffset, thumbOffset));
        }
        if (await input.position() != length) return null;

        // A PIN identifies one vault in the UI. Restore into it when present.
        final existing = await findVaultByPin(pin);
        final vault = existing ??
            Vault(
              id: _uuid.v4(),
              name: manifest['vaultName'] is String
                  ? manifest['vaultName']
                  : 'Imported',
              pinHash: credential,
              createdAt: DateTime.now(),
            );
        final vaultDir = await _vaultDirectory();
        final written = <File>[];
        final savedIds = <String>[];
        try {
          for (final (meta, fullOffset, thumbOffset) in pending) {
            await input.setPosition(fullOffset);
            final fullEnc = await _readBlobFromFile(input, length);
            await input.setPosition(thumbOffset);
            final thumbEnc = await _readBlobFromFile(input, length);
            if (sha256.convert(fullEnc).toString() != meta['fullDigest'] ||
                sha256.convert(thumbEnc).toString() != meta['thumbDigest']) {
              throw const FormatException('Archive changed during import');
            }
            final id = _uuid.v4();
            final fullPath = p.join(vaultDir.path, '$id.enc');
            final thumbPath = p.join(vaultDir.path, '${id}_thumb.enc');
            final fullFile = File(fullPath);
            final thumbFile = File(thumbPath);
            final destinationKey =
                existing == null ? key : VaultCrypto.unlockedKey(existing.id!)!;
            final storedFull = await VaultCrypto.encrypt(
              await VaultCrypto.decrypt(fullEnc, key,
                  context: 'media:${meta['id']}:full'),
              destinationKey,
              context: 'media:$id:full',
            );
            final storedThumb = await VaultCrypto.encrypt(
              await VaultCrypto.decrypt(thumbEnc, key,
                  context: 'media:${meta['id']}:thumb'),
              destinationKey,
              context: 'media:$id:thumb',
            );
            await fullFile.writeAsBytes(storedFull, flush: true);
            written.add(fullFile);
            await thumbFile.writeAsBytes(storedThumb, flush: true);
            written.add(thumbFile);
            final image = GalleryMedia(
              id: id,
              filePath: fullPath,
              thumbPath: thumbPath,
              originalName: _safeName(meta['originalName']),
              mimeType: meta['mimeType'],
              fileSize: meta['fileSize'],
              importedAt: meta['importedAt'] != null
                  ? DateTime.parse(meta['importedAt'])
                  : DateTime.now(),
              vaultId: vault.id,
              tag: meta['tag'] ?? 'default',
              durationMs: meta['durationMs'],
              width: meta['width'],
              height: meta['height'],
            );
            savedIds.add(id);
            await DataService.gallery.put(id, image);
          }
          if (existing == null) await DataService.vault.put(vault.id!, vault);
        } catch (_) {
          for (final id in savedIds) {
            await DataService.gallery.deleteById(id);
          }
          for (final file in written) {
            if (await file.exists()) await file.delete();
          }
          rethrow;
        }
        return vault;
      } finally {
        await input.close();
      }
    } catch (_) {
      return null;
    }
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  Future<void> _writeBlobToFile(RandomAccessFile out, Uint8List bytes) async {
    final len = bytes.length;
    await out.writeFrom([
      (len >> 24) & 0xFF,
      (len >> 16) & 0xFF,
      (len >> 8) & 0xFF,
      len & 0xFF,
    ]);
    await out.writeFrom(bytes);
  }

  Future<Uint8List> _readBlobFromFile(RandomAccessFile input, int fileLength,
      {int? maxLength}) async {
    final position = await input.position();
    if (fileLength - position < 4) {
      throw const FormatException('Truncated archive');
    }
    final header = await input.read(4);
    if (header.length != 4) throw const FormatException('Truncated archive');
    final len =
        (header[0] << 24) | (header[1] << 16) | (header[2] << 8) | header[3];
    if (len < 0 ||
        len > fileLength - position - 4 ||
        (maxLength != null && len > maxLength)) {
      throw const FormatException('Invalid archive length');
    }
    final bytes = await input.read(len);
    if (bytes.length != len) throw const FormatException('Truncated archive');
    return bytes;
  }

  Uint8List _readBlob(
      Uint8List raw, int Function() getOffset, void Function(int) setOffset) {
    final start = getOffset();
    if (start < 0 || start + 4 > raw.length) {
      throw const FormatException('Truncated archive');
    }
    final len = (raw[start] << 24) |
        (raw[start + 1] << 16) |
        (raw[start + 2] << 8) |
        raw[start + 3];
    if (len < 0 || len > raw.length - start - 4) {
      throw const FormatException('Invalid archive length');
    }
    setOffset(start + 4 + len);
    return raw.sublist(start + 4, start + 4 + len);
  }

  Future<Vault?> _importLegacy(Uint8List raw, String pin) async {
    try {
      var offset = 5;
      final manifestBytes = _readBlob(raw, () => offset, (v) => offset = v);
      final manifest = jsonDecode(
          utf8.decode(VaultCrypto.decryptLegacy(manifestBytes, pin)));
      if (manifest is! Map<String, dynamic> || manifest['media'] is! List) {
        return null;
      }
      final entries = manifest['media'] as List;
      if (entries.length > 100000) return null;
      final credential = await VaultCrypto.createCredential(pin);
      final key = await VaultCrypto.unwrap(credential, pin);
      if (key == null) return null;
      final pending = <(Map<String, dynamic>, Uint8List, Uint8List)>[];
      for (final entry in entries) {
        if (entry is! Map<String, dynamic>) return null;
        final full = _readBlob(raw, () => offset, (v) => offset = v);
        final thumb = _readBlob(raw, () => offset, (v) => offset = v);
        if (entry['fullSize'] != full.length ||
            entry['thumbSize'] != thumb.length) return null;
        final fullClear = VaultCrypto.decryptLegacy(full, pin);
        final thumbClear = VaultCrypto.decryptLegacy(thumb, pin);
        pending.add((
          entry,
          await VaultCrypto.encrypt(fullClear, key),
          await VaultCrypto.encrypt(thumbClear, key)
        ));
      }
      if (offset != raw.length) return null;
      final existing = await findVaultByPin(pin);
      final vault = existing ??
          Vault(
            id: _uuid.v4(),
            name: manifest['vaultName'] is String
                ? manifest['vaultName']
                : 'Imported',
            pinHash: credential,
            createdAt: DateTime.now(),
          );
      final vaultDir = await _vaultDirectory();
      final written = <File>[];
      final savedIds = <String>[];
      try {
        for (final (meta, full, thumb) in pending) {
          final id = _uuid.v4();
          final fullFile = File(p.join(vaultDir.path, '$id.enc'));
          final thumbFile = File(p.join(vaultDir.path, '${id}_thumb.enc'));
          final destinationKey =
              existing == null ? key : VaultCrypto.unlockedKey(existing.id!)!;
          final storedFull = await VaultCrypto.encrypt(
              await VaultCrypto.decrypt(full, key), destinationKey,
              context: 'media:$id:full');
          final storedThumb = await VaultCrypto.encrypt(
              await VaultCrypto.decrypt(thumb, key), destinationKey,
              context: 'media:$id:thumb');
          await fullFile.writeAsBytes(storedFull, flush: true);
          written.add(fullFile);
          await thumbFile.writeAsBytes(storedThumb, flush: true);
          written.add(thumbFile);
          savedIds.add(id);
          await DataService.gallery.put(
              id,
              GalleryMedia(
                id: id,
                filePath: fullFile.path,
                thumbPath: thumbFile.path,
                originalName: _safeName(meta['originalName']),
                mimeType: meta['mimeType'],
                fileSize: meta['fileSize'],
                importedAt: meta['importedAt'] != null
                    ? DateTime.parse(meta['importedAt'])
                    : DateTime.now(),
                vaultId: vault.id,
                tag: meta['tag'] ?? 'default',
                durationMs: meta['durationMs'],
                width: meta['width'],
                height: meta['height'],
              ));
        }
        if (existing == null) await DataService.vault.put(vault.id!, vault);
      } catch (_) {
        for (final id in savedIds) {
          await DataService.gallery.deleteById(id);
        }
        for (final file in written) {
          if (await file.exists()) await file.delete();
        }
        rethrow;
      }
      return vault;
    } catch (_) {
      return null;
    }
  }

  String _safeName(dynamic value) {
    if (value is! String || value.trim().isEmpty) return 'imported_media';
    final name = p.windows.basename(p.posix.basename(value));
    if (name.isEmpty || name == '.' || name == '..') return 'imported_media';
    return name;
  }

  Future<void> _upgradeLegacyMedia(Vault vault, String pin) async {
    final key = VaultCrypto.unlockedKey(vault.id!);
    if (key == null) throw StateError('Vault is locked');
    final media = DataService.gallery.where((m) => m.vaultId == vault.id);
    for (final item in media) {
      for (final path in [item.filePath, item.thumbPath]) {
        if (path == null) throw const FormatException('Missing media path');
        final file = File(path);
        final handle = await file.open();
        final prefix = await handle.read(4);
        await handle.close();
        if (prefix.length == 4 &&
            prefix[0] == 0x48 &&
            prefix[1] == 0x50 &&
            prefix[2] == 0x56 &&
            prefix[3] == 0x32) continue;
        final bytes = await file.readAsBytes();
        final clear = VaultCrypto.decryptLegacy(bytes, pin);
        final kind = path == item.filePath ? 'full' : 'thumb';
        final upgraded = await VaultCrypto.encrypt(clear, key,
            context: 'media:${item.id}:$kind');
        final staged = File('$path.migrating');
        await staged.writeAsBytes(upgraded, flush: true);
        await staged.rename(path);
      }
    }
  }

  Future<Directory> _vaultDirectory() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(base.path, 'vault'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }
}
