import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../core/models/app_settings.dart';
import '../../core/models/cycle_block.dart';
import '../../core/models/schedule.dart';
import '../../core/providers/schedule_providers.dart';

class CycleSetupScreen extends ConsumerStatefulWidget {
  const CycleSetupScreen({super.key});

  @override
  ConsumerState<CycleSetupScreen> createState() => _CycleSetupScreenState();
}

class _CycleSetupScreenState extends ConsumerState<CycleSetupScreen> {
  DateTime _startDate = DateTime.now();
  final List<CycleBlock> _blocks = [];
  final _nameCtrl = TextEditingController(text: '새 일정');

  int get _totalDays => _blocks.fold(0, (s, b) => s + b.days);

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shiftTypes = ref.watch(shiftTypesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('사이클 설정'),
        actions: [
          TextButton(
            onPressed: _blocks.isEmpty ? null : _save,
            child: const Text('저장'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                  labelText: '일정 이름',
                  border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                  '시작일: ${_startDate.year}/${_startDate.month}/${_startDate.day}'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: _startDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                );
                if (d != null) setState(() => _startDate = d);
              },
            ),
            const Divider(),
            Text('총 $_totalDays일 주기',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Expanded(
              child: _blocks.isEmpty
                  ? const Center(
                      child: Text('아래 버튼으로 근무 블록을 추가하세요',
                          style: TextStyle(color: Colors.grey)))
                  : ReorderableListView(
                      onReorder: (oldI, newI) {
                        setState(() {
                          if (newI > oldI) newI--;
                          final item = _blocks.removeAt(oldI);
                          _blocks.insert(newI, item);
                        });
                      },
                      children: [
                        for (var i = 0; i < _blocks.length; i++)
                          ListTile(
                            key: ValueKey('block_$i'),
                            leading: CircleAvatar(
                              backgroundColor: Color(shiftTypes
                                      .firstWhere(
                                          (t) =>
                                              t.id ==
                                              _blocks[i].shiftTypeId,
                                          orElse: () => shiftTypes.first)
                                      .colorValue),
                              child: Text(
                                shiftTypes
                                    .firstWhere(
                                        (t) =>
                                            t.id ==
                                            _blocks[i].shiftTypeId,
                                        orElse: () => shiftTypes.first)
                                    .name
                                    .substring(0, 1),
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 12),
                              ),
                            ),
                            title: Text(
                              '${shiftTypes.firstWhere((t) => t.id == _blocks[i].shiftTypeId, orElse: () => shiftTypes.first).name}'
                              ' × ${_blocks[i].days}일',
                            ),
                            trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline),
                                    onPressed: () =>
                                        setState(() => _blocks.removeAt(i)),
                                  ),
                                  const Icon(Icons.drag_handle),
                                ]),
                          ),
                      ],
                    ),
            ),
            const Divider(),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: shiftTypes
                  .map((t) => ActionChip(
                        avatar: CircleAvatar(
                          backgroundColor: Color(t.colorValue),
                          radius: 8,
                        ),
                        label: Text(t.name),
                        onPressed: () => _showDayPicker(t.id),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  void _showDayPicker(String shiftTypeId) {
    int days = 1;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('일수 선택'),
        content: StatefulBuilder(
          builder: (ctx, setSt) => Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.remove),
                onPressed: () =>
                    setSt(() => days = (days - 1).clamp(1, 30)),
              ),
              Text('$days일',
                  style: const TextStyle(fontSize: 28)),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () =>
                    setSt(() => days = (days + 1).clamp(1, 30)),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => _blocks.add(
                  CycleBlock(shiftTypeId: shiftTypeId, days: days)));
              Navigator.pop(ctx);
            },
            child: const Text('추가'),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (_blocks.isEmpty || _nameCtrl.text.trim().isEmpty) return;
    final schedule = Schedule(
      id: const Uuid().v4(),
      name: _nameCtrl.text.trim(),
      cycleStartDate: _startDate,
      cycleBlocks: List.from(_blocks),
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
}
