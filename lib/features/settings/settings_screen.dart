import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app_widget_observer.dart';
import '../../core/models/app_settings.dart';
import '../../core/providers/schedule_providers.dart';
import '../../core/services/notification_service.dart';
import 'shift_type_editor.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool? _notifPermission;
  late final TextEditingController _minutesCtrl;
  String? _minutesError;

  @override
  void initState() {
    super.initState();
    _checkPermission();
    final minutes = ref.read(appSettingsProvider).notificationMinutesBefore;
    _minutesCtrl = TextEditingController(text: minutes.toString());
  }

  @override
  void dispose() {
    _minutesCtrl.dispose();
    super.dispose();
  }

  Future<void> _applyMinutes(AppSettings settings) async {
    final value = _minutesCtrl.text.trim();
    final minutes = int.tryParse(value);
    if (minutes == null || minutes < 1 || minutes > 240) {
      setState(() => _minutesError = '1~240 사이의 숫자를 입력해주세요');
      return;
    }
    setState(() => _minutesError = null);
    if (minutes == settings.notificationMinutesBefore) return;
    await ref.read(appSettingsProvider.notifier).update(AppSettings(
          activeScheduleId: settings.activeScheduleId,
          notificationEnabled: settings.notificationEnabled,
          notificationMinutesBefore: minutes,
        ));
    await syncAll(ref);
  }

  Future<void> _checkPermission() async {
    final granted = await NotificationService.checkPermission();
    if (mounted) setState(() => _notifPermission = granted);
  }

  @override
  Widget build(BuildContext context) {
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
                onTap: () async {
                  await ref
                      .read(appSettingsProvider.notifier)
                      .update(AppSettings(
                        activeScheduleId: s.id,
                        notificationEnabled: settings.notificationEnabled,
                        notificationMinutesBefore:
                            settings.notificationMinutesBefore,
                      ));
                  await syncAll(ref);
                },
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
                        t.id == 'off' ||
                        t.id == 'overtime')
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _deleteShiftType(context, ref, t.id, t.name, schedules),
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
            onChanged: (v) async {
              await ref.read(appSettingsProvider.notifier).update(AppSettings(
                    activeScheduleId: settings.activeScheduleId,
                    notificationEnabled: v,
                    notificationMinutesBefore:
                        settings.notificationMinutesBefore,
                  ));
              await syncAll(ref);
            },
          ),
          if (settings.notificationEnabled)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('알림 시간',
                      style: TextStyle(fontSize: 15)),
                  const SizedBox(height: 2),
                  const Text('근무 시작 몇 분 전 (1~240)',
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      SizedBox(
                        width: 110,
                        child: TextField(
                          controller: _minutesCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                              signed: false, decimal: false),
                          textAlign: TextAlign.center,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: const InputDecoration(
                            suffixText: '분 전',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 8, vertical: 10),
                          ),
                          onChanged: (_) {
                            if (_minutesError != null) {
                              setState(() => _minutesError = null);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () => _applyMinutes(settings),
                        child: const Text('적용'),
                      ),
                    ],
                  ),
                  if (_minutesError != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      _minutesError!,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
          // 알림 권한 상태 및 테스트
          const Divider(),
          const _SectionHeader(title: '알림 진단'),
          if (_notifPermission == false)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('⚠️ 알림 권한이 거부되어 있습니다',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.red)),
                  const SizedBox(height: 4),
                  const Text(
                      '이 기기 설정 앱 → 알림 → 이 앱 → "알림 허용" 을 켜주세요',
                      style: TextStyle(fontSize: 13)),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () async {
                      await NotificationService.requestPermission();
                      _checkPermission();
                    },
                    child: const Text('권한 다시 요청'),
                  ),
                ],
              ),
            )
          else if (_notifPermission == true)
            const ListTile(
              leading: Icon(Icons.check_circle, color: Colors.green),
              title: Text('알림 권한 허용됨'),
              dense: true,
            )
          else
            const ListTile(
              leading: SizedBox(
                  width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
              title: Text('권한 확인 중...'),
              dense: true,
            ),
          ListTile(
            leading: const Icon(Icons.notifications_active),
            title: const Text('즉시 테스트 알림 보내기'),
            subtitle: const Text('버튼을 누르면 바로 알림이 표시됩니다'),
            onTap: () async {
              try {
                await NotificationService.sendTestNotification();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('테스트 알림을 발송했습니다')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('알림 오류: $e'),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 8),
                    ),
                  );
                }
              }
            },
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  /// 커스텀 근무 유형 삭제 — 사용 중인 스케줄이 있으면 경고 다이얼로그 표시
  Future<void> _deleteShiftType(BuildContext context, WidgetRef ref, String id,
      String name, List<dynamic> schedules) async {
    // 이 유형을 사용하는 스케줄이 있는지 확인
    final isUsed = schedules.any((s) =>
        (s.cycleBlocks as List).any((b) => b.shiftTypeId == id));

    if (isUsed) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('근무 유형 삭제 불가'),
          content: Text(
              '"$name" 유형은 현재 사용 중인 일정에 포함되어 있습니다.\n'
              '해당 일정을 먼저 삭제하거나 변경해주세요.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('확인'),
            ),
          ],
        ),
      );
    } else {
      ref.read(shiftTypesProvider.notifier).remove(id);
      try {
        await syncAll(ref);
      } catch (_) {}
    }
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
            onPressed: () async {
              Navigator.pop(ctx);
              // 삭제 전 현재 설정 스냅샷
              final settings = ref.read(appSettingsProvider);
              await ref.read(schedulesProvider.notifier).delete(id);
              // 삭제한 일정이 활성 일정이었으면 activeScheduleId 초기화
              if (settings.activeScheduleId == id) {
                await ref.read(appSettingsProvider.notifier).update(
                      AppSettings(
                        activeScheduleId: '',
                        notificationEnabled: settings.notificationEnabled,
                        notificationMinutesBefore:
                            settings.notificationMinutesBefore,
                      ),
                    );
              }
              // DateOverride 고아 데이터 정리
              await ref.read(overrideRepositoryProvider).deleteAllForSchedule(id);
              await syncAll(ref);
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
