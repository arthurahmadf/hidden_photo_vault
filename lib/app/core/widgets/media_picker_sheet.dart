// media_source_sheet.dart
//
// Usage:
//   final result = await showMediaSourceSheet(context, type: MediaType.image);
//   if (result != null && result.isSuccess) {
//     final file = result.file!;
//   }

// ignore_for_file: use_build_context_synchronously

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hidden_photo_vault/app/core/helpers/dialog_helper.dart';
import 'package:hidden_photo_vault/app/core/style/app_colors.dart';
import 'package:hidden_photo_vault/app/core/style/app_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../services/dialog_service.dart';
import '../services/media_picker_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Public entry point — call this from anywhere
// ─────────────────────────────────────────────────────────────────────────────

/// Shows a bottom sheet for the user to choose Gallery or Camera,
/// then picks media of [type]. Returns [MediaPickResult] or null if dismissed.
Future<MediaPickResult?> showMediaSourceSheet(
  BuildContext context, {
  MediaType type = MediaType.image,
}) {
  return showModalBottomSheet<MediaPickResult>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => _MediaSourceSheet(type: type),
    isScrollControlled: true,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Sheet widget (private)
// ─────────────────────────────────────────────────────────────────────────────

class _MediaSourceSheet extends StatelessWidget {
  final MediaType type;
  const _MediaSourceSheet({required this.type});

  String get _title {
    switch (type) {
      case MediaType.image:
        return 'Add Image';
      case MediaType.video:
        return 'Add Video';
      case MediaType.any:
        return 'Add Media';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface, // Uses your dark surface color
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      padding: EdgeInsets.fromLTRB(
        24.w,
        16.w,
        24.w,
        32.w + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40.w,
            height: 4.w,
            decoration: BoxDecoration(
              color: AppColors.onSurfaceDim,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          20.verticalSpace,

          // Title
          Text(
            _title,
            style: AppFonts.bold18.copyWith(color: AppColors.onBackground),
          ),
          24.verticalSpace,

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _SourceOption(
                  icon: Icons.photo_library_outlined,
                  label: 'Gallery',
                  onTap: () async {
                    final result =
                        await MediaPickerService.instance.pickFromGallery(type);
                    if (context.mounted) Navigator.pop(context, result);
                  },
                ),
              ),
              10.horizontalSpace,
              Expanded(
                child: _SourceOption(
                  icon: Icons.camera_alt_outlined,
                  label: type == MediaType.video ? 'Record' : 'Photo',
                  onTap: () async {
                    final captureType = type == MediaType.video
                        ? MediaType.video
                        : MediaType.image;
                    final result = await MediaPickerService.instance
                        .pickFromCamera(captureType);
                    if (context.mounted) Navigator.pop(context, result);
                  },
                ),
              ),
              if (type == MediaType.any) ...[
                10.horizontalSpace,
                Expanded(
                  child: _SourceOption(
                    icon: Icons.videocam_outlined,
                    label: 'Video',
                    onTap: () async {
                      final result = await MediaPickerService.instance
                          .pickFromCamera(MediaType.video);
                      if (context.mounted) Navigator.pop(context, result);
                    },
                  ),
                ),
              ],
            ],
          ),
          16.verticalSpace,
          Text(
            "----- or -----",
            style: AppFonts.regular14.copyWith(color: AppColors.onSurfaceMuted),
          ),
          16.verticalSpace,

          // ── From URL ──────────────────────────────────────────
          _UrlInput(type: type),
          16.verticalSpace,

          // Cancel
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: Text(
              'Cancel',
              style:
                  AppFonts.medium14.copyWith(color: AppColors.onSurfaceMuted),
            ),
          ),
        ],
      ),
    );
  }
}

class _UrlInput extends StatefulWidget {
  final MediaType type;
  const _UrlInput({required this.type});

  @override
  State<_UrlInput> createState() => _UrlInputState();
}

class _UrlInputState extends State<_UrlInput> {
  final _tc = TextEditingController();
  bool _loading = false;
  String? _errorText; // Added to track error state

  @override
  void initState() {
    super.initState();
  }

  Future<void> _autoPaste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text ?? '';
    if (text.startsWith('http://') || text.startsWith('https://')) {
      setState(() {
        _tc.text = text;
        _errorText = null; // Clear error on new paste
      });
    }
  }

  final _progress = ValueNotifier<double>(0);

  Future<void> _submit() async {
    final url = _tc.text.trim();
    if (url.isEmpty) return;

    setState(() {
      _loading = true;
      _errorText =
          null; // Clear any previous errors when starting a new request
      _progress.value = 0;
    });

    try {
      DialogService.showBarrier(dismissible: false);

      final request = http.Request('GET', Uri.parse(url));

      // Explicitly follow redirects
      request.followRedirects = true;
      request.maxRedirects = 10;

      final response = await http.Client().send(request);

      if (response.statusCode != 200) {
        closeDialog();
        throw Exception(
          'Failed to fetch (${response.statusCode})',
        );
      }

      final contentType =
          response.headers['content-type']?.split(';').first.toLowerCase() ??
              '';
      final finalUrl = response.request?.url.toString() ?? url;
      final ext = _extensionFor(contentType, finalUrl);

      final contentLength = response.contentLength ?? 0;
      final cacheDir = await getTemporaryDirectory();
      final fileName = 'url_${DateTime.now().millisecondsSinceEpoch}.$ext';
      final tempFile = File(p.join(cacheDir.path, fileName));
      final sink = tempFile.openWrite();
      final headerBytes = <int>[];
      var received = 0;

      await for (final chunk in response.stream) {
        sink.add(chunk);
        received += chunk.length;
        if (headerBytes.length < 64) {
          headerBytes.addAll(chunk.take(64 - headerBytes.length));
        }

        if (contentLength > 0) {
          _progress.value = received / contentLength;
        }
      }
      await sink.flush();
      await sink.close();

      final detectedMime =
          lookupMimeType(tempFile.path, headerBytes: headerBytes);
      final suppliedIsMedia =
          contentType.startsWith('image/') || contentType.startsWith('video/');
      final detectedIsMedia = detectedMime?.startsWith('image/') == true ||
          detectedMime?.startsWith('video/') == true;
      if (!suppliedIsMedia && !detectedIsMedia) {
        await tempFile.delete();
        throw const FormatException('The URL did not return a media file.');
      }

      final resolvedType = resolveMediaType(
        tempFile.path,
        mimeType: suppliedIsMedia ? contentType : detectedMime,
        headerBytes: headerBytes,
      );
      if (widget.type != MediaType.any && widget.type != resolvedType) {
        await tempFile.delete();
        throw const FormatException('The URL returned a different media type.');
      }

      final result = MediaPickResult.success(
        XFile(
          tempFile.path,
          mimeType: suppliedIsMedia ? contentType : detectedMime,
        ),
        resolvedType,
      );

      closeDialog();

      if (context.mounted) {
        Navigator.pop(context, result);
      }
    } catch (e, s) {
      debugPrint('URL download error: $e');
      debugPrintStack(stackTrace: s);

      // Replaced the ScaffoldMessenger with an inline error state
      setState(() {
        _loading = false;
        _errorText = 'Failed to load media. Use a direct image or video URL.';
      });
      _progress.value = 0;
      closeDialog();
    }
  }

  @override
  void dispose() {
    _tc.dispose();
    _progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AbsorbPointer(
          absorbing: _loading,
          child: TextField(
            controller: _tc,
            readOnly: true, // ← no keyboard ever
            onSubmitted: (_) => _submit(),
            style: AppFonts.medium14.copyWith(color: AppColors.onBackground),
            decoration: InputDecoration(
              hintText: 'Paste a direct media URL...',
              hintStyle:
                  AppFonts.regular14.copyWith(color: AppColors.onSurfaceMuted),
              filled: true,
              fillColor: AppColors
                  .surfaceHigh, // Replaced standard surfaceContainerHighest
              isDense: true,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.w),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide.none,
              ),
              // Optional: Highlight the border in red if there is an error
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: _errorText != null
                    ? const BorderSide(color: AppColors.error, width: 1)
                    : BorderSide.none,
              ),
              suffixIcon: _loading
                  ? Padding(
                      padding: EdgeInsets.all(10.w),
                      child: SizedBox(
                        width: 16.w,
                        height: 16.w,
                        child: const CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.primary),
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // paste button
                        IconButton(
                          icon: Icon(Icons.content_paste_rounded,
                              color: AppColors.onSurfaceMuted, size: 18.w),
                          onPressed: _autoPaste,
                        ),
                        // submit button — only show when text is not empty
                        if (_tc.text.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.check_circle_outline_rounded,
                                color: AppColors.primary),
                            onPressed: _submit,
                          ),
                      ],
                    ),
            ),
          ),
        ),

        // ── Error Label ──────────────────────────────────────────────────
        if (_errorText != null) ...[
          8.verticalSpace,
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              _errorText!,
              style: AppFonts.regular14.copyWith(color: AppColors.error),
            ),
          ),
        ],

        // progress bar — only shown when loading
        if (_loading) ...[
          8.verticalSpace,
          ValueListenableBuilder<double>(
            valueListenable: _progress,
            builder: (_, value, __) => Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4.r),
                  child: LinearProgressIndicator(
                    value: value == 0 ? null : value,
                    backgroundColor: AppColors.surfaceHigh,
                    color: AppColors.primary,
                    minHeight: 4.w,
                  ),
                ),
                4.verticalSpace,
                Text(
                  value == 0
                      ? 'Connecting...'
                      : '${(value * 100).toStringAsFixed(0)}%',
                  style: AppFonts.regular14.copyWith(
                    fontSize: 11,
                    color: AppColors.onSurfaceMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Option tile (private)
// ─────────────────────────────────────────────────────────────────────────────

String _extensionFor(String mimeType, String url) {
  const byMime = <String, String>{
    'image/jpeg': 'jpg',
    'image/png': 'png',
    'image/gif': 'gif',
    'image/webp': 'webp',
    'image/heic': 'heic',
    'video/mp4': 'mp4',
    'video/mpeg': 'mpeg',
    'video/quicktime': 'mov',
    'video/x-matroska': 'mkv',
    'video/webm': 'webm',
    'video/x-msvideo': 'avi',
    'video/x-ms-wmv': 'wmv',
  };

  final mapped = byMime[mimeType.toLowerCase()];
  if (mapped != null) return mapped;

  final urlExtension =
      p.extension(Uri.parse(url).path).replaceFirst('.', '').toLowerCase();
  if (urlExtension.isNotEmpty && urlExtension.length <= 5) {
    return urlExtension;
  }

  return mimeType.startsWith('video/') ? 'mp4' : 'jpg';
}

class _SourceOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SourceOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 20.w),
        decoration: BoxDecoration(
          color: AppColors
              .surfaceHigh, // Replaced standard surfaceContainerHighest
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 32.w, color: AppColors.primary),
            8.verticalSpace,
            Text(
              label,
              style: AppFonts.medium14.copyWith(color: AppColors.onBackground),
            ),
          ],
        ),
      ),
    );
  }
}
