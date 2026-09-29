# 효자손 보호자 앱 MVP

창업경진대회 시연을 위한 Flutter 보호자용 앱입니다.

## 현재 구현 기능

- 첫 실행 보호자/어르신 정보 설정
- 홈에서 오늘 상태(안정적 / 확인 필요 / 주의) 표시
- 식사 / 복약 / 외출 / 기분 요약
- AI 하루 요약 및 AI 대화 기록 조회
- 지난 기록 리스트 / 월간 달력
- 복약 일정 추가 / 수정 / 삭제 / ON-OFF
- 복약 시간 Android/iOS 로컬 시스템 알림 예약
- 앱 내 알림 읽음 처리 / 모두 읽음
- 보호자 정보 수정 및 로컬 저장
- 효자손 기기 연결 상태 시뮬레이션
- 발표용 시연 모드(복약 미확인, 24시간 대화 없음, 연결 끊김, 배터리 부족)
- 개인정보 및 데이터 안내
- 시제품 데이터 초기화

## 실행

```bash
flutter pub get
flutter run -d chrome
```

Android 실기기:

```bash
flutter devices
flutter run
```

## 아이콘 / 스플래시 재생성

```bash
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

## APK 생성

```bash
flutter clean
flutter pub get
flutter build apk --release
```

완성 APK는 일반적으로 `build/app/outputs/flutter-apk/app-release.apk`에 생성됩니다.

## 참고

현재 AI 대화, 하루 기록, 기기 연결 상태는 시연용 데이터입니다. 실제 라즈베리파이/AI 서버/Firebase 연결은 이후 `AppState`의 데이터 공급부를 실제 백엔드 Repository로 교체하는 방식으로 확장할 수 있습니다.
