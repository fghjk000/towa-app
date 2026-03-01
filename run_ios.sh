#!/bin/bash
# iOS 빌드 시 iCloud FinderInfo xattr 문제 근본 해결 스크립트
# 전략: build/ → /tmp/shiftwidget_build 심링크
#   /tmp는 iCloud Drive 범위 밖 → xattr 레이스 컨디션 완전 차단

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_BUILD="/tmp/shiftwidget_build"
BUILD_LINK="$PROJECT_DIR/build"

cd "$PROJECT_DIR"

# 1) build → /tmp/shiftwidget_build 심링크 설정
if [ -L "$BUILD_LINK" ] && [ "$(readlink "$BUILD_LINK")" = "$TMP_BUILD" ]; then
  echo "iCloud bypass already active (build -> $TMP_BUILD)"
else
  echo "Setting up iCloud bypass: build -> $TMP_BUILD ..."
  flutter clean
  rm -rf "$BUILD_LINK" 2>/dev/null
  # build.nosync 잔재도 정리
  rm -rf "$PROJECT_DIR/build.nosync" 2>/dev/null
  mkdir -p "$TMP_BUILD"
  ln -s "$TMP_BUILD" "$BUILD_LINK"
  echo "iCloud bypass active: $BUILD_LINK -> $TMP_BUILD"
fi

# 2) flutter run (release 모드: 홈 화면에서 직접 실행 가능)
flutter run --release -d 00008103-001D29AA3620C01E "$@"
