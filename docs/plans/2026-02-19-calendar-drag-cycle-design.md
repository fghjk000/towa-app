# Calendar Drag Cycle Setup — Design Doc

Date: 2026-02-19

## Overview

Replace the current block-list cycle setup with a calendar paint interface.
Users select a shift type, drag over real calendar dates to assign it, then save.
The painted range becomes a repeating cycle. Individual days can be overridden post-hoc.

---

## UX Flow

### Cycle Setup Screen (새/편집)
1. 상단: 일정 이름 텍스트 필드
2. 중앙: 실제 월 달력 (7열 그리드, 월 이동 버튼 포함)
3. 하단: 근무 유형 선택 버튼 (주간 / 야간 / 휴무 / 커스텀...)
4. 사용자: 유형 선택 → 달력 위에서 드래그 → 날짜 색칠
5. 월 이동 후 다른 달도 계속 색칠 가능
6. 저장: 첫 색칠 날 ~ 마지막 색칠 날 = 한 사이클, 이후 반복

### 개별 날짜 수정 (특근/예외)
- 캘린더 화면에서 날짜 탭 → 바텀시트로 근무 유형 선택
- 해당 날짜만 예외 저장, 사이클은 유지

---

## Data Model

### Schedule 변경 없음 (CycleBlock 구조 유지)
사이클 추출 알고리즘이 페인트 결과 → CycleBlock 리스트로 변환.

### 신규: DateOverride 모델
```dart
@HiveType(typeId: 3)
class DateOverride {
  @HiveField(0) final String scheduleId;
  @HiveField(1) final DateTime date;       // midnight normalized
  @HiveField(2) final String shiftTypeId;
}
```
별도 Hive box `dateOverrides`에 저장.

---

## Key Algorithms

### 사이클 추출
```
paintedDays: Map<DateTime, shiftTypeId>
start = min(paintedDays.keys)
end   = max(paintedDays.keys)

for day in [start..end]:
  typeId = paintedDays[day] ?? 'off'   // 안 칠한 날 = 휴무
  연속 같은 typeId 묶기 → CycleBlock(typeId, days)
```

### ShiftCalculator 오버라이드 적용
```
getShiftType(date, schedule, overrides):
  if overrides[date] exists → return that shiftType
  else → 기존 사이클 계산 (cycleStartDate + cycleBlocks)
```

### 달력 드래그 히트 테스트
- 달력 전체를 GestureDetector(onPanStart/Update/End)로 감싸기
- 각 셀 위치를 수학적으로 계산:
  ```
  cellW = calendarWidth / 7
  cellH = rowHeight
  col = (localX / cellW).floor()
  row = (localY / cellH).floor()
  dayIndex = row * 7 + col - firstWeekdayOffset
  ```
- 드래그 중 dayIndex가 바뀔 때마다 paintedDays 업데이트

---

## Files to Create / Modify

| 파일 | 작업 |
|------|------|
| `lib/core/models/date_override.dart` (신규) | DateOverride Hive 모델 |
| `lib/core/models/date_override.g.dart` (생성) | build_runner |
| `lib/core/repositories/schedule_repository.dart` | override CRUD 추가 |
| `lib/core/providers/schedule_providers.dart` | overridesProvider 추가 |
| `lib/core/services/shift_calculator.dart` | override 우선 적용 |
| `lib/features/cycle/cycle_setup_screen.dart` | 전체 재작성 (캘린더 페인트) |
| `lib/features/calendar/calendar_screen.dart` | 날짜 탭 → override 바텀시트 |
| `lib/main.dart` | DateOverride Hive adapter 등록 |

---

## Constraints

- 색칠한 날이 0개면 저장 불가
- 월 이동 시 다른 달에 칠한 내용 유지
- 기존 Schedule 호환 유지 (CycleBlock 구조 변경 없음)
