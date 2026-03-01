import 'dart:io';
import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() async {
  await integrationDriver(
    onScreenshot: (String name, List<int> bytes, [Map<String, Object?>? args]) async {
      final file = File('store_assets/screenshots/ios/$name.png');
      file.parent.createSync(recursive: true);
      await file.writeAsBytes(bytes);
      print('Screenshot saved: store_assets/screenshots/ios/$name.png');
      return true;
    },
  );
}
