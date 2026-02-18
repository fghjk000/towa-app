import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/app_settings.dart';
import '../../core/providers/schedule_providers.dart';
import 'shift_type_editor.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schedules = ref.watch(schedulesProvider);
    final settings = ref.watch(appSettingsProvider);
    final shiftTypes = ref.watch(shiftTypesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('설정')),
      body: ListView(
        children: [
          // 일정 프로필 섹션
          const _SectionHeader(title: '일정 프로필'),
          if (schedules.isEmpty)
            const ListTile(
              title: Text('저장된 일정이 없습니다',
                  style: TextStyle(color: Colors.grey)),
            ),
          ...schedules.map((s) => ListTile(
                title: Text(s.name),
                subtitle: Text('${s.totalDays}일 주기'),
                trailing: settings.activeScheduleId == s.id
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : null,
                onTap: () =>
                    ref.read(appSettingsProvider.notifier).update(AppSettings(
                          activeScheduleId: s.id,
                          notificationEnabled: settings.notificationEnabled,
                          notificationMinutesBefore:
                              settings.notificationMinutesBefore,
                        )),
                onLongPress: () => _confirmDelete(context, ref, s.id, s.name),
              )),
          ListTile(
            leading: const Icon(Icons.add),
            title: const Text('새 일정 추가'),
            onTap: () => context.push('/cycle-setup'),
          ),
          const Divider(),
          // 근무 유형 섹션
          const _SectionHeader(title: '근무 유형'),
          ...shiftTypes.map((t) => ListTile(
                leading: CircleAvatar(backgroundColor: Color(t.colorValue)),
                title: Text(t.name),
                subtitle: t.isOff
                    ? const Text('휴무')
                    : Text(
                        '${t.startHour.toString().padLeft(2, '0')}:${t.startMinute.toString().padLeft(2, '0')}'
                        ' ~ ${t.endHour.toString().padLeft(2, '0')}:${t.endMinute.toString().padLeft(2, '0')}'),
                trailing: (t.id == 'day' ||
                        t.id == 'night' ||
                        t.id == 'off')
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () =>
                            ref.read(shiftTypesProvider.notifier).remove(t.id),
                      ),
                onTap: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => ShiftTypeEditor(shiftType: t),
                ),
              )),
          ListTile(
            leading: const Icon(Icons.add),
            title: const Text('근무 유형 추가'),
            onTap: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (_) => const ShiftTypeEditor(),
            ),
          ),
          const Divider(),
          // 알림 섹션
          const _SectionHeader(title: '알림'),
          SwitchListTile(
            title: const Text('알림 사용'),
            subtitle: const Text('근무 시작 전 푸시 알림'),
            value: settings.notificationEnabled,
            onChanged: (v) =>
                ref.read(appSettingsProvider.notifier).update(AppSettings(
                      activeScheduleId: settings.activeScheduleId,
                      notificationEnabled: v,
                      notificationMinutesBefore:
                          settings.notificationMinutesBefore,
                    )),
          ),
          if (settings.notificationEnabled)
            ListTile(
              title: const Text('알림 시간'),
              trailing: DropdownButton<int>(
                value: settings.notificationMinutesBefore,
                items: [10, 15, 30, 60]
                    .map((m) => DropdownMenuItem(
                        value: m, child: Text('$m분 전')))
                    .toList(),
                onChanged: (v) {
                  if (v == null) return;
                  ref.read(appSettingsProvider.notifier).update(AppSettings(
                        activeScheduleId: settings.activeScheduleId,
                        notificationEnabled: settings.notificationEnabled,
                        notificationMinutesBefore: v,
                      ));
                },
              ),
            ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, WidgetRef ref, String id, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('일정 삭제'),
        content: Text('"$name" 일정을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(schedulesProvider.notifier).delete(id);
              Navigator.pop(ctx);
            },
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child:
                const Text('삭제', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(title,
          style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary)),
    );
  }
}
