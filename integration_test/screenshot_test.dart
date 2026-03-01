import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shift_widget_app/main.dart' as app;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('App Store 스크린샷', (tester) async {
    app.main();

    // Android: 스크린샷 전 surface 변환 필수
    if (defaultTargetPlatform == TargetPlatform.android) {
      await binding.convertFlutterSurfaceToImage();
    }

    // 플랫폼 채널(Hive, 알림) 초기화 대기
    await Future.delayed(const Duration(seconds: 7));
    await tester.pump();
    await tester.pumpAndSettle(const Duration(seconds: 5));

    // ─── 캘린더 탭으로 이동 ───
    final calText = find.text('캘린더');
    if (calText.evaluate().isNotEmpty) {
      await tester.tap(calText.first);
    }
    await Future.delayed(const Duration(seconds: 1));
    await tester.pump();
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // ─── 사이클 설정 진입 ───
    final setupBtn = find.text('사이클 설정');
    if (setupBtn.evaluate().isNotEmpty) {
      await tester.tap(setupBtn.first);
      await Future.delayed(const Duration(seconds: 1));
      await tester.pump();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // 날짜 셀 탭으로 주기 칠하기 (현재 기본 선택: 첫 번째 근무 유형)
      // 2026년 2월: 1일=일요일 → row0: 1~7, row1: 8~14, row2: 15~21
      // 첫 근무유형(주간)으로 1~7 칠하기
      for (final d in ['1', '2', '3', '4', '5', '6', '7']) {
        final t = find.text(d);
        if (t.evaluate().isNotEmpty) {
          await tester.tap(t.first);
          await tester.pump(const Duration(milliseconds: 80));
        }
      }
      await tester.pump();

      // 야간 유형 선택 후 8~14 칠하기
      final nightChip = find.text('야간');
      if (nightChip.evaluate().isNotEmpty) {
        await tester.tap(nightChip.first);
        await tester.pump();
        for (final d in ['8', '9', '10', '11', '12', '13', '14']) {
          final t = find.text(d);
          if (t.evaluate().isNotEmpty) {
            await tester.tap(t.first);
            await tester.pump(const Duration(milliseconds: 80));
          }
        }
      }
      await tester.pump();

      // 휴무 유형 선택 후 15~17 칠하기
      final offChip = find.text('휴무');
      if (offChip.evaluate().isNotEmpty) {
        await tester.tap(offChip.first);
        await tester.pump();
        for (final d in ['15', '16', '17']) {
          final t = find.text(d);
          if (t.evaluate().isNotEmpty) {
            await tester.tap(t.first);
            await tester.pump(const Duration(milliseconds: 80));
          }
        }
      }
      await tester.pumpAndSettle();

      // ─── 03_cycle_setup 스크린샷 ───
      await binding.takeScreenshot('03_cycle_setup');

      // 저장 (paintedDays가 있으면 활성화됨)
      final saveBtn = find.text('저장');
      if (saveBtn.evaluate().isNotEmpty) {
        await tester.tap(saveBtn.first);
        await Future.delayed(const Duration(seconds: 3));
        await tester.pump();
        await tester.pumpAndSettle(const Duration(seconds: 3));
      }
    }

    // ─── 캘린더 화면으로 이동 (메인 셸) ───
    // 사이클 설정 저장 후 자동으로 캘린더 화면으로 돌아옴
    // 만약 아직 cycle setup이면 뒤로가기
    final backBtn = find.byTooltip('Back');
    if (backBtn.evaluate().isNotEmpty) {
      await tester.tap(backBtn.first);
      await Future.delayed(const Duration(seconds: 1));
      await tester.pump();
      await tester.pumpAndSettle(const Duration(seconds: 3));
    }

    // 캘린더 탭 확인 (bottom nav에 있어야 함)
    final calTab = find.text('캘린더');
    if (calTab.evaluate().isNotEmpty) {
      await tester.tap(calTab.first);
      await Future.delayed(const Duration(seconds: 1));
      await tester.pump();
      await tester.pumpAndSettle(const Duration(seconds: 3));
    }

    // ─── 02_calendar 스크린샷 ───
    await binding.takeScreenshot('02_calendar');

    // ─── 오늘 탭으로 이동 ───
    final homeTab = find.text('오늘');
    if (homeTab.evaluate().isNotEmpty) {
      await tester.tap(homeTab.first);
      await Future.delayed(const Duration(seconds: 1));
      await tester.pump();
      await tester.pumpAndSettle(const Duration(seconds: 3));
    }

    // ─── 01_home 스크린샷 ───
    await binding.takeScreenshot('01_home');

    // ─── 설정 탭으로 이동 ───
    final settingsTab = find.text('설정');
    if (settingsTab.evaluate().isNotEmpty) {
      await tester.tap(settingsTab.first);
      await Future.delayed(const Duration(seconds: 1));
      await tester.pump();
      await tester.pumpAndSettle(const Duration(seconds: 3));
    }

    // ─── 04_settings 스크린샷 ───
    await binding.takeScreenshot('04_settings');
  });
}
