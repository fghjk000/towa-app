import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/models/shift_type.dart';
import '../../core/providers/schedule_providers.dart';

class ShiftTypeEditor extends ConsumerStatefulWidget {
  final ShiftType? shiftType;
  const ShiftTypeEditor({super.key, this.shiftType});

  @override
  ConsumerState<ShiftTypeEditor> createState() => _ShiftTypeEditorState();
}

class _ShiftTypeEditorState extends ConsumerState<ShiftTypeEditor> {
  late final TextEditingController _nameCtrl;
  TimeOfDay _start = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _end = const TimeOfDay(hour: 17, minute: 0);
  bool _isOff = false;

  // 간단한 색상 팔레트
  static const _colors = [
    0xFFFFEB3B, 0xFF3F51B5, 0xFFE91E63, 0xFF4CAF50,
    0xFFFF5722, 0xFF9C27B0, 0xFF00BCD4, 0xFF607D8B,
  ];
  late int _colorValue;

  @override
  void initState() {
    super.initState();
    final t = widget.shiftType;
    _nameCtrl = TextEditingController(text: t?.name ?? '');
    if (t != null) {
      _start = TimeOfDay(hour: t.startHour, minute: t.startMinute);
      _end = TimeOfDay(hour: t.endHour, minute: t.endMinute);
      _isOff = t.isOff;
      _colorValue = t.colorValue;
    } else {
      _colorValue = _colors.first;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16, right: 16, top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.shiftType == null ? '근무 유형 추가' : '근무 유형 편집',
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
                labelText: '근무 이름', border: OutlineInputBorder()),
          ),
          SwitchListTile(
            title: const Text('휴무'),
            contentPadding: EdgeInsets.zero,
            value: _isOff,
            onChanged: (v) => setState(() => _isOff = v),
          ),
          if (!_isOff)
            Row(children: [
              Expanded(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('시작'),
                  subtitle: Text(_start.format(context)),
                  onTap: () async {
                    final t = await showTimePicker(
                        context: context, initialTime: _start);
                    if (t != null) setState(() => _start = t);
                  },
                ),
              ),
              Expanded(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('종료'),
                  subtitle: Text(_end.format(context)),
                  onTap: () async {
                    final t = await showTimePicker(
                        context: context, initialTime: _end);
                    if (t != null) setState(() => _end = t);
                  },
                ),
              ),
            ]),
          // 색상 선택
          const SizedBox(height: 8),
          const Text('색상'),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            children: _colors.map((c) => GestureDetector(
              onTap: () => setState(() => _colorValue = c),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: Color(c),
                child: _colorValue == c
                    ? const Icon(Icons.check, color: Colors.white, size: 16)
                    : null,
              ),
            )).toList(),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _save,
            child: const Text('저장'),
          ),
        ],
      ),
    );
  }

  void _save() {
    if (_nameCtrl.text.trim().isEmpty) return;
    final type = ShiftType(
      id: widget.shiftType?.id ?? const Uuid().v4(),
      name: _nameCtrl.text.trim(),
      startHour: _start.hour,
      startMinute: _start.minute,
      endHour: _end.hour,
      endMinute: _end.minute,
      colorValue: _colorValue,
      isOff: _isOff,
    );
    if (widget.shiftType != null) {
      ref.read(shiftTypesProvider.notifier).update(type);
    } else {
      ref.read(shiftTypesProvider.notifier).add(type);
    }
    Navigator.pop(context);
  }
}
