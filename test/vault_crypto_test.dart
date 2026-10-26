import 'dart:io';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart' as old;
import 'package:flutter_test/flutter_test.dart';
import 'package:hidden_photo_vault/app/data/models/gallery_media_model.dart';
import 'package:hidden_photo_vault/app/data/services/gallery_service.dart';
import 'package:hidden_photo_vault/app/data/services/vault_crypto.dart';

void main() {
  test('PIN unwrap, rewrap and authenticated file round trip', () async {
    const pin = '123456';
    final credential = await VaultCrypto.createCredential(pin);
    expect(await VaultCrypto.unwrap(credential, '000000'), isNull);
    final key = await VaultCrypto.unwrap(credential, pin);
    expect(key, isNotNull);
    final plain = Uint8List.fromList(List.generate(257, (i) => i % 256));
    final encrypted = await VaultCrypto.encrypt(plain, key!);
    expect(VaultCrypto.isModern(encrypted), isTrue);
    expect(await VaultCrypto.decrypt(encrypted, key), plain);

    final rewrapped =
        await VaultCrypto.createCredential('654321', masterKey: key);
    expect(await VaultCrypto.unwrap(rewrapped, pin), isNull);
    final newKey = await VaultCrypto.unwrap(rewrapped, '654321');
    expect(await VaultCrypto.decrypt(encrypted, newKey!), plain);
  });

  test('modified header, nonce, ciphertext and tag are rejected', () async {
    final key = Uint8List.fromList(List.generate(32, (i) => i));
    final encrypted =
        await VaultCrypto.encrypt(Uint8List.fromList([1, 2, 3]), key);
    for (final index in [0, 5, 16, encrypted.length - 1]) {
      final tampered = Uint8List.fromList(encrypted);
      tampered[index] ^= 1;
      expect(() => VaultCrypto.decrypt(tampered, key), throwsException);
    }
    expect(() => VaultCrypto.decrypt(encrypted.sublist(0, 20), key),
        throwsException);
    final bound = await VaultCrypto.encrypt(Uint8List.fromList([9]), key,
        context: 'media:one:full');
    expect(() => VaultCrypto.decrypt(bound, key, context: 'media:two:full'),
        throwsException);
  });

  test('full media decrypts on a worker and rejects tampering', () async {
    const vaultId = 'worker-test-vault';
    const mediaId = 'worker-test-media';
    final directory = await Directory.systemTemp.createTemp('hpv_worker_test_');
    try {
      final key = Uint8List.fromList(List.generate(32, (i) => i));
      final credential =
          await VaultCrypto.createCredential('123456', masterKey: key);
      expect(await VaultCrypto.unlock(vaultId, credential, '123456'), isTrue);
      final plain = Uint8List.fromList(List.generate(4096, (i) => i % 256));
      final file = File('${directory.path}/photo.enc');
      final ciphertext =
          await VaultCrypto.encrypt(plain, key, context: 'media:$mediaId:full');
      await file.writeAsBytes(ciphertext);
      final media =
          GalleryMedia(id: mediaId, filePath: file.path, vaultId: vaultId);
      final gallery = GalleryService();
      expect(await gallery.loadFull(media, encryptionKey: '123456'), plain);

      ciphertext[ciphertext.length - 1] ^= 1;
      await file.writeAsBytes(ciphertext);
      await expectLater(
          gallery.loadFull(media, encryptionKey: '123456'), throwsException);
    } finally {
      VaultCrypto.lock(vaultId);
      await directory.delete(recursive: true);
    }
  });

  test('legacy CBC files can be read for migration', () {
    final key = old.Key.fromUtf8('123456'.padRight(32, '0'));
    final iv = old.IV(Uint8List.fromList(List.generate(16, (i) => i)));
    final ciphertext = old.Encrypter(old.AES(key, mode: old.AESMode.cbc))
        .encryptBytes([1, 2, 3], iv: iv).bytes;
    final oldFile = Uint8List.fromList([...iv.bytes, ...ciphertext]);
    expect(VaultCrypto.decryptLegacy(oldFile, '123456'), [1, 2, 3]);
    expect(() => VaultCrypto.decryptLegacy(oldFile, '000000'),
        throwsArgumentError);
  });
}
