# 버그 리포트 — Towa (shift_widget_app)
**작성일**: 2026-02-27
**테스트 환경**: iOS 시뮬레이터 (iPhone 17 Pro / iOS 26.2), Android 에뮬레이터 (API 36)
**유닛 테스트**: 50개 전부 통과

---

## 요약

| 심각도 | 개수 |
|--------|------|
| P1 (긴급) | 5 |
| P2 (높음) | 5 |
| P3 (중간) | 11 |
| **합계** | **21** |

---

## P1 — 긴급 (출시 전 필수 수정)

### BUG-01: Android 정확한 알람 권한 미확인 → Unhandled Exception
- **파일**: `lib/core/services/notification_service.dart:135`
- **원인**: `zonedSchedule()` 호출 시 `androidScheduleMode: exactAllowWhileIdle`을 사용하는데, 권한(`SCHEDULE_EXACT_ALARM`)이 실제로 허용됐는지 확인하지 않음
- **재현**: Android 12+ 기기에서 "정확한 알람" 권한을 거부한 상태로 사이클 저장
- **증상**: `PlatformException(exact_alarms_not_permitted)` 크래시 — 에뮬레이터 logcat에서 반복 확인됨
- **수정 방향**: 스케줄링 전 `canScheduleExactAlarms()` 확인 후 불가 시 inexact 폴백 또는 건너뜀

---

### BUG-02: `scheduleWeekNotifications()` try-catch 누락
- **파일**: `lib/core/services/notification_service.dart:100-164`
- **원인**: 60개 알림을 순서대로 await 스케줄링하는데 전체 함수에 try-catch 없음
- **재현**: 알림 권한 문제, 타임존 데이터 누락 등 플랫폼 이슈 발생 시
- **증상**: Unhandled Exception → 상위 호출 체인(syncAll) 전체 중단
- **수정 방향**: 함수 전체를 try-catch로 감싸거나, 개별 `zonedSchedule` 호출을 try-catch 처리

---

### BUG-03: `_save()`에서 `syncAll()` 예외 미처리
- **파일**: `lib/features/cycle/cycle_setup_screen.dart:146`
- **원인**: 사이클 저장 성공 후 `syncAll(ref)` 호출 시 예외 처리 없음
- **재현**: 알림 권한 없는 상태에서 사이클 저장
- **증상**: DB 저장은 성공하지만 알림/위젯 동기화 실패가 사용자에게 표시 안 됨 (BUG-01의 영향)

---

### BUG-04: 캘린더 근무 변경 시 예외 처리 누락
- **파일**: `lib/features/calendar/calendar_screen.dart:99-115`
- **원인**: `onSelect` / `onReset` 콜백에서 await 호출 후 try-catch 없음
- **재현**: 오버라이드 저장/삭제 중 DB 오류 또는 동기화 실패 시
- **증상**: 변경 실패 시 사용자에게 아무 피드백 없음

---

### BUG-05: 설정 화면 async 호출 예외 처리 누락
- **파일**: `lib/features/settings/settings_screen.dart:82-92, 231, 324`
- **원인**: 일정 활성화, 알림 권한 요청, 삭제 등 여러 async 호출에 try-catch 없음
- **재현**: 설정 변경 중 동기화 실패 시
- **증상**: 설정은 바뀌지만 동기화 실패 시 위젯/알림 상태 불일치

---

## P2 — 높음 (조기 출시 후 빠른 패치 필요)

### BUG-06: Android 정확한 알람 권한 요청 반환값 미활용
- **파일**: `lib/core/services/notification_service.dart:56-57`
- **원인**: `requestExactAlarmsPermission()` 호출만 하고 반환값 확인 안 함
- **증상**: 권한 거부 여부를 앱이 모름 → 이후 스케줄링 시도 시 BUG-01 재발

---

### BUG-07: `_applyMinutes()` 예외 처리 누락
- **파일**: `lib/features/settings/settings_screen.dart:37-52`
- **원인**: 알림 시간 변경 후 `syncAll()` try-catch 없음
- **재현**: 알림 분 설정 변경 중 동기화 실패

---

### BUG-08: 캘린더 날짜 선택 race condition
- **파일**: `lib/features/calendar/calendar_screen.dart:44-49`
- **원인**: `onDaySelected` → `_showShiftOverrideSheet()` 호출 사이에 일정 삭제 시 null 역참조 가능
- **재현**: 날짜 탭과 동시에 다른 기기/탭에서 일정 삭제 (드문 케이스)

---

### BUG-09: 근무 유형 편집 저장 예외 처리 누락
- **파일**: `lib/features/settings/shift_type_editor.dart:141-161`
- **원인**: `_save()` 메서드 내 `add/update()` 및 `syncAll()` try-catch 없음

---

### BUG-10: `_doSync()` 예외 처리 누락
- **파일**: `lib/app_widget_observer.dart:33-64`
- **원인**: `NotificationService.scheduleWeekNotifications()`와 `WidgetSyncService.updateWidget()` 모두 예외 처리 없음
- **증상**: 동기화 실패가 상위로 전파되어 `syncAll()`의 finally 블록까지 영향

---

## P3 — 중간 (다음 정식 업데이트에서 수정)

### BUG-11: 근무 유형 삭제 후 위젯/알림 동기화 누락
- **파일**: `lib/features/settings/settings_screen.dart:306-308`
- **원인**: `_deleteShiftType()` 후 `syncAll()` 호출 없음
- **증상**: 근무 유형 삭제 후 위젯이 삭제된 유형명을 계속 표시 가능

---

### BUG-12: `shift_calculator.dart` 빈 사이클 처리 미비
- **파일**: `lib/core/services/shift_calculator.dart:32-42`
- **원인**: `totalDays == 0` 체크는 있으나 에러 메시지/로깅 없음
- **재현**: 빈 `cycleBlocks` 상태의 Schedule 생성 (UI에서 방지하나 이론적 가능)

---

### BUG-13: iOS 위젯 업데이트 예외 처리 누락
- **파일**: `lib/core/services/widget_sync_service.dart:45-47`
- **원인**: Android는 `catch (_) {}` 처리하지만 iOS `HomeWidget.updateWidget()` 예외 처리 없음

---

### BUG-14: 홈 화면 프로바이더 상태 불일치 가능성
- **파일**: `lib/features/home/home_screen.dart:14-40`
- **원인**: `schedule`, `shiftTypes`, `overrides` 독립 watch → 삭제 타이밍에 inconsistent 상태 발생 가능

---

### BUG-15~21: 기타 미세 이슈
- `shift_type_editor.dart:134`: `_pickTime()` 취소 시 명시적 null 처리 없음 (동작은 정상)
- `calendar_screen.dart:81`: `ref.read(activeScheduleProvider)` 이중 체크 중복
- `app_widget_observer.dart:21`: `_pendingSync` 플래그로 동기화 최대 1회 누락 가능
- `calendar_screen.dart:52-66`: calendarBuilders 콜백에 null 체크 중복 (성능 미미)
- `cycle_setup_screen.dart:39-43`: `initState` postFrameCallback에서 setState → 다중 rebuild 가능
- 설정 화면 동기화 실패 시 UI 상태 롤백 없음
- 홈 화면 weekdayOffset 계산 로직 일요일(7%7=0) 경계값 검증 부족

---

## 플랫폼별 특이 사항

### Android
- **에뮬레이터 로그에서 확인된 크래시**: BUG-01 (`exact_alarms_not_permitted`) 반복 발생 (약 20~40초 간격)
- **WorkManager SystemJobService 재시작 반복**: 에뮬레이터 logcat에서 다수 확인 (배경 동기화 서비스 불안정)
- **시작 시 프레임 스킵**: `Skipped 167 frames` → 메인 스레드 과부하 (Hive 초기화 비동기 처리 개선 필요)

### iOS
- **통합 테스트**: All tests passed ✅
- **스크린샷 일관성 이슈**: 신규 설치 시 01_home / 02_calendar / 04_settings 스크린샷이 동일 사이즈 (134091 bytes) → 빈 상태에서 세 화면 모두 유사하게 보이는 것으로 추정 (기능 버그 아님)

---

## 권장 수정 우선순위

```
1. BUG-01 + BUG-02 + BUG-10 묶음 수정:
   notification_service.dart에 try-catch + canScheduleExactAlarms() 체크 추가
   → _doSync()에서 예외 catch하여 silently 처리

2. BUG-03 + BUG-04 + BUG-05 묶음 수정:
   각 화면 async 호출에 try-catch 추가

3. BUG-11 단독 수정:
   _deleteShiftType() 후 syncAll() 추가

4. P3 버그들은 다음 업데이트에서 일괄 처리
```

---

*이 보고서는 통합 테스트 + logcat 분석 + 코드 리뷰를 통해 작성됐습니다.*
