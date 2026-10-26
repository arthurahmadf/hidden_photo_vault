import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:encrypt/encrypt.dart' as legacy;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Version 2: a random 256-bit vault key, wrapped by Argon2id(PIN, salt).
/// Files are AES-256-GCM with a fresh 96-bit nonce and a 128-bit tag.
class VaultCrypto {
  VaultCrypto._();

  static final _cipher = AesGcm.with256bits();
  static final _kdf = Argon2id(
    memory: 19 * 1024,
    parallelism: 1,
    iterations: 2,
    hashLength: 32,
  );
  static const _storage = FlutterSecureStorage();
  static const _publicStorageKey = 'public_vault_key_v2';
  static const _fileHeader = [0x48, 0x50, 0x56, 0x32]; // HPV2
  static final Map<String, Uint8List> _unlocked = {};
  static Future<Uint8List>? _publicPending;

  static Uint8List _random(int length) {
    final random = Random.secure();
    return Uint8List.fromList(
        List.generate(length, (_) => random.nextInt(256)));
  }

  static bool isModern(Uint8List bytes) =>
      bytes.length >= 4 &&
      List.generate(4, (i) => bytes[i] == _fileHeader[i]).every((b) => b);

  static Future<String> createCredential(String pin,
      {Uint8List? masterKey}) async {
    final salt = _random(16);
    final master = masterKey ?? _random(32);
    if (master.length != 32) throw ArgumentError('Invalid vault key');
    final wrappingKey =
        await _kdf.deriveKeyFromPassword(password: pin, nonce: salt);
    final nonce = _random(12);
    final box = await _cipher.encrypt(master,
        secretKey: wrappingKey, nonce: nonce, aad: utf8.encode('HPV2:wrap'));
    return 'v2:${base64Url.encode(salt)}:${base64Url.encode(nonce)}:'
        '${base64Url.encode([...box.cipherText, ...box.mac.bytes])}';
  }

  static Future<Uint8List?> unwrap(String credential, String pin) async {
    try {
      final parts = credential.split(':');
      if (parts.length != 4 || parts[0] != 'v2') return null;
      final salt = base64Url.decode(parts[1]);
      final nonce = base64Url.decode(parts[2]);
      final encrypted = base64Url.decode(parts[3]);
      if (salt.length != 16 || nonce.length != 12 || encrypted.length != 48) {
        return null;
      }
      final wrappingKey =
          await _kdf.deriveKeyFromPassword(password: pin, nonce: salt);
      final clear = await _cipher.decrypt(
        SecretBox(encrypted.sublist(0, 32),
            nonce: nonce, mac: Mac(encrypted.sublist(32))),
        secretKey: wrappingKey,
        aad: utf8.encode('HPV2:wrap'),
      );
      return Uint8List.fromList(clear);
    } catch (_) {
      return null;
    }
  }

  static Future<bool> unlock(
      String vaultId, String credential, String pin) async {
    final key = await unwrap(credential, pin);
    if (key == null) return false;
    _unlocked[vaultId] = key;
    return true;
  }

  static void lock(String vaultId) {
    final key = _unlocked.remove(vaultId);
    key?.fillRange(0, key.length, 0);
  }

  static Uint8List? unlockedKey(String vaultId) => _unlocked[vaultId];

  static Future<Uint8List> publicKey() async {
    final cached = _unlocked['public'];
    if (cached != null) return cached;
    return _publicPending ??= _loadPublicKey().whenComplete(() {
      _publicPending = null;
    });
  }

  static Future<Uint8List> _loadPublicKey() async {
    final saved = await _storage.read(key: _publicStorageKey);
    final key = saved == null
        ? _random(32)
        : Uint8List.fromList(base64Url.decode(saved));
    if (key.length != 32) throw StateError('Invalid public vault key');
    if (saved == null) {
      await _storage.write(
          key: _publicStorageKey, value: base64Url.encode(key));
    }
    _unlocked['public'] = key;
    return key;
  }

  static List<int> _aad(String context) =>
      [..._fileHeader, ...utf8.encode(context)];

  static Future<Uint8List> encrypt(Uint8List plain, Uint8List key,
      {String context = ''}) async {
    final nonce = _random(12);
    final box = await _cipher.encrypt(plain,
        secretKey: SecretKey(key), nonce: nonce, aad: _aad(context));
    return Uint8List.fromList([
      ..._fileHeader,
      ...nonce,
      ...box.cipherText,
      ...box.mac.bytes,
    ]);
  }

  static Future<Uint8List> decrypt(Uint8List bytes, Uint8List key,
      {String context = ''}) async {
    if (!isModern(bytes) || bytes.length < 32) {
      throw const FormatException('Unsupported encrypted file');
    }
    final nonce = bytes.sublist(4, 16);
    final mac = bytes.sublist(bytes.length - 16);
    final cipherText = bytes.sublist(16, bytes.length - 16);
    final clear = await _cipher.decrypt(
      SecretBox(cipherText, nonce: nonce, mac: Mac(mac)),
      secretKey: SecretKey(key),
      aad: _aad(context),
    );
    return Uint8List.fromList(clear);
  }

  /// Read only for migration of files written by the original CBC format.
  static Uint8List decryptLegacy(Uint8List bytes, String pin) {
    if (bytes.length < 32 || (bytes.length - 16) % 16 != 0) {
      throw const FormatException('Invalid legacy encrypted file');
    }
    final padded =
        pin.length >= 32 ? pin.substring(0, 32) : pin.padRight(32, '0');
    final encrypter = legacy.Encrypter(
        legacy.AES(legacy.Key.fromUtf8(padded), mode: legacy.AESMode.cbc));
    return Uint8List.fromList(encrypter.decryptBytes(
        legacy.Encrypted(bytes.sublist(16)),
        iv: legacy.IV(bytes.sublist(0, 16))));
  }
}
