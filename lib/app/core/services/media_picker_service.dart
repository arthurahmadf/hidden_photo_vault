// media_picker_service.dart
//
// Dependencies (add to pubspec.yaml):
//   image_picker: ^1.1.2
//   permission_handler: ^11.3.1
//
// Android — android/app/src/main/AndroidManifest.xml:
//   <uses-permission android:name="android.permission.CAMERA"/>
//   <uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>   (API 33+)
//   <uses-permission android:name="android.permission.READ_MEDIA_VIDEO"/>    (API 33+)
//   <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" android:maxSdkVersion="32"/>
//
// iOS — Info.plist:
//   NSCameraUsageDescription
//   NSPhotoLibraryUsageDescription

import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Media type enum
// ─────────────────────────────────────────────────────────────────────────────

enum MediaType { image, video, any }

// ─────────────────────────────────────────────────────────────────────────────
// Result wrapper
// ─────────────────────────────────────────────────────────────────────────────

enum PickResultStatus { success, permissionDenied, permissionPermanentlyDenied, cancelled }

class MediaPickResult {
  final XFile? file;
  final PickResultStatus status;
  final MediaType? resolvedType; // actual type of the picked file

  const MediaPickResult._({
    this.file,
    required this.status,
    this.resolvedType,
  });

  factory MediaPickResult.success(XFile file, MediaType type) =>
      MediaPickResult._(file: file, status: PickResultStatus.success, resolvedType: type);

  factory MediaPickResult.permissionDenied() => const MediaPickResult._(status: PickResultStatus.permissionDenied);

  factory MediaPickResult.permissionPermanentlyDenied() =>
      const MediaPickResult._(status: PickResultStatus.permissionPermanentlyDenied);

  factory MediaPickResult.cancelled() => const MediaPickResult._(status: PickResultStatus.cancelled);

  bool get isSuccess => status == PickResultStatus.success;
  bool get isVideo => resolvedType == MediaType.video;
  bool get isImage => resolvedType == MediaType.image;
}

// ─────────────────────────────────────────────────────────────────────────────
// Service
// ─────────────────────────────────────────────────────────────────────────────

class MediaPickerService {
  MediaPickerService._();
  static final MediaPickerService instance = MediaPickerService._();

  final _picker = ImagePicker();

  // ── Public API ──────────────────────────────────────────────────────────────

  /// Pick media from the device gallery.
  Future<MediaPickResult> pickFromGallery(MediaType type) async {
    final granted = await _requestGalleryPermission();
    if (!granted.isGranted) {
      return granted.isPermanentlyDenied
          ? MediaPickResult.permissionPermanentlyDenied()
          : MediaPickResult.permissionDenied();
    }
    return _pick(ImageSource.gallery, type);
  }

  /// Capture media from the camera.
  Future<MediaPickResult> pickFromCamera(MediaType type) async {
    final granted = await _requestCameraPermission();
    if (!granted.isGranted) {
      return granted.isPermanentlyDenied
          ? MediaPickResult.permissionPermanentlyDenied()
          : MediaPickResult.permissionDenied();
    }
    return _pick(ImageSource.camera, type);
  }

  // ── Internal pick logic ─────────────────────────────────────────────────────

  Future<MediaPickResult> _pick(ImageSource source, MediaType type) async {
    try {
      XFile? file;

      switch (type) {
        case MediaType.image:
          file = await _picker.pickImage(
            source: source,
            imageQuality: 95,
          );
          return file == null ? MediaPickResult.cancelled() : MediaPickResult.success(file, MediaType.image);

        case MediaType.video:
          file = await _picker.pickVideo(source: source);
          return file == null ? MediaPickResult.cancelled() : MediaPickResult.success(file, MediaType.video);

        case MediaType.any:
          // pickMedia() has no source param — always opens gallery.
          // For camera source, capture an image since camera can't pick
          // an arbitrary media type; video capture needs explicit intent.
          if (source == ImageSource.camera) {
            file = await _picker.pickImage(
              source: ImageSource.camera,
              imageQuality: 95,
            );
            if (file == null) return MediaPickResult.cancelled();
            return MediaPickResult.success(file, MediaType.image);
          }
          // Gallery source — use pickMedia() for true any-type selection.
          file = await _picker.pickMedia();
          if (file == null) return MediaPickResult.cancelled();
          final resolved = _resolveType(file.path);
          return MediaPickResult.success(file, resolved);
      }
    } catch (_) {
      return MediaPickResult.cancelled();
    }
  }

  // ── Permission helpers ──────────────────────────────────────────────────────

  Future<PermissionStatus> _requestGalleryPermission() async {
    if (Platform.isAndroid) {
      final sdkInt = await _androidSdkVersion();
      if (sdkInt >= 33) {
        // Request both; user may grant only one
        await [Permission.photos, Permission.videos].request();
        final photos = await Permission.photos.status;
        return photos;
      } else {
        return await Permission.storage.request();
      }
    } else {
      return await Permission.photos.request();
    }
  }

  Future<PermissionStatus> _requestCameraPermission() async {
    return await Permission.camera.request();
  }

  // ── Utilities ───────────────────────────────────────────────────────────────

  MediaType _resolveType(String path) {
    final ext = path.split('.').last.toLowerCase();
    const videoExts = {'mp4', 'mov', 'avi', 'mkv', 'webm', '3gp'};
    return videoExts.contains(ext) ? MediaType.video : MediaType.image;
  }

  Future<int> _androidSdkVersion() async {
    try {
      final v = int.tryParse(Platform.operatingSystemVersion.split('.').first);
      return v ?? 33;
    } catch (_) {
      return 33;
    }
  }
}

// USAGE EXAMPLE
// In Controller
// XFile? file;
// MediaType? type;

// In build:
// MediaPreviewContainer(
//   file: controller.file,
//   mediaType: controller.type,
//   pickType: MediaType.image, // or .video or .any
//   onChanged: (result) {
//     setState(() {
//       controller.file = result?.file;
//       controller.type = result?.resolvedType;
//     });
//   },
// )