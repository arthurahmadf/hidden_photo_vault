// media_preview_container.dart
//
// Self-contained preview widget — handles picking and clearing internally.
//
// Empty  → tap → opens media source sheet → calls onChanged(result)
// Filled → tap → opens action sheet (Change / Remove)
//              → Change: opens source sheet → calls onChanged(result)
//              → Remove: calls onChanged(null)
//
// Usage:
//   MediaPreviewContainer(
//     file: _file,
//     mediaType: _type,
//     pickType: MediaType.any,
//     onChanged: (result) {
//       setState(() {
//         _file = result?.file;
//         _type = result?.resolvedType;
//       });
//     },
//   )

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/media_picker_service.dart';
import 'media_picker_sheet.dart';


class MediaPreviewContainer extends StatelessWidget {
  /// Current file. Null = empty state.
  final XFile? file;

  /// Resolved type of [file]. Used to render the correct preview.
  final MediaType? mediaType;

  /// What media type to allow when picking. Defaults to [MediaType.any].
  final MediaType pickType;

  /// Called whenever the media changes.
  /// Receives [MediaPickResult] on pick, or null when user removes.
  final void Function(MediaPickResult? result) onChanged;

  /// Side length of the square. Defaults to full available width.
  final double? size;

  /// Corner radius. Defaults to 16.
  final double borderRadius;

  const MediaPreviewContainer({
    super.key,
    this.file,
    this.mediaType,
    this.pickType = MediaType.any,
    required this.onChanged,
    this.size,
    this.borderRadius = 16,
  });

  // ── Tap handlers ────────────────────────────────────────────────────────────

  Future<void> _onTap(BuildContext context) async {
    if (file == null) {
      await _openPicker(context);
    } else {
      await _openActionSheet(context);
    }
  }

  Future<void> _openPicker(BuildContext context) async {
    final result = await showMediaSourceSheet(context, type: pickType);
    if (result != null && result.isSuccess) {
      onChanged(result);
    }
  }

  Future<void> _openActionSheet(BuildContext context) async {
    final action = await showModalBottomSheet<_MediaAction>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _MediaActionSheet(),
    );

    if (action == null) return;
    if (!context.mounted) return;

    switch (action) {
      case _MediaAction.change:
        await _openPicker(context);
      case _MediaAction.remove:
        onChanged(null);
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final effectiveSize = size ?? MediaQuery.of(context).size.width;

    return GestureDetector(
      onTap: () => _onTap(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: SizedBox(
          width: effectiveSize,
          height: effectiveSize,
          child: file == null
              ? _Placeholder(scheme: scheme, borderRadius: borderRadius)
              : _Preview(
                  file: file!,
                  mediaType: mediaType ?? MediaType.image,
                  scheme: scheme,
                ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Action sheet (Change / Remove)
// ─────────────────────────────────────────────────────────────────────────────

enum _MediaAction { change, remove }

class _MediaActionSheet extends StatelessWidget {
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

          // Options row — same style as media_source_sheet
          Row(
            children: [
              Expanded(
                child: _ActionOption(
                  icon: Icons.swap_horiz_rounded,
                  label: 'Change',
                  onTap: () => Navigator.pop(context, _MediaAction.change),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _ActionOption(
                  icon: Icons.delete_outline_rounded,
                  label: 'Remove',
                  color: scheme.error,
                  onTap: () => Navigator.pop(context, _MediaAction.remove),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

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

class _ActionOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _ActionOption({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final effectiveColor = color ?? scheme.primary;

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
            Icon(icon, size: 32, color: effectiveColor),
            const SizedBox(height: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: effectiveColor,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty placeholder
// ─────────────────────────────────────────────────────────────────────────────

class _Placeholder extends StatelessWidget {
  final ColorScheme scheme;
  final double borderRadius;
  const _Placeholder({required this.scheme, required this.borderRadius});

  @override
  Widget build(BuildContext context) {
    return DashedBorderContainer(
      borderRadius: borderRadius,
      color: scheme.outline.withOpacity(0.4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_photo_alternate_outlined,
            size: 48,
            color: scheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 12),
          Text(
            'Tap to add media',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurface.withOpacity(0.35),
                ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Filled preview
// ─────────────────────────────────────────────────────────────────────────────

class _Preview extends StatelessWidget {
  final XFile file;
  final MediaType mediaType;
  final ColorScheme scheme;

  const _Preview({
    required this.file,
    required this.mediaType,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (mediaType == MediaType.image)
          Image.file(File(file.path), fit: BoxFit.cover)
        else
          Container(
            color: scheme.surfaceContainerHighest,
            child: Center(
              child: Icon(
                Icons.play_circle_outline_rounded,
                size: 64,
                color: scheme.onSurface.withOpacity(0.4),
              ),
            ),
          ),

        // Bottom hint overlay
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withOpacity(0.55),
                  Colors.transparent,
                ],
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.touch_app_outlined, size: 14, color: Colors.white.withOpacity(0.8)),
                const SizedBox(width: 4),
                Text(
                  'Tap to change or remove',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.white.withOpacity(0.8),
                      ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dashed border painter
// ─────────────────────────────────────────────────────────────────────────────

class DashedBorderContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final Color color;
  final double dashWidth;
  final double dashGap;
  final double strokeWidth;

  const DashedBorderContainer({
    super.key,
    required this.child,
    this.borderRadius = 16,
    this.color = Colors.grey,
    this.dashWidth = 6,
    this.dashGap = 4,
    this.strokeWidth = 1.5,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(
        color: color,
        borderRadius: borderRadius,
        dashWidth: dashWidth,
        dashGap: dashGap,
        strokeWidth: strokeWidth,
      ),
      child: child,
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double borderRadius;
  final double dashWidth;
  final double dashGap;
  final double strokeWidth;

  _DashedBorderPainter({
    required this.color,
    required this.borderRadius,
    required this.dashWidth,
    required this.dashGap,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Radius.circular(borderRadius),
      ));

    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final next = (distance + dashWidth).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance += dashWidth + dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) =>
      old.color != color ||
      old.borderRadius != borderRadius ||
      old.strokeWidth != strokeWidth;
}