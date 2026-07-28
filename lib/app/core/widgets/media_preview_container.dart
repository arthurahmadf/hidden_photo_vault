import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;

import '../services/media_picker_service.dart';
import '../style/app_colors.dart';
import 'dark_video_player.dart';
import 'media_picker_sheet.dart';

class MediaPreviewContainer extends StatelessWidget {
  final XFile? file;
  final MediaType? mediaType;
  final MediaType pickType;
  final void Function(MediaPickResult? result) onChanged;
  final double? size;
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

  Future<void> _openPicker(BuildContext context) async {
    final result = await showMediaSourceSheet(context, type: pickType);
    if (result != null && result.isSuccess) onChanged(result);
  }

  @override
  Widget build(BuildContext context) {
    final effectiveSize = size ?? MediaQuery.of(context).size.width;
    final currentFile = file;

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(
        width: effectiveSize,
        height: effectiveSize,
        child: currentFile == null
            ? InkWell(
                onTap: () => _openPicker(context),
                child: DashedBorderContainer(
                  borderRadius: borderRadius,
                  color: AppColors.primary,
                  child: const _EmptyPreview(),
                ),
              )
            : Stack(
                fit: StackFit.expand,
                children: [
                  if (mediaType == MediaType.video)
                    DarkVideoPlayer(
                      key: ValueKey(currentFile.path),
                      sourcePath: currentFile.path,
                      compact: true,
                      fit: BoxFit.contain,
                    )
                  else
                    ColoredBox(
                      color: Colors.black,
                      child: Image.file(
                        File(currentFile.path),
                        fit: BoxFit.contain,
                        gaplessPlayback: true,
                        errorBuilder: (_, __, ___) => const _PreviewError(),
                      ),
                    ),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: _MediaBadge(
                      label: mediaType == MediaType.video
                          ? p
                              .extension(currentFile.path)
                              .replaceFirst('.', '')
                              .toUpperCase()
                          : p.extension(currentFile.path).toLowerCase() == '.gif'
                              ? 'GIF'
                              : 'IMAGE',
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Row(
                      children: [
                        _RoundAction(
                          tooltip: 'Change media',
                          icon: Icons.swap_horiz_rounded,
                          onTap: () => _openPicker(context),
                        ),
                        const SizedBox(width: 8),
                        _RoundAction(
                          tooltip: 'Remove media',
                          icon: Icons.close_rounded,
                          color: AppColors.error,
                          onTap: () => onChanged(null),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _EmptyPreview extends StatelessWidget {
  const _EmptyPreview();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppColors.surface,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_to_photos_outlined,
            size: 48,
            color: AppColors.onSurfaceMuted,
          ),
          SizedBox(height: 12),
          Text(
            'Tap to add photo, GIF, or video',
            style: TextStyle(color: AppColors.onSurface),
          ),
        ],
      ),
    );
  }
}

class _PreviewError extends StatelessWidget {
  const _PreviewError();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppColors.surface,
      child: Center(
        child: Icon(
          Icons.broken_image_outlined,
          color: AppColors.error,
          size: 40,
        ),
      ),
    );
  }
}

class _RoundAction extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  const _RoundAction({
    required this.tooltip,
    required this.icon,
    required this.onTap,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.72),
      shape: const CircleBorder(),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onTap,
        visualDensity: VisualDensity.compact,
        icon: Icon(icon, color: color, size: 20),
      ),
    );
  }
}

class _MediaBadge extends StatelessWidget {
  final String label;

  const _MediaBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.72),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

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
    this.color = AppColors.error,
    this.dashWidth = 6,
    this.dashGap = 4,
    this.strokeWidth = 1.5,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: _DashedBorderPainter(
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
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          Radius.circular(borderRadius),
        ),
      );

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
  bool shouldRepaint(_DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.borderRadius != borderRadius ||
      oldDelegate.dashWidth != dashWidth ||
      oldDelegate.dashGap != dashGap ||
      oldDelegate.strokeWidth != strokeWidth;
}
