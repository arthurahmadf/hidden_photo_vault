import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:encrypt/encrypt.dart' as old;
import 'package:hidden_photo_vault/app/core/services/data_service.dart';
import 'package:hidden_photo_vault/app/data/models/gallery_media_model.dart';
import 'package:hidden_photo_vault/app/data/models/vault_model.dart';
import 'package:hidden_photo_vault/app/data/services/vault_crypto.dart';
import 'package:hidden_photo_vault/app/data/services/vault_service.dart';
import 'package:hive/hive.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

class _TestPaths extends PathProviderPlatform {
  _TestPaths(this.root);
  final String root;
  @override
  Future<String?> getApplicationDocumentsPath() async => root;
  @override
  Future<String?> getTemporaryPath() async => root;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;

  setUpAll(() async {
    directory = await Directory.systemTemp.createTemp('hpv_crypto_test_');
    PathProviderPlatform.instance = _TestPaths(directory.path);
    Hive.init(directory.path);
    Hive.registerAdapter(VaultAdapter());
    Hive.registerAdapter(GalleryMediaAdapter());
    await DataService.vault.init();
    await DataService.gallery.init();
  });

  tearDownAll(() async {
    await DataService.gallery.close();
    await DataService.vault.close();
    await directory.delete(recursive: true);
  });

  test('PIN rotation keeps ciphertext and archive detects modified blobs',
      () async {
    final service = VaultService();
    final vault = await service.createVault('123456', 'Test vault');
    final key = VaultCrypto.unlockedKey(vault.id!)!;
    final full = await VaultCrypto.encrypt(Uint8List.fromList([1, 2, 3]), key,
        context: 'media:media:full');
    final thumb = await VaultCrypto.encrypt(Uint8List.fromList([4, 5]), key,
        context: 'media:media:thumb');
    final mediaDir = Directory(p.join(directory.path, 'vault'));
    await mediaDir.create();
    final fullFile = File(p.join(mediaDir.path, 'media.enc'));
    final thumbFile = File(p.join(mediaDir.path, 'media_thumb.enc'));
    await fullFile.writeAsBytes(full);
    await thumbFile.writeAsBytes(thumb);
    await DataService.gallery.put(
        'media',
        GalleryMedia(
          id: 'media',
          vaultId: vault.id,
          filePath: fullFile.path,
          thumbPath: thumbFile.path,
          fileSize: 3,
          originalName: 'test.jpg',
          mimeType: 'image/jpeg',
          importedAt: DateTime.now(),
        ));

    expect(await service.changePin(vault, '000000', '654321'), isFalse);
    expect(await service.changePin(vault, '123456', '654321'), isTrue);
    expect(await fullFile.readAsBytes(), full);
    expect(await service.findVaultByPin('123456'), isNull);
    expect((await service.findVaultByPin('654321'))?.id, vault.id);

    final archive = await service.exportVault(vault, '654321');
    expect(archive, isNotNull);
    final imported = await service.importVault(archive!, '654321');
    expect(imported, isNotNull);
    expect(imported!.id, vault.id);
    final importedKey = await VaultCrypto.unwrap(imported.pinHash!, '654321');
    expect(importedKey, isNotNull);
    final importedMedia = DataService.gallery
        .where((m) => m.vaultId == imported.id && m.id != 'media')
        .single;
    expect(
        await VaultCrypto.decrypt(
            await File(importedMedia.filePath!).readAsBytes(), importedKey!,
            context: 'media:${importedMedia.id}:full'),
        [1, 2, 3]);

    final altered = Uint8List.fromList(await archive.readAsBytes());
    altered[altered.length - 1] ^= 1;
    final badArchive = File(p.join(directory.path, 'bad.hpv'));
    await badArchive.writeAsBytes(altered);
    final before = DataService.vault.list.length;
    expect(await service.importVault(badArchive, '654321'), isNull);
    expect(DataService.vault.list.length, before);
  });

  test('legacy vault files migrate after a successful PIN unlock', () async {
    const pin = '112233';
    final service = VaultService();
    final vault = Vault(
      id: 'legacy-vault',
      name: 'Old vault',
      pinHash: service.hashPin(pin),
      createdAt: DateTime.now(),
    );
    await DataService.vault.put(vault.id!, vault);
    final iv = old.IV(Uint8List.fromList(List.generate(16, (i) => i)));
    final encrypter = old.Encrypter(old
        .AES(old.Key.fromUtf8(pin.padRight(32, '0')), mode: old.AESMode.cbc));
    final legacyBytes = Uint8List.fromList([
      ...iv.bytes,
      ...encrypter.encryptBytes([7, 8, 9], iv: iv).bytes,
    ]);
    final mediaDir = Directory(p.join(directory.path, 'vault'));
    final fullFile = File(p.join(mediaDir.path, 'legacy.enc'));
    final thumbFile = File(p.join(mediaDir.path, 'legacy_thumb.enc'));
    await fullFile.writeAsBytes(legacyBytes);
    await thumbFile.writeAsBytes(legacyBytes);
    await DataService.gallery.put(
        'legacy',
        GalleryMedia(
          id: 'legacy',
          vaultId: vault.id,
          filePath: fullFile.path,
          thumbPath: thumbFile.path,
          fileSize: 3,
        ));

    expect((await service.findVaultByPin(pin))?.id, vault.id);
    expect(vault.pinHash, startsWith('v2:'));
    final migrated = await fullFile.readAsBytes();
    expect(VaultCrypto.isModern(migrated), isTrue);
    expect(
        await VaultCrypto.decrypt(migrated, VaultCrypto.unlockedKey(vault.id!)!,
            context: 'media:legacy:full'),
        [7, 8, 9]);
  });

  test('version 1 backup imports into authenticated version 2 media', () async {
    const pin = '998877';
    final iv = old.IV(Uint8List.fromList(List.generate(16, (i) => i + 1)));
    final encrypter = old.Encrypter(old
        .AES(old.Key.fromUtf8(pin.padRight(32, '0')), mode: old.AESMode.cbc));
    Uint8List legacy(List<int> clear) => Uint8List.fromList(
        [...iv.bytes, ...encrypter.encryptBytes(clear, iv: iv).bytes]);
    final full = legacy([10, 11]);
    final thumb = legacy([12]);
    final manifest = legacy(utf8.encode(jsonEncode({
      'vaultName': 'Old backup',
      'media': [
        {
          'originalName': '../old.jpg',
          'mimeType': 'image/jpeg',
          'fileSize': 2,
          'fullSize': full.length,
          'thumbSize': thumb.length,
        }
      ],
    })));
    final archiveBytes = BytesBuilder()..add([0x48, 0x56, 0x4c, 0x54, 1]);
    void addBlob(Uint8List bytes) {
      final length = bytes.length;
      archiveBytes.add([
        (length >> 24) & 255,
        (length >> 16) & 255,
        (length >> 8) & 255,
        length & 255,
      ]);
      archiveBytes.add(bytes);
    }

    addBlob(manifest);
    addBlob(full);
    addBlob(thumb);
    final archive = File(p.join(directory.path, 'legacy.hpv'));
    await archive.writeAsBytes(archiveBytes.toBytes());
    final imported = await VaultService().importVault(archive, pin);
    expect(imported, isNotNull);
    final restored =
        DataService.gallery.where((m) => m.vaultId == imported!.id).single;
    expect(restored.originalName, 'old.jpg');
    final key = await VaultCrypto.unwrap(imported!.pinHash!, pin);
    expect(
        await VaultCrypto.decrypt(
            await File(restored.filePath!).readAsBytes(), key!,
            context: 'media:${restored.id}:full'),
        [10, 11]);
  });
}
