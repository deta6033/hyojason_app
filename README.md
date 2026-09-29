# 효자손 보호자 앱

창업경진대회 시연을 위한 Flutter 보호자용 돌봄 앱입니다.

## 구현 기능

- 첫 실행 보호자/어르신 정보 설정
- 홈에서 오늘 상태(안정적 / 확인 필요 / 주의) 표시
- 식사 / 복약 / 외출 / 기분 요약
- AI 하루 요약 및 AI 대화 기록 조회
- 지난 기록 리스트 / 월간 달력
- 복약 일정 추가 / 수정 / 삭제 / ON-OFF
- Android/iOS 로컬 시스템 복약 알림 예약
- 보호자 알림 OFF 시 예약 알림도 실제 해제
- 앱 내 알림 읽음 처리 / 모두 읽음
- 보호자 정보 수정 및 로컬 저장
- 효자손 기기 연결 상태 시뮬레이션
- 발표용 시연 모드
- 개인정보 및 데이터 안내
- 시제품 데이터 초기화
- 전체 Material 3 UI 디자인 시스템 적용
- 잘난체 / 잘난체 고딕 적용 구조 준비

## 실행

```bash
flutter pub get
flutter run
```

웹 확인:

```bash
flutter run -d chrome
```

## 정적 분석

```bash
flutter analyze
```

GitHub Pull Request에서도 Flutter CI가 정적 분석과 Android debug APK 빌드를 자동으로 확인합니다.

## APK 생성

```bash
flutter clean
flutter pub get
flutter build apk --release
```

완성 APK는 일반적으로 아래 경로에 생성됩니다.

```text
build/app/outputs/flutter-apk/app-release.apk
```

## 잘난체 적용

UI 코드는 제목에 `Jalnan`, 본문에 `JalnanGothic`을 사용하도록 준비되어 있습니다.

폰트 파일 자체는 저장소에 포함하지 않습니다. 공식 폰트 페이지에서 직접 내려받은 뒤 `FONT_SETUP.md`의 절차대로 추가하세요.

폰트 파일을 넣지 않은 상태에서도 앱은 시스템 기본 폰트로 정상 빌드됩니다.

## 현재 데이터 범위

현재 AI 대화, 하루 기록, 기기 연결 상태는 창업경진대회 시연용 데이터입니다.

실제 제품 단계에서는 다음 데이터 공급부를 교체하면 됩니다.

- AI/STT 서버
- Raspberry Pi 또는 실제 웨어러블 기기
- Firebase 또는 별도 백엔드
- 실제 보호자/어르신 계정 인증

UI와 상태 관리 코드는 실제 백엔드 연결 전에도 독립적으로 시연할 수 있도록 구성되어 있습니다.
