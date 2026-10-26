import 'package:flutter/services.dart';

class PrivacyService {
  PrivacyService._();

  static const _channel = MethodChannel('hidden_photo_vault/privacy');

  static Future<void> setPrivateVaultOpen(bool value) async {
    try {
      await _channel.invokeMethod<void>('setSecure', {'enabled': value});
    } on MissingPluginException {
      // Allows tests and unsupported platforms to keep running.
    }
  }
}
