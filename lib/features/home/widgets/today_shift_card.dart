import 'package:flutter/material.dart';
import '../../../core/models/shift_type.dart';

class TodayShiftCard extends StatelessWidget {
  final ShiftType shiftType;
  final bool hasOvertime;

  const TodayShiftCard({
    super.key,
    required this.shiftType,
    this.hasOvertime = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      color: Color(shiftType.colorValue).withAlpha(38),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              shiftType.name,
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: Color(shiftType.colorValue),
                    fontWeight: FontWeight.bold,
                  ),
            ),
            if (!shiftType.isOff) ...[
              const SizedBox(height: 4),
              Text(
                '${_fmt(shiftType.startHour, shiftType.startMinute)}'
                ' ~ ${_fmt(shiftType.endHour, shiftType.endMinute)}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
            if (hasOvertime) ...[
              const SizedBox(height: 8),
              const Chip(label: Text('특근 있음')),
            ],
          ],
        ),
      ),
    );
  }

  String _fmt(int h, int m) =>
      '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
}
