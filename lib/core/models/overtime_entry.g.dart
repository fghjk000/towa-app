// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'overtime_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class OvertimeEntryAdapter extends TypeAdapter<OvertimeEntry> {
  @override
  final int typeId = 3;

  @override
  OvertimeEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return OvertimeEntry(
      id: fields[0] as String,
      date: fields[1] as DateTime,
      note: fields[2] as String?,
      startHour: fields[3] as int?,
      startMinute: fields[4] as int?,
      endHour: fields[5] as int?,
      endMinute: fields[6] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, OvertimeEntry obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.note)
      ..writeByte(3)
      ..write(obj.startHour)
      ..writeByte(4)
      ..write(obj.startMinute)
      ..writeByte(5)
      ..write(obj.endHour)
      ..writeByte(6)
      ..write(obj.endMinute);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OvertimeEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
