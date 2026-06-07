// media_source_sheet.dart
//
// Usage:
//   final result = await showMediaSourceSheet(context, type: MediaType.image);
//   if (result != null && result.isSuccess) {
//     final file = result.file!;
//   }

import 'package:flutter/material.dart';

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
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
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
                    final result = await MediaPickerService.instance
                        .pickFromGallery(type);
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
                    final result = await MediaPickerService.instance
                        .pickFromCamera(type);
                    if (context.mounted) Navigator.pop(context, result);
                  },
                ),
              ),
            ],
          ),

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