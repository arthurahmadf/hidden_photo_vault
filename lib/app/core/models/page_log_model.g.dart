// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'page_log_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PageLogAdapter extends TypeAdapter<PageLog> {
  @override
  final int typeId = 12;

  @override
  PageLog read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PageLog(
      pageId: fields[0] as String?,
      userId: fields[1] as int?,
      openedAt: fields[2] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, PageLog obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.pageId)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.openedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PageLogAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
