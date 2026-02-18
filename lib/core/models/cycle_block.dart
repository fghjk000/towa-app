import 'package:hive_flutter/hive_flutter.dart';

part 'cycle_block.g.dart';

@HiveType(typeId: 1)
class CycleBlock {
  @HiveField(0)
  final String shiftTypeId;
  @HiveField(1)
  final int days;

  CycleBlock({required this.shiftTypeId, required this.days});
}
