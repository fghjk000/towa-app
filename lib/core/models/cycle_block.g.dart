// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cycle_block.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CycleBlockAdapter extends TypeAdapter<CycleBlock> {
  @override
  final int typeId = 1;

  @override
  CycleBlock read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CycleBlock(
      shiftTypeId: fields[0] as String,
      days: fields[1] as int,
    );
  }

  @override
  void write(BinaryWriter writer, CycleBlock obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.shiftTypeId)
      ..writeByte(1)
      ..write(obj.days);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CycleBlockAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
