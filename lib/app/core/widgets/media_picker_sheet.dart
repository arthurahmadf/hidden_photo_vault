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
import 'package:hidden_photo_vault/app/core/style/app_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
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
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        16,
        24,
        32 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: scheme.onSurface.withOpacity(0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Title
          Text(
            _title,
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 24),

          // Options row
          Row(
            children: [
              Expanded(
                child: _SourceOption(
                  icon: Icons.photo_library_outlined,
                  label: 'Gallery',
                  onTap: () async {
                    final result = await MediaPickerService.instance.pickFromGallery(type);
                    if (context.mounted) Navigator.pop(context, result);
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _SourceOption(
                  icon: Icons.camera_alt_outlined,
                  label: 'Camera',
                  onTap: () async {
                    final result = await MediaPickerService.instance.pickFromCamera(type);
                    if (context.mounted) Navigator.pop(context, result);
                  },
                ),
              ),
            ],
          ),
          16.verticalSpace,
          Text(
            "----- or -----",
            style: AppFonts.regular14.copyWith(color: Colors.grey),
          ),
          16.verticalSpace,
          // ── From URL ──────────────────────────────────────────
          _UrlInput(type: type),
          const SizedBox(height: 16),

          // Cancel
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: Text(
              'Cancel',
              style: textTheme.bodyMedium?.copyWith(
                color: scheme.onSurface.withOpacity(0.5),
              ),
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

  @override
  void initState() {
    super.initState();
    // _autoPaste();
  }

  Future<void> _autoPaste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text ?? '';
    if (text.startsWith('http://') || text.startsWith('https://')) {
      setState(() => _tc.text = text);
    }
  }

  final _progress = ValueNotifier<double>(0);

  Future<void> _submit() async {
    final url = _tc.text.trim();
    if (url.isEmpty) return;

    setState(() {
      _loading = true;
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
        throw Exception(
          'Failed to fetch (${response.statusCode})',
        );
      }

      final contentType = response.headers['content-type']?.toLowerCase() ?? '';

      // Determine extension from content type
      String ext;

      if (contentType.contains('png')) {
        ext = 'png';
      } else if (contentType.contains('jpeg') || contentType.contains('jpg')) {
        ext = 'jpg';
      } else if (contentType.contains('webp')) {
        ext = 'webp';
      } else if (contentType.contains('gif')) {
        ext = 'gif';
      } else {
        // Fallback to final redirected URL
        final finalUrl = response.request?.url.toString() ?? url;

        final uri = Uri.parse(finalUrl);
        final path = uri.path;

        if (path.contains('.')) {
          ext = path.split('.').last;
        } else {
          ext = 'jpg';
        }
      }

      final contentLength = response.contentLength ?? 0;
      final bytes = <int>[];

      await for (final chunk in response.stream) {
        bytes.addAll(chunk);

        if (contentLength > 0) {
          _progress.value = bytes.length / contentLength;
        }
      }

      final cacheDir = await getTemporaryDirectory();

      final fileName = 'url_${DateTime.now().millisecondsSinceEpoch}.$ext';

      final tempFile = File('${cacheDir.path}/$fileName');

      await tempFile.writeAsBytes(
        bytes,
        flush: true,
      );

      final result = MediaPickResult.success(
        XFile(tempFile.path),
        MediaType.image,
      );

      closeDialog();

      if (context.mounted) {
        Navigator.pop(context, result);
      }
    } catch (e, s) {
      debugPrint('URL download error: $e');
      debugPrintStack(stackTrace: s);

      setState(() => _loading = false);
      _progress.value = 0;

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to load image from URL\n$e',
            ),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _tc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AbsorbPointer(
          absorbing: _loading,
          child: TextField(
            controller: _tc,
            readOnly: true, // ← no keyboard ever
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              hintText: 'Paste image URL...',
              hintStyle: TextStyle(color: scheme.onSurface.withOpacity(0.35), fontSize: 13),
              filled: true,
              fillColor: scheme.surfaceContainerHighest,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              suffixIcon: _loading
                  ? Padding(
                      padding: const EdgeInsets.all(10),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: scheme.primary),
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // paste button
                        IconButton(
                          icon: Icon(Icons.content_paste_rounded,
                              color: scheme.onSurface.withOpacity(0.5), size: 18),
                          onPressed: _autoPaste,
                        ),
                        // submit button — only show when text is not empty
                        if (_tc.text.isNotEmpty)
                          IconButton(
                            icon: Icon(Icons.check_circle_outline_rounded, color: scheme.primary),
                            onPressed: _submit,
                          ),
                      ],
                    ),
            ),
          ),
        ),

        // progress bar — only shown when loading
        if (_loading) ...[
          const SizedBox(height: 8),
          ValueListenableBuilder<double>(
            valueListenable: _progress,
            builder: (_, value, __) => Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: value == 0 ? null : value,
                    backgroundColor: scheme.surfaceContainerHighest,
                    color: scheme.primary,
                    minHeight: 4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value == 0 ? 'Connecting...' : '${(value * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 11,
                    color: scheme.onSurface.withOpacity(0.5),
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
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 32, color: scheme.primary),
            const SizedBox(height: 8),
            Text(
              label,
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
