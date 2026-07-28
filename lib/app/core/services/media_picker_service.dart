import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import 'package:hidden_photo_vault/app/modules/home/controllers/home_controller.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';

enum MediaType { image, video, any }

const supportedVideoExtensions = <String>{
  '3g2',
  '3gp',
  'asf',
  'avi',
  'dat',
  'divx',
  'dv',
  'f4v',
  'flv',
  'm1v',
  'm2p',
  'm2ts',
  'm2v',
  'm4v',
  'mkv',
  'mov',
  'mp2',
  'mp4',
  'mpe',
  'mpeg',
  'mpg',
  'mpv',
  'mts',
  'mxf',
  'nut',
  'ogm',
  'ogv',
  'qt',
  'rm',
  'rmvb',
  'ts',
  'vob',
  'webm',
  'wmv',
  'wtv',
  'y4m',
};

const supportedImageExtensions = <String>{
  'bmp',
  'gif',
  'heic',
  'heif',
  'jpeg',
  'jpg',
  'png',
  'webp',
};

MediaType resolveMediaType(
  String path, {
  String? mimeType,
  List<int>? headerBytes,
}) {
  final resolvedMime =
      mimeType ?? lookupMimeType(path, headerBytes: headerBytes);
  if (resolvedMime?.toLowerCase().startsWith('video/') ?? false) {
    return MediaType.video;
  }
  final ext = p.extension(path).toLowerCase().replaceFirst('.', '');
  return supportedVideoExtensions.contains(ext)
      ? MediaType.video
      : MediaType.image;
}

String resolveMediaMimeType(
  String path, {
  required MediaType mediaType,
  List<int>? headerBytes,
  String? suppliedMimeType,
}) {
  final detected =
      suppliedMimeType ?? lookupMimeType(path, headerBytes: headerBytes);
  if (detected != null &&
      (detected.startsWith('image/') || detected.startsWith('video/'))) {
    return detected.toLowerCase();
  }

  final ext = p.extension(path).toLowerCase().replaceFirst('.', '');
  const videoFallbacks = <String, String>{
    '3g2': 'video/3gpp2',
    '3gp': 'video/3gpp',
    'asf': 'video/x-ms-asf',
    'avi': 'video/x-msvideo',
    'f4v': 'video/x-f4v',
    'flv': 'video/x-flv',
    'm4v': 'video/x-m4v',
    'mkv': 'video/x-matroska',
    'mov': 'video/quicktime',
    'mp2': 'video/mpeg',
    'mpe': 'video/mpeg',
    'mpeg': 'video/mpeg',
    'mpg': 'video/mpeg',
    'ogv': 'video/ogg',
    'qt': 'video/quicktime',
    'rm': 'video/vnd.rn-realvideo',
    'rmvb': 'video/vnd.rn-realvideo',
    'ts': 'video/mp2t',
    'vob': 'video/mpeg',
    'webm': 'video/webm',
    'wmv': 'video/x-ms-wmv',
  };
  const imageFallbacks = <String, String>{
    'bmp': 'image/bmp',
    'gif': 'image/gif',
    'heic': 'image/heic',
    'heif': 'image/heif',
    'jpeg': 'image/jpeg',
    'jpg': 'image/jpeg',
    'png': 'image/png',
    'webp': 'image/webp',
  };
  if (mediaType == MediaType.video) {
    return videoFallbacks[ext] ?? 'video/mp4';
  }
  return imageFallbacks[ext] ?? 'image/jpeg';
}

enum PickResultStatus {
  success,
  permissionDenied,
  permissionPermanentlyDenied,
  cancelled,
}

class MediaPickResult {
  final XFile? file;
  final PickResultStatus status;
  final MediaType? resolvedType;

  const MediaPickResult._({
    this.file,
    required this.status,
    this.resolvedType,
  });

  factory MediaPickResult.success(XFile file, MediaType type) =>
      MediaPickResult._(
        file: file,
        status: PickResultStatus.success,
        resolvedType: type,
      );

  factory MediaPickResult.permissionDenied() =>
      const MediaPickResult._(status: PickResultStatus.permissionDenied);

  factory MediaPickResult.permissionPermanentlyDenied() =>
      const MediaPickResult._(
        status: PickResultStatus.permissionPermanentlyDenied,
      );

  factory MediaPickResult.cancelled() =>
      const MediaPickResult._(status: PickResultStatus.cancelled);

  bool get isSuccess => status == PickResultStatus.success;
  bool get isVideo => resolvedType == MediaType.video;
  bool get isImage => resolvedType == MediaType.image;
}

class MediaPickerService {
  MediaPickerService._();

  static final MediaPickerService instance = MediaPickerService._();

  final ImagePicker _picker = ImagePicker();

  Future<MediaPickResult> pickFromGallery(MediaType type) async {
    try {
      Get.find<HomeController>().isBusy = true;
      final allowedExtensions = switch (type) {
        MediaType.image => supportedImageExtensions.toList(),
        MediaType.video => supportedVideoExtensions.toList(),
        MediaType.any => {
            ...supportedImageExtensions,
            ...supportedVideoExtensions,
          }.toList(),
      };
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: allowedExtensions,
        allowMultiple: false,
      );
      if (result == null || result.files.isEmpty) {
        return MediaPickResult.cancelled();
      }

      final file = result.files.single.xFile;
      final resolvedType = resolveMediaType(
        file.path,
        mimeType: file.mimeType,
      );
      return MediaPickResult.success(file, resolvedType);
    } catch (_) {
      return MediaPickResult.cancelled();
    }
  }

  Future<MediaPickResult> pickFromCamera(MediaType type) async {
    final camera = await Permission.camera.request();
    if (!camera.isGranted) {
      return camera.isPermanentlyDenied
          ? MediaPickResult.permissionPermanentlyDenied()
          : MediaPickResult.permissionDenied();
    }

    if (type == MediaType.video) {
      final microphone = await Permission.microphone.request();
      if (!microphone.isGranted) {
        return microphone.isPermanentlyDenied
            ? MediaPickResult.permissionPermanentlyDenied()
            : MediaPickResult.permissionDenied();
      }
    }

    Get.find<HomeController>().isBusy = true;
    return _pick(ImageSource.camera, type);
  }

  Future<MediaPickResult> _pick(ImageSource source, MediaType type) async {
    try {
      XFile? file;
      switch (type) {
        case MediaType.image:
          file = await _picker.pickImage(
            source: source,
            imageQuality: source == ImageSource.camera ? 95 : null,
          );
          return file == null
              ? MediaPickResult.cancelled()
              : MediaPickResult.success(file, MediaType.image);
        case MediaType.video:
          file = await _picker.pickVideo(source: source);
          return file == null
              ? MediaPickResult.cancelled()
              : MediaPickResult.success(file, MediaType.video);
        case MediaType.any:
          if (source == ImageSource.camera) {
            return pickFromCamera(MediaType.image);
          }
          file = await _picker.pickMedia();
          if (file == null) return MediaPickResult.cancelled();
          return MediaPickResult.success(
            file,
            resolveMediaType(file.path, mimeType: file.mimeType),
          );
      }
    } catch (_) {
      return MediaPickResult.cancelled();
    }
  }
}
