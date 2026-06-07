// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vault_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class VaultAdapter extends TypeAdapter<Vault> {
  @override
  final int typeId = 3;

  @override
  Vault read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Vault(
      id: fields[0] as String?,
      name: fields[1] as String?,
      pinHash: fields[2] as String?,
      createdAt: fields[3] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, Vault obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.pinHash)
      ..writeByte(3)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VaultAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
