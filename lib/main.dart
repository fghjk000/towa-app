import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  runApp(const ProviderScope(child: ShiftWidgetApp()));
}

class ShiftWidgetApp extends StatelessWidget {
  const ShiftWidgetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '교대근무',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const Scaffold(
        body: Center(child: Text('교대근무 앱')),
      ),
    );
  }
}
