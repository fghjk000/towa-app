import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../core/models/app_settings.dart';
import '../../core/models/cycle_block.dart';
import '../../core/models/schedule.dart';
import '../../core/models/shift_type.dart';
import '../../core/providers/schedule_providers.dart';

class CycleSetupScreen extends ConsumerStatefulWidget {
  const CycleSetupScreen({super.key});

  @override
  ConsumerState<CycleSetupScreen> createState() => _CycleSetupScreenState();
}

class _CycleSetupScreenState extends ConsumerState<CycleSetupScreen> {
  final _nameCtrl = TextEditingController(text: '새 일정');

  // 페인트된 날짜: DateTime(y,m,d) → shiftTypeId
  final Map<DateTime, String> _paintedDays = {};

  // 현재 보여주는 월
  late int _year;
  late int _month;

  // 현재 선택된 근무 유형
  String? _selectedShiftTypeId;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _year = now.year;
    _month = now.month;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _prevMonth() {
    setState(() {
      if (_month == 1) {
        _year--;
        _month = 12;
      } else {
        _month--;
      }
    });
  }

  void _nextMonth() {
    setState(() {
      if (_month == 12) {
        _year++;
        _month = 1;
      } else {
        _month++;
      }
    });
  }

  void _paintDay(DateTime day) {
    if (_selectedShiftTypeId == null) return;
    setState(() => _paintedDays[day] = _selectedShiftTypeId!);
  }

  /// 페인트된 날짜에서 CycleBlock 리스트 추출
  List<CycleBlock> _extractBlocks() {
    if (_paintedDays.isEmpty) return [];
    final sorted = _paintedDays.keys.toList()..sort();
    final start = sorted.first;
    final end = sorted.last;

    final blocks = <CycleBlock>[];
    String? currentId;
    int count = 0;

    for (int i = 0; i <= end.difference(start).inDays; i++) {
      final d = start.add(Duration(days: i));
      final key = DateTime(d.year, d.month, d.day);
      final typeId = _paintedDays[key] ?? 'off';

      if (typeId == currentId) {
        count++;
      } else {
        if (currentId != null) {
          blocks.add(CycleBlock(shiftTypeId: currentId, days: count));
        }
        currentId = typeId;
        count = 1;
      }
    }
    if (currentId != null) {
      blocks.add(CycleBlock(shiftTypeId: currentId, days: count));
    }
    return blocks;
  }

  Future<void> _save() async {
    if (_paintedDays.isEmpty || _nameCtrl.text.trim().isEmpty) return;
    final sorted = _paintedDays.keys.toList()..sort();
    final startDate = sorted.first;
    final blocks = _extractBlocks();

    final schedule = Schedule(
      id: const Uuid().v4(),
      name: _nameCtrl.text.trim(),
      cycleStartDate: startDate,
      cycleBlocks: blocks,
    );
    await ref.read(schedulesProvider.notifier).save(schedule);

    final settings = ref.read(appSettingsProvider);
    await ref.read(appSettingsProvider.notifier).update(
          AppSettings(
            activeScheduleId: schedule.id,
            notificationEnabled: settings.notificationEnabled,
            notificationMinutesBefore: settings.notificationMinutesBefore,
          ),
        );

    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final shiftTypes = ref.watch(shiftTypesProvider);
    if (_selectedShiftTypeId == null && shiftTypes.isNotEmpty) {
      _selectedShiftTypeId = shiftTypes.first.id;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('사이클 설정'),
        actions: [
          TextButton(
            onPressed: _paintedDays.isEmpty ? null : _save,
            child: const Text('저장'),
          ),
        ],
      ),
      body: Column(
        children: [
          // 일정 이름
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: '일정 이름',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),
          const SizedBox(height: 8),
          // 총 주기 안내
          if (_paintedDays.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildCycleSummary(),
            ),
          const SizedBox(height: 4),
          // 달력
          Expanded(
            child: _PaintableCalendar(
              year: _year,
              month: _month,
              paintedDays: _paintedDays,
              selectedShiftTypeId: _selectedShiftTypeId,
              shiftTypes: shiftTypes,
              onDayPainted: _paintDay,
              onPrevMonth: _prevMonth,
              onNextMonth: _nextMonth,
            ),
          ),
          // 근무 유형 선택 바
          _ShiftTypeBar(
            shiftTypes: shiftTypes,
            selectedId: _selectedShiftTypeId,
            onSelect: (id) => setState(() => _selectedShiftTypeId = id),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    );
  }

  Widget _buildCycleSummary() {
    final sorted = _paintedDays.keys.toList()..sort();
    final days = sorted.last.difference(sorted.first).inDays + 1;
    return Text(
      '총 $days일 주기 (${sorted.first.month}/${sorted.first.day} ~ ${sorted.last.month}/${sorted.last.day})',
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
    );
  }
}

// ─────────────────────────────────────────────
// 페인터블 달력 위젯
// ─────────────────────────────────────────────
class _PaintableCalendar extends StatelessWidget {
  final int year;
  final int month;
  final Map<DateTime, String> paintedDays;
  final String? selectedShiftTypeId;
  final List<ShiftType> shiftTypes;
  final ValueChanged<DateTime> onDayPainted;
  final VoidCallback onPrevMonth;
  final VoidCallback onNextMonth;

  static const _cellHeight = 52.0;
  static const _weekLabels = ['일', '월', '화', '수', '목', '금', '토'];

  const _PaintableCalendar({
    required this.year,
    required this.month,
    required this.paintedDays,
    required this.selectedShiftTypeId,
    required this.shiftTypes,
    required this.onDayPainted,
    required this.onPrevMonth,
    required this.onNextMonth,
  });

  int get _daysInMonth => DateTime(year, month + 1, 0).day;
  // 0=일, 1=월 ... 6=토 (DateTime.weekday: 1=월 ~ 7=일, %7 변환)
  int get _firstWeekday => DateTime(year, month, 1).weekday % 7;

  DateTime? _dayFromOffset(Offset pos, double cellWidth) {
    final col = (pos.dx / cellWidth).floor().clamp(0, 6);
    final row = (pos.dy / _cellHeight).floor();
    if (row < 0) return null;
    final dayNum = row * 7 + col - _firstWeekday + 1;
    if (dayNum < 1 || dayNum > _daysInMonth) return null;
    return DateTime(year, month, dayNum);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 월 헤더
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: onPrevMonth),
            Text('$year년 $month월',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16)),
            IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: onNextMonth),
          ],
        ),
        // 요일 라벨
        Row(
          children: _weekLabels
              .map((l) => Expanded(
                    child: Center(
                      child: Text(l,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: l == '일'
                                ? Colors.red
                                : l == '토'
                                    ? Colors.blue
                                    : null,
                          )),
                    ),
                  ))
              .toList(),
        ),
        const Divider(height: 4),
        // 날짜 그리드 (드래그 감지)
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final cellWidth = constraints.maxWidth / 7;
              return GestureDetector(
                onPanStart: (d) {
                  final day = _dayFromOffset(d.localPosition, cellWidth);
                  if (day != null) onDayPainted(day);
                },
                onPanUpdate: (d) {
                  final day = _dayFromOffset(d.localPosition, cellWidth);
                  if (day != null) onDayPainted(day);
                },
                onTapDown: (d) {
                  final day = _dayFromOffset(d.localPosition, cellWidth);
                  if (day != null) onDayPainted(day);
                },
                child: _buildGrid(cellWidth),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGrid(double cellWidth) {
    final totalCells = _firstWeekday + _daysInMonth;
    final rows = (totalCells / 7).ceil();

    return Column(
      children: List.generate(rows, (row) {
        return SizedBox(
          height: _cellHeight,
          child: Row(
            children: List.generate(7, (col) {
              final dayNum = row * 7 + col - _firstWeekday + 1;
              if (dayNum < 1 || dayNum > _daysInMonth) {
                return SizedBox(width: cellWidth);
              }
              final date = DateTime(year, month, dayNum);
              final shiftId = paintedDays[date];
              final shift = shiftId != null
                  ? shiftTypes.where((t) => t.id == shiftId).firstOrNull
                  : null;

              return SizedBox(
                width: cellWidth,
                child: _DayCell(
                  dayNum: dayNum,
                  shift: shift,
                  isWeekend: col == 0 || col == 6,
                ),
              );
            }),
          ),
        );
      }),
    );
  }
}

class _DayCell extends StatelessWidget {
  final int dayNum;
  final ShiftType? shift;
  final bool isWeekend;

  const _DayCell({
    required this.dayNum,
    required this.shift,
    required this.isWeekend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: shift != null
            ? Color(shift!.colorValue).withAlpha(180)
            : Colors.grey.withAlpha(20),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: shift != null
              ? Color(shift!.colorValue)
              : Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$dayNum',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isWeekend
                  ? (shift != null ? Colors.white : Colors.red.shade300)
                  : (shift != null ? Colors.white : null),
            ),
          ),
          if (shift != null)
            Text(
              shift!.name,
              style: const TextStyle(fontSize: 9, color: Colors.white),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// 하단 근무 유형 선택 바
// ─────────────────────────────────────────────
class _ShiftTypeBar extends StatelessWidget {
  final List<ShiftType> shiftTypes;
  final String? selectedId;
  final ValueChanged<String> onSelect;

  const _ShiftTypeBar({
    required this.shiftTypes,
    required this.selectedId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        children: shiftTypes.map((t) {
          final isSelected = t.id == selectedId;
          return GestureDetector(
            onTap: () => onSelect(t.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color:
                    Color(t.colorValue).withAlpha(isSelected ? 255 : 80),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Color(t.colorValue),
                  width: isSelected ? 2.5 : 1,
                ),
              ),
              child: Text(
                t.name,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight:
                      isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
