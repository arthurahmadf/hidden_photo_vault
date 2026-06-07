// ignore_for_file: non_constant_identifier_names

import 'package:flutter/services.dart';

abstract final class SystemUi {
  const SystemUi._();

  static Future<void> leanBack() {
    return SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.leanBack,
    );
  }

  static Future<void> immersive() {
    return SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersive,
    );
  }

  static Future<void> immersiveSticky() {
    return SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
    );
  }

  static Future<void> defaultEdgeToEdge() {
    return SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
    );
  }

  static Future<void> manual({
    List<SystemUiOverlay> overlays = const [
      SystemUiOverlay.top,
      SystemUiOverlay.bottom,
    ],
  }) {
    return SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: overlays,
    );
  }

  static Future<void> showStatusBarOnly() {
    return manual(
      overlays: const [
        SystemUiOverlay.top,
      ],
    );
  }

  static Future<void> showNavigationBarOnly() {
    return manual(
      overlays: const [
        SystemUiOverlay.bottom,
      ],
    );
  }

  static Future<void> hideAll() {
    return manual(
      overlays: const [],
    );
  }

  static Future<void> showAll() {
    return manual(
      overlays: const [
        SystemUiOverlay.top,
        SystemUiOverlay.bottom,
      ],
    );
  }
}
