import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../core/models/date_override.dart';
import '../../core/models/shift_type.dart';
import '../../core/providers/schedule_providers.dart';
import '../../core/services/shift_calculator.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final schedule = ref.watch(activeScheduleProvider);
    final shiftTypes = ref.watch(shiftTypesProvider);
    final overrides = ref.watch(overridesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('캘린더'),
        actions: [
          TextButton(
            onPressed: () => context.push('/cycle-setup'),
            child: const Text('사이클 설정'),
          ),
        ],
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime(2020),
            lastDay: DateTime(2030),
            focusedDay: _focusedDay,
            onPageChanged: (day) => setState(() => _focusedDay = day),
            onDaySelected: (selected, focused) {
              setState(() => _focusedDay = focused);
              if (schedule != null) {
                _showShiftOverrideSheet(context, selected, schedule.id, shiftTypes, overrides);
              }
            },
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, day, focusedDay) {
                if (schedule == null) return null;
                final id = ShiftCalculator.getShiftTypeIdForDate(
                    schedule, day, overrides: overrides);
                final shift = shiftTypes.where((t) => t.id == id).firstOrNull;
                if (shift == null) return null;
                return _DayCell(day: day, shift: shift);
              },
              todayBuilder: (context, day, focusedDay) {
                if (schedule == null) return null;
                final id = ShiftCalculator.getShiftTypeIdForDate(
                    schedule, day, overrides: overrides);
                final shift = shiftTypes.where((t) => t.id == id).firstOrNull;
                if (shift == null) return null;
                return _DayCell(day: day, shift: shift, isToday: true);
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showShiftOverrideSheet(
    BuildContext context,
    DateTime date,
    String scheduleId,
    List<ShiftType> shiftTypes,
    List<DateOverride> overrides,
  ) {
    final schedule = ref.read(activeScheduleProvider);
    if (schedule == null) return;

    final currentId = ShiftCalculator.getShiftTypeIdForDate(
        schedule, date, overrides: overrides);
    final hasOverride = overrides.any((o) =>
        o.scheduleId == scheduleId &&
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
                  scheduleId: scheduleId,
                  date: DateTime(date.year, date.month, date.day),
                  shiftTypeId: shiftTypeId,
                ),
              );
        },
        onReset: hasOverride
            ? () async {
                await ref.read(overridesProvider.notifier).deleteOverride(
                      scheduleId,
                      DateTime(date.year, date.month, date.day),
                    );
              }
            : null,
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  final DateTime day;
  final ShiftType shift;
  final bool isToday;

  const _DayCell({
    required this.day,
    required this.shift,
    this.isToday = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Color(shift.colorValue).withAlpha(isToday ? 100 : 50),
        borderRadius: BorderRadius.circular(8),
        border: isToday
            ? Border.all(color: Color(shift.colorValue), width: 2)
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('${day.day}',
              style: TextStyle(
                  fontWeight:
                      isToday ? FontWeight.bold : FontWeight.normal)),
          Text(shift.name,
              style: const TextStyle(fontSize: 9)),
        ],
      ),
    );
  }
}

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
