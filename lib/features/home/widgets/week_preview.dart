import 'package:flutter/material.dart';
import '../../../core/models/shift_type.dart';

class WeekPreview extends StatelessWidget {
  final Map<DateTime, ShiftType?> weekData;

  const WeekPreview({super.key, required this.weekData});

  @override
  Widget build(BuildContext context) {
    const dayLabels = ['일', '월', '화', '수', '목', '금', '토'];
    final sorted = weekData.keys.toList()..sort();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: sorted.map((date) {
        final shift = weekData[date];
        final initial = shift?.name.isNotEmpty == true
            ? shift!.name.substring(0, 1)
            : '-';
        return Column(
          children: [
            Text(
              dayLabels[date.weekday % 7],
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 4),
            CircleAvatar(
              radius: 18,
              backgroundColor: shift != null
                  ? Color(shift.colorValue)
                  : Colors.grey.shade300,
              child: Text(
                initial,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}
