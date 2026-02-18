import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/models/app_settings.dart';
import 'core/models/cycle_block.dart';
import 'core/models/overtime_entry.dart';
import 'core/models/schedule.dart';
import 'core/models/shift_type.dart';
import 'core/providers/schedule_providers.dart';
import 'core/repositories/schedule_repository.dart';
import 'core/repositories/settings_repository.dart';
import 'core/router.dart';
import 'core/services/notification_service.dart';
import 'core/services/widget_sync_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ko', null);
  await Hive.initFlutter();
  Hive.registerAdapter(ShiftTypeAdapter());
  Hive.registerAdapter(CycleBlockAdapter());
  Hive.registerAdapter(ScheduleAdapter());
  Hive.registerAdapter(OvertimeEntryAdapter());
  Hive.registerAdapter(AppSettingsAdapter());

  final scheduleRepo = ScheduleRepository();
  final settingsRepo = SettingsRepository();
  await scheduleRepo.init();
  await settingsRepo.init();
  await NotificationService.init();
  await WidgetSyncService.init();
  await NotificationService.requestPermission();

  runApp(ProviderScope(
    overrides: [
      scheduleRepositoryProvider.overrideWithValue(scheduleRepo),
      settingsRepositoryProvider.overrideWithValue(settingsRepo),
    ],
    child: const ShiftWidgetApp(),
  ));
}

class ShiftWidgetApp extends StatelessWidget {
  const ShiftWidgetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: '교대근무',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      routerConfig: appRouter,
    );
  }
}
