import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/models/shift_type.dart';
import '../../core/providers/schedule_providers.dart';
import '../../app_widget_observer.dart';

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
                  subtitle: Text(_fmt(_start)),
                  onTap: () async {
                    final t = await _pickTime(context, _start);
                    if (t != null) setState(() => _start = t);
                  },
                ),
              ),
              Expanded(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('종료'),
                  subtitle: Text(_fmt(_end)),
                  onTap: () async {
                    final t = await _pickTime(context, _end);
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

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<TimeOfDay?> _pickTime(BuildContext context, TimeOfDay initial) {
    return showDialog<TimeOfDay>(
      context: context,
      builder: (ctx) => _TimePickerDialog(initial: initial),
    );
  }

  Future<void> _save() async {
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
      await ref.read(shiftTypesProvider.notifier).update(type);
    } else {
      await ref.read(shiftTypesProvider.notifier).add(type);
    }
    // 근무 시간 변경 시 알림 즉시 재스케줄
    await syncAll(ref);
    if (mounted) Navigator.pop(context);
  }
}

/// 시간 입력 다이얼로그 — 자체 lifecycle로 controller/focus 관리
class _TimePickerDialog extends StatefulWidget {
  final TimeOfDay initial;
  const _TimePickerDialog({required this.initial});

  @override
  State<_TimePickerDialog> createState() => _TimePickerDialogState();
}

class _TimePickerDialogState extends State<_TimePickerDialog> {
  late final TextEditingController _hourCtrl;
  late final TextEditingController _minCtrl;
  late final FocusNode _minFocus;

  @override
  void initState() {
    super.initState();
    _hourCtrl = TextEditingController(
        text: widget.initial.hour.toString().padLeft(2, '0'));
    _minCtrl = TextEditingController(
        text: widget.initial.minute.toString().padLeft(2, '0'));
    _minFocus = FocusNode();
  }

  @override
  void dispose() {
    _hourCtrl.dispose();
    _minCtrl.dispose();
    _minFocus.dispose();
    super.dispose();
  }

  void _selectAll(TextEditingController ctrl) {
    ctrl.selection =
        TextSelection(baseOffset: 0, extentOffset: ctrl.text.length);
  }

  void _confirm() {
    final h = int.tryParse(_hourCtrl.text);
    final m = int.tryParse(_minCtrl.text);
    if (h != null && m != null && h >= 0 && h <= 23 && m >= 0 && m <= 59) {
      Navigator.pop(context, TimeOfDay(hour: h, minute: m));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('시간 입력 (24시간)'),
      content: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _hourCtrl,
              autofocus: true,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                  labelText: '시', counterText: '',
                  border: OutlineInputBorder()),
              maxLength: 2,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onTap: () => _selectAll(_hourCtrl),
              onChanged: (v) {
                if (v.length == 2) {
                  _minFocus.requestFocus();
                  // mounted 보장된 상태에서 실행
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) _selectAll(_minCtrl);
                  });
                }
              },
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Text(':',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: TextField(
              controller: _minCtrl,
              focusNode: _minFocus,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                  labelText: '분', counterText: '',
                  border: OutlineInputBorder()),
              maxLength: 2,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onTap: () => _selectAll(_minCtrl),
              onSubmitted: (_) => _confirm(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소')),
        TextButton(
            onPressed: _confirm,
            child: const Text('확인')),
      ],
    );
  }
}
