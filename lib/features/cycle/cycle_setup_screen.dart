import 'package:flutter/material.dart';

class CycleSetupScreen extends StatelessWidget {
  const CycleSetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('사이클 설정')),
      body: const Center(child: Text('사이클 설정 화면')),
    );
  }
}
