// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'date_override.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DateOverrideAdapter extends TypeAdapter<DateOverride> {
  @override
  final int typeId = 5;

  @override
  DateOverride read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DateOverride(
      scheduleId: fields[0] as String,
      date: fields[1] as DateTime,
      shiftTypeId: fields[2] as String,
    );
  }

  @override
  void write(BinaryWriter writer, DateOverride obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.scheduleId)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.shiftTypeId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DateOverrideAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
