// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_setting_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AppSettingAdapter extends TypeAdapter<AppSetting> {
  @override
  final int typeId = 5;

  @override
  AppSetting read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AppSetting(
      gridItemCount: fields[0] as int?,
      preferTaggedView: fields[1] as bool,
      exportDir: fields[2] as String,
      lastBackupAt: fields[3] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, AppSetting obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.gridItemCount)
      ..writeByte(1)
      ..write(obj.preferTaggedView)
      ..writeByte(2)
      ..write(obj.exportDir)
      ..writeByte(3)
      ..write(obj.lastBackupAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppSettingAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
