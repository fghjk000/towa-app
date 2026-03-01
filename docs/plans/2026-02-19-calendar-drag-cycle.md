# Calendar Drag Cycle Setup — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 달력에서 드래그하여 근무 사이클을 정의하고, 개별 날짜를 탭으로 수정할 수 있게 한다.

**Architecture:** 커스텀 달력 그리드(7열 Row/Column)를 GestureDetector로 감싸 드래그 히트테스트를 수학적으로 처리. DateOverride 모델로 개별 날짜 예외를 Hive에 저장. ShiftCalculator가 오버라이드를 우선 반환.

**Tech Stack:** Flutter, Riverpod, Hive/hive_flutter, build_runner

---

## Task 1: DateOverride 모델 생성

**Files:**
- Create: `lib/core/models/date_override.dart`
- Modify: `lib/main.dart`

**Step 1: date_override.dart 작성**

```dart
import 'package:hive_flutter/hive_flutter.dart';
part 'date_override.g.dart';

@HiveType(typeId: 5)
class DateOverride {
  @HiveField(0)
  final String scheduleId;

  @HiveField(1)
  final DateTime date; // midnight normalized (DateTime(y,m,d))

  @HiveField(2)
  final String shiftTypeId;

  DateOverride({
    required this.scheduleId,
    required this.date,
    required this.shiftTypeId,
  });
}
```

**Step 2: build_runner 실행**

```bash
cd /Users/kimhanseop/Desktop/TodayWork/shift_widget_app
dart run build_runner build --delete-conflicting-outputs
```

확인: `lib/core/models/date_override.g.dart` 생성됨

**Step 3: main.dart에 어댑터 등록 및 import 추가**

`lib/main.dart` 수정:
- import 추가: `import 'core/models/date_override.dart';`
- `Hive.registerAdapter(AppSettingsAdapter());` 바로 뒤에 추가:
  ```dart
  Hive.registerAdapter(DateOverrideAdapter());
  ```

**Step 4: 커밋**

```bash
git add lib/core/models/date_override.dart lib/core/models/date_override.g.dart lib/main.dart
git commit -m "feat: add DateOverride Hive model (typeId 5)"
```

---

## Task 2: Override Repository + Provider

**Files:**
- Create: `lib/core/repositories/override_repository.dart`
- Modify: `lib/core/providers/schedule_providers.dart`
- Modify: `lib/main.dart`

**Step 1: override_repository.dart 작성**

```dart
import 'package:hive_flutter/hive_flutter.dart';
import '../models/date_override.dart';

class OverrideRepository {
  static const _boxName = 'dateOverrides';
  late Box<DateOverride> _box;

  Future<void> init() async {
    if (Hive.isBoxOpen(_boxName)) {
      _box = Hive.box<DateOverride>(_boxName);
    } else {
      _box = await Hive.openBox<DateOverride>(_boxName);
    }
  }

  List<DateOverride> getForSchedule(String scheduleId) =>
      _box.values.where((o) => o.scheduleId == scheduleId).toList();

  Future<void> save(DateOverride override) async {
    // 같은 날짜+일정의 기존 항목 삭제 후 저장
    final key = '${override.scheduleId}_${override.date.millisecondsSinceEpoch}';
    await _box.put(key, override);
  }

  Future<void> delete(String scheduleId, DateTime date) async {
    final key = '${scheduleId}_${date.millisecondsSinceEpoch}';
    await _box.delete(key);
  }

  Future<void> deleteAllForSchedule(String scheduleId) async {
    final keys = _box.values
        .where((o) => o.scheduleId == scheduleId)
        .map((_) => '${scheduleId}_${_.date.millisecondsSinceEpoch}')
        .toList();
    await _box.deleteAll(keys);
  }
}
```

**Step 2: schedule_providers.dart에 overrideRepositoryProvider + overridesProvider 추가**

`lib/core/providers/schedule_providers.dart` 수정:

파일 상단 imports에 추가:
```dart
import '../models/date_override.dart';
import '../repositories/override_repository.dart';
```

기존 providers 아래에 추가:
```dart
final overrideRepositoryProvider = Provider<OverrideRepository>((ref) {
  throw UnimplementedError('main에서 override 필요');
});

// 활성 일정의 오버라이드 목록
final overridesProvider =
    StateNotifierProvider<OverridesNotifier, List<DateOverride>>((ref) {
  final settings = ref.watch(appSettingsProvider);
  return OverridesNotifier(
    ref.watch(overrideRepositoryProvider),
    settings.activeScheduleId,
  );
});

class OverridesNotifier extends StateNotifier<List<DateOverride>> {
  final OverrideRepository _repo;
  final String? _scheduleId;

  OverridesNotifier(this._repo, this._scheduleId)
      : super(_scheduleId != null ? _repo.getForSchedule(_scheduleId) : []);

  Future<void> saveOverride(DateOverride override) async {
    await _repo.save(override);
    if (_scheduleId != null) {
      state = _repo.getForSchedule(_scheduleId!);
    }
  }

  Future<void> deleteOverride(String scheduleId, DateTime date) async {
    await _repo.delete(scheduleId, date);
    if (_scheduleId != null) {
      state = _repo.getForSchedule(_scheduleId!);
    }
  }
}
```

**Step 3: main.dart에 overrideRepo 초기화 및 provider 오버라이드**

`lib/main.dart` 수정:
- import 추가: `import 'core/repositories/override_repository.dart';`
- `await scheduleRepo.init();` 뒤에 추가:
  ```dart
  final overrideRepo = OverrideRepository();
  await overrideRepo.init();
  ```
- `ProviderScope` overrides에 추가:
  ```dart
  overrideRepositoryProvider.overrideWithValue(overrideRepo),
  ```

**Step 4: 커밋**

```bash
git add lib/core/repositories/override_repository.dart lib/core/providers/schedule_providers.dart lib/main.dart
git commit -m "feat: add OverrideRepository and overridesProvider"
```

---

## Task 3: ShiftCalculator에 오버라이드 적용

**Files:**
- Modify: `lib/core/services/shift_calculator.dart`

**Step 1: getShiftTypeIdForDate에 overrides 파라미터 추가**

`lib/core/services/shift_calculator.dart` 전체 교체:

```dart
import '../models/date_override.dart';
import '../models/schedule.dart';

class ShiftCalculator {
  /// overrides가 주어지면 해당 날짜에 override가 있을 경우 우선 반환.
  static String? getShiftTypeIdForDate(
    Schedule schedule,
    DateTime date, {
    List<DateOverride> overrides = const [],
  }) {
    final target = DateTime(date.year, date.month, date.day);

    // 오버라이드 우선 확인
    final override = overrides
        .where((o) =>
            o.scheduleId == schedule.id &&
            o.date.year == target.year &&
            o.date.month == target.month &&
            o.date.day == target.day)
        .firstOrNull;
    if (override != null) return override.shiftTypeId;

    // 기존 사이클 계산
    final start = DateTime(
      schedule.cycleStartDate.year,
      schedule.cycleStartDate.month,
      schedule.cycleStartDate.day,
    );
    final dayIndex = target.difference(start).inDays;
    if (dayIndex < 0) return null;

    final totalDays = schedule.totalDays;
    if (totalDays == 0) return null;

    final positionInCycle = dayIndex % totalDays;
    int cursor = 0;
    for (final block in schedule.cycleBlocks) {
      cursor += block.days;
      if (positionInCycle < cursor) return block.shiftTypeId;
    }
    return null;
  }
}
```

**Step 2: 커밋**

```bash
git add lib/core/services/shift_calculator.dart
git commit -m "feat: ShiftCalculator supports DateOverride priority"
```

---

## Task 4: CalendarScreen — 탭으로 근무 유형 변경

**Files:**
- Modify: `lib/features/calendar/calendar_screen.dart`

**Step 1: calendar_screen.dart 수정**

`_CalendarScreenState.build()` 내 `ShiftCalculator.getShiftTypeIdForDate` 호출 2곳에 overrides 파라미터 추가.

`build()` 메서드 상단에 추가:
```dart
final overrides = ref.watch(overridesProvider);
```

두 곳의 `ShiftCalculator.getShiftTypeIdForDate(schedule, day)` 호출을:
```dart
ShiftCalculator.getShiftTypeIdForDate(schedule, day, overrides: overrides)
```
로 교체.

**Step 2: onDaySelected를 근무 유형 변경 시트로 교체**

`onDaySelected` 콜백을:
```dart
onDaySelected: (selected, focused) {
  setState(() => _focusedDay = focused);
  _showShiftOverrideSheet(context, selected);
},
```

**Step 3: _showShiftOverrideSheet 메서드 추가 (기존 _showOvertimeSheet 제거)**

```dart
void _showShiftOverrideSheet(BuildContext context, DateTime date) {
  final schedule = ref.read(activeScheduleProvider);
  if (schedule == null) return;
  final shiftTypes = ref.read(shiftTypesProvider);
  final overrides = ref.read(overridesProvider);

  final currentId = ShiftCalculator.getShiftTypeIdForDate(
      schedule, date, overrides: overrides);
  final hasOverride = overrides.any((o) =>
      o.scheduleId == schedule.id &&
      o.date.year == date.year &&
      o.date.month == date.month &&
      o.date.day == date.day);

  showModalBottomSheet(
    context: context,
    builder: (ctx) => _ShiftOverrideSheet(
      date: date,
      currentShiftTypeId: currentId,
      hasOverride: hasOverride,
      shiftTypes: shiftTypes,
      onSelect: (shiftTypeId) async {
        await ref.read(overridesProvider.notifier).saveOverride(
              DateOverride(
                scheduleId: schedule.id,
                date: DateTime(date.year, date.month, date.day),
                shiftTypeId: shiftTypeId,
              ),
            );
      },
      onReset: hasOverride
          ? () async {
              await ref
                  .read(overridesProvider.notifier)
                  .deleteOverride(schedule.id,
                      DateTime(date.year, date.month, date.day));
            }
          : null,
    ),
  );
}
```

**Step 4: _ShiftOverrideSheet 위젯 추가 (파일 하단)**

기존 `_OvertimeSheet` 관련 클래스를 모두 제거하고 아래로 교체:

```dart
class _ShiftOverrideSheet extends StatelessWidget {
  final DateTime date;
  final String? currentShiftTypeId;
  final bool hasOverride;
  final List<ShiftType> shiftTypes;
  final ValueChanged<String> onSelect;
  final VoidCallback? onReset;

  const _ShiftOverrideSheet({
    required this.date,
    required this.currentShiftTypeId,
    required this.hasOverride,
    required this.shiftTypes,
    required this.onSelect,
    this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${date.year}/${date.month}/${date.day} 근무 유형 변경',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          if (hasOverride)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('* 수동 변경됨',
                  style: TextStyle(
                      fontSize: 12, color: Colors.orange.shade700)),
            ),
          const SizedBox(height: 16),
          ...shiftTypes.map((t) => ListTile(
                leading: CircleAvatar(backgroundColor: Color(t.colorValue)),
                title: Text(t.name),
                trailing: t.id == currentShiftTypeId
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
                onTap: () {
                  onSelect(t.id);
                  Navigator.pop(context);
                },
              )),
          if (onReset != null) ...[
            const Divider(),
            ListTile(
              leading: const Icon(Icons.refresh, color: Colors.grey),
              title: const Text('사이클 기본값으로 되돌리기'),
              onTap: () {
                onReset!();
                Navigator.pop(context);
              },
            ),
          ],
        ],
      ),
    );
  }
}
```

**Step 5: import 정리**

`calendar_screen.dart` 상단에 추가:
```dart
import '../../core/models/date_override.dart';
```

`uuid`와 `overtime_entry` import는 더 이상 필요 없으면 제거.

**Step 6: 커밋**

```bash
git add lib/features/calendar/calendar_screen.dart
git commit -m "feat: calendar day tap shows shift type override sheet"
```

---

## Task 5: CycleSetupScreen — 달력 페인트 UI 전체 재작성

**Files:**
- Rewrite: `lib/features/cycle/cycle_setup_screen.dart`

**Step 1: cycle_setup_screen.dart 전체 교체**

```dart
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
      if (_month == 1) { _year--; _month = 12; }
      else { _month--; }
    });
  }

  void _nextMonth() {
    setState(() {
      if (_month == 12) { _year++; _month = 1; }
      else { _month++; }
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
          blocks.add(CycleBlock(shiftTypeId: currentId!, days: count));
        }
        currentId = typeId;
        count = 1;
      }
    }
    if (currentId != null) {
      blocks.add(CycleBlock(shiftTypeId: currentId!, days: count));
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
              child: _buildCycleSummary(shiftTypes),
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

  Widget _buildCycleSummary(List<ShiftType> shiftTypes) {
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
  // 0=일, 1=월 ... 6=토 (DateTime.weekday: 1=월 ~ 7=일)
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
            IconButton(icon: const Icon(Icons.chevron_left), onPressed: onPrevMonth),
            Text('$year년 $month월',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            IconButton(icon: const Icon(Icons.chevron_right), onPressed: onNextMonth),
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
        LayoutBuilder(
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
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Color(t.colorValue).withAlpha(isSelected ? 255 : 80),
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
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
```

**Step 2: 커밋**

```bash
git add lib/features/cycle/cycle_setup_screen.dart
git commit -m "feat: rewrite CycleSetupScreen with calendar paint drag UI"
```

---

## Task 6: 전체 빌드 확인 및 최종 커밋

**Step 1: flutter analyze 실행**

```bash
cd /Users/kimhanseop/Desktop/TodayWork/shift_widget_app
flutter analyze
```

오류가 없으면 다음 단계로. 있으면 오류 메시지 기반으로 수정.

**Step 2: 사용하지 않는 import 정리**

`calendar_screen.dart`에서 더 이상 쓰지 않는:
- `import 'package:uuid/uuid.dart';`
- `import '../../core/models/overtime_entry.dart';`
- `import 'package:go_router/go_router.dart';`

를 확인 후 제거.

**Step 3: iPad에 배포 확인**

```bash
bash run_ios.sh
```

앱을 열고 다음 시나리오 확인:
1. 설정 → 새 일정 추가 → 사이클 설정 화면 열림
2. 하단 근무 유형 탭 선택 → 달력 날짜 드래그 → 색칠됨
3. 월 이동 버튼으로 다음 달 이동 → 다른 날짜도 칠 수 있음
4. 저장 → 홈/캘린더에서 사이클 반영됨
5. 캘린더 화면에서 날짜 탭 → 근무 유형 변경 시트 표시
6. 유형 선택 → 해당 날짜만 변경됨, 사이클 유지

**Step 4: 최종 커밋**

```bash
git add -A
git commit -m "feat: calendar drag cycle setup + per-day shift override complete"
```

---

## 파일 변경 요약

| 파일 | 작업 |
|------|------|
| `lib/core/models/date_override.dart` | 신규 생성 |
| `lib/core/models/date_override.g.dart` | build_runner 자동 생성 |
| `lib/core/repositories/override_repository.dart` | 신규 생성 |
| `lib/core/providers/schedule_providers.dart` | overridesProvider 추가 |
| `lib/core/services/shift_calculator.dart` | overrides 파라미터 추가 |
| `lib/features/cycle/cycle_setup_screen.dart` | 전체 재작성 |
| `lib/features/calendar/calendar_screen.dart` | 탭→오버라이드 시트 교체 |
| `lib/main.dart` | adapter 등록, repo 초기화, provider override |
