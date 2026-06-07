// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gallery_media_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class GalleryMediaAdapter extends TypeAdapter<GalleryMedia> {
  @override
  final int typeId = 4;

  @override
  GalleryMedia read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return GalleryMedia(
      id: fields[0] as String?,
      filePath: fields[1] as String?,
      thumbPath: fields[2] as String?,
      originalName: fields[3] as String?,
      mimeType: fields[4] as String?,
      fileSize: fields[5] as int?,
      importedAt: fields[6] as DateTime?,
      vaultId: fields[7] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, GalleryMedia obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.filePath)
      ..writeByte(2)
      ..write(obj.thumbPath)
      ..writeByte(3)
      ..write(obj.originalName)
      ..writeByte(4)
      ..write(obj.mimeType)
      ..writeByte(5)
      ..write(obj.fileSize)
      ..writeByte(6)
      ..write(obj.importedAt)
      ..writeByte(7)
      ..write(obj.vaultId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GalleryMediaAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
