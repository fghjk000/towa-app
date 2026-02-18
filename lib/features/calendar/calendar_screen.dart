import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:uuid/uuid.dart';
import '../../core/models/overtime_entry.dart';
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
  final List<OvertimeEntry> _overtimes = [];

  @override
  Widget build(BuildContext context) {
    final schedule = ref.watch(activeScheduleProvider);
    final shiftTypes = ref.watch(shiftTypesProvider);

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
              _showOvertimeSheet(context, selected);
            },
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, day, focusedDay) {
                if (schedule == null) return null;
                final id =
                    ShiftCalculator.getShiftTypeIdForDate(schedule, day);
                final shift =
                    shiftTypes.where((t) => t.id == id).firstOrNull;
                if (shift == null) return null;
                return _DayCell(day: day, shift: shift);
              },
              todayBuilder: (context, day, focusedDay) {
                if (schedule == null) return null;
                final id =
                    ShiftCalculator.getShiftTypeIdForDate(schedule, day);
                final shift =
                    shiftTypes.where((t) => t.id == id).firstOrNull;
                if (shift == null) return null;
                return _DayCell(day: day, shift: shift, isToday: true);
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showOvertimeSheet(BuildContext context, DateTime date) {
    final hasOvertime = _overtimes.any(
        (o) => _sameDay(o.date, date));
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _OvertimeSheet(
        date: date,
        existing: hasOvertime
            ? _overtimes.firstWhere((o) => _sameDay(o.date, date))
            : null,
        onSave: (entry) {
          setState(() {
            _overtimes.removeWhere((o) => _sameDay(o.date, date));
            _overtimes.add(entry);
          });
        },
        onDelete: () {
          setState(() =>
              _overtimes.removeWhere((o) => _sameDay(o.date, date)));
        },
      ),
    );
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
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

class _OvertimeSheet extends StatefulWidget {
  final DateTime date;
  final OvertimeEntry? existing;
  final ValueChanged<OvertimeEntry> onSave;
  final VoidCallback onDelete;

  const _OvertimeSheet({
    required this.date,
    required this.onSave,
    required this.onDelete,
    this.existing,
  });

  @override
  State<_OvertimeSheet> createState() => _OvertimeSheetState();
}

class _OvertimeSheetState extends State<_OvertimeSheet> {
  late TextEditingController _noteCtrl;
  TimeOfDay? _start;
  TimeOfDay? _end;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _noteCtrl = TextEditingController(text: e?.note ?? '');
    if (e != null) {
      if (e.startHour != null) {
        _start = TimeOfDay(hour: e.startHour!, minute: e.startMinute ?? 0);
      }
      if (e.endHour != null) {
        _end = TimeOfDay(hour: e.endHour!, minute: e.endMinute ?? 0);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.date;
    return Padding(
      padding: EdgeInsets.only(
        left: 16, right: 16, top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '특근 등록 — ${d.year}/${d.month}/${d.day}',
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _noteCtrl,
            decoration: const InputDecoration(
              labelText: '메모 (선택)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: ListTile(
                title: Text(_start == null
                    ? '시작 시간'
                    : _start!.format(context)),
                leading: const Icon(Icons.access_time),
                onTap: () async {
                  final t = await showTimePicker(
                      context: context,
                      initialTime: _start ?? TimeOfDay.now());
                  if (t != null) setState(() => _start = t);
                },
              ),
            ),
            Expanded(
              child: ListTile(
                title: Text(
                    _end == null ? '종료 시간' : _end!.format(context)),
                leading: const Icon(Icons.access_time_filled),
                onTap: () async {
                  final t = await showTimePicker(
                      context: context,
                      initialTime: _end ?? TimeOfDay.now());
                  if (t != null) setState(() => _end = t);
                },
              ),
            ),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            if (widget.existing != null)
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    widget.onDelete();
                    Navigator.pop(context);
                  },
                  child: const Text('삭제'),
                ),
              ),
            if (widget.existing != null) const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  widget.onSave(OvertimeEntry(
                    id: widget.existing?.id ?? const Uuid().v4(),
                    date: widget.date,
                    note: _noteCtrl.text.isEmpty ? null : _noteCtrl.text,
                    startHour: _start?.hour,
                    startMinute: _start?.minute,
                    endHour: _end?.hour,
                    endMinute: _end?.minute,
                  ));
                  Navigator.pop(context);
                },
                child: const Text('저장'),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}
