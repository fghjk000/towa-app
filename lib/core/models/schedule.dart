import 'package:hive_flutter/hive_flutter.dart';
import 'cycle_block.dart';

part 'schedule.g.dart';

@HiveType(typeId: 2)
class Schedule {
  @HiveField(0)
  final String id;
  @HiveField(1)
  String name;
  @HiveField(2)
  DateTime cycleStartDate;
  @HiveField(3)
  List<CycleBlock> cycleBlocks;

  Schedule({
    required this.id,
    required this.name,
    required this.cycleStartDate,
    required this.cycleBlocks,
  });

  int get totalDays =>
      cycleBlocks.fold(0, (sum, b) => sum + b.days);
}
