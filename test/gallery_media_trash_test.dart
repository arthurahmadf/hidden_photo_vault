import 'package:flutter_test/flutter_test.dart';
import 'package:hidden_photo_vault/app/data/models/gallery_media_model.dart';

void main() {
  test('moving media to trash preserves encrypted file metadata', () {
    final media = GalleryMedia(
      id: 'media-1',
      filePath: '/vault/media-1.enc',
      thumbPath: '/vault/media-1_thumb.enc',
      vaultId: 'vault-1',
      fileSize: 42,
    );
    final deletedAt = DateTime(2026, 7, 28);

    final trashed = media.copyWith(deletedAt: deletedAt);

    expect(trashed.deletedAt, deletedAt);
    expect(trashed.filePath, media.filePath);
    expect(trashed.thumbPath, media.thumbPath);
    expect(trashed.vaultId, media.vaultId);
  });

  test('restoring media clears only its trash timestamp', () {
    final media = GalleryMedia(
      id: 'media-1',
      filePath: '/vault/media-1.enc',
      deletedAt: DateTime(2026, 7, 28),
    );

    final restored = media.copyWith(restore: true);

    expect(restored.deletedAt, isNull);
    expect(restored.filePath, media.filePath);
  });
}
