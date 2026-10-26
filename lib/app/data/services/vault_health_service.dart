import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/services/data_service.dart';
import '../../core/services/sensitive_cache_service.dart';
import '../models/gallery_media_model.dart';
import 'gallery_service.dart';

class VaultHealthReport {
  final int activeItems;
  final int activeBytes;
  final int trashItems;
  final int missingFiles;
  final int orphanFiles;
  final int temporaryBytes;
  final DateTime? lastBackupAt;

  const VaultHealthReport({
    required this.activeItems,
    required this.activeBytes,
    required this.trashItems,
    required this.missingFiles,
    required this.orphanFiles,
    required this.temporaryBytes,
    required this.lastBackupAt,
  });
}

class VaultHealthService {
  static const encryptionFormatVersion = 2;

  Future<VaultHealthReport> inspect(String vaultId) async {
    final all = DataService.gallery.where((item) => item.vaultId == vaultId);
    final active = all.where((item) => item.deletedAt == null).toList();
    final trash = all.where((item) => item.deletedAt != null).toList();

    var missing = 0;
    for (final item in all) {
      if (!await _bothFilesExist(item)) missing++;
    }

    final referenced = DataService.gallery.list
        .expand((item) => [item.filePath, item.thumbPath])
        .whereType<String>()
        .map(p.normalize)
        .toSet();
    final vaultDir = await _vaultDirectory();
    var orphanCount = 0;
    if (await vaultDir.exists()) {
      await for (final entity in vaultDir.list()) {
        if (entity is File && !referenced.contains(p.normalize(entity.path))) {
          orphanCount++;
        }
      }
    }

    return VaultHealthReport(
      activeItems: active.length,
      activeBytes: active.fold(0, (sum, item) => sum + (item.fileSize ?? 0)),
      trashItems: trash.length,
      missingFiles: missing,
      orphanFiles: orphanCount,
      temporaryBytes: await _temporaryBytes(),
      lastBackupAt: DataService.setting.data?.lastBackupAt,
    );
  }

  Future<int> restoreTrash(String vaultId) async {
    final items = DataService.gallery.where(
      (item) => item.vaultId == vaultId && item.deletedAt != null,
    );
    var restored = 0;
    final gallery = GalleryService();
    for (final item in items) {
      if (await gallery.restoreFromTrash(item)) restored++;
    }
    return restored;
  }

  Future<int> emptyTrash(String vaultId) async {
    final items = DataService.gallery.where(
      (item) => item.vaultId == vaultId && item.deletedAt != null,
    );
    var removed = 0;
    final gallery = GalleryService();
    for (final item in items) {
      if (await gallery.deleteMedia(item)) removed++;
    }
    return removed;
  }

  Future<int> cleanup(String vaultId) async {
    var removed = await SensitiveCacheService.clearPlaintextTemporaryFiles();
    final cache = await getTemporaryDirectory();
    await for (final entity in cache.list()) {
      if (entity is File && p.extension(entity.path).toLowerCase() == '.hpv') {
        await entity.delete();
        removed++;
      }
    }
    final referenced = DataService.gallery.list
        .expand((item) => [item.filePath, item.thumbPath])
        .whereType<String>()
        .map(p.normalize)
        .toSet();
    final vaultDir = await _vaultDirectory();
    if (await vaultDir.exists()) {
      await for (final entity in vaultDir.list()) {
        if (entity is File && !referenced.contains(p.normalize(entity.path))) {
          await entity.delete();
          removed++;
        }
      }
    }
    return removed;
  }

  Future<bool> _bothFilesExist(GalleryMedia item) async {
    if (item.filePath == null || item.thumbPath == null) return false;
    return await File(item.filePath!).exists() &&
        await File(item.thumbPath!).exists();
  }

  Future<Directory> _vaultDirectory() async {
    final base = await getApplicationDocumentsDirectory();
    return Directory(p.join(base.path, 'vault'));
  }

  Future<int> _temporaryBytes() async {
    try {
      final dir = await getTemporaryDirectory();
      var bytes = 0;
      await for (final entity in dir.list(recursive: true)) {
        if (entity is File) bytes += await entity.length();
      }
      return bytes;
    } catch (_) {
      return 0;
    }
  }
}
