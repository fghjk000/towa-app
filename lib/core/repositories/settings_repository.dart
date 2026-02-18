import 'package:hive_flutter/hive_flutter.dart';
import '../models/app_settings.dart';

class SettingsRepository {
  static const _boxName = 'settings';
  static const _key = 'app_settings';
  late Box<AppSettings> _box;

  Future<void> init() async {
    if (Hive.isBoxOpen(_boxName)) {
      _box = Hive.box<AppSettings>(_boxName);
    } else {
      _box = await Hive.openBox<AppSettings>(_boxName);
    }
  }

  AppSettings get settings =>
      _box.get(_key) ??
      AppSettings(
        activeScheduleId: '',
        notificationEnabled: true,
        notificationMinutesBefore: 30,
      );

  Future<void> save(AppSettings settings) async {
    await _box.put(_key, settings);
  }
}
