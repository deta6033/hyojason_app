# 효자손 완성본 변경 사항

이 프로젝트는 창업경진대회에서 앱 단독으로 시연할 수 있도록 정리한 Flutter MVP입니다.

## 핵심 흐름

1. 첫 실행 시 보호자 / 어르신 정보 설정
2. 홈에서 오늘 상태(안정적 / 확인 필요 / 주의) 확인
3. 식사 / 복약 / 외출 / 기분 확인
4. AI 하루 요약과 대화 기록 확인
5. 지난 기록을 리스트 또는 달력으로 확인
6. 복약 일정 추가 / 수정 / 삭제 / 활성화
7. Android/iOS 실제 로컬 복약 알림 예약
8. 앱 내 중요 알림 확인
9. 설정에서 보호자 정보, 기기 상태, 개인정보 원칙 확인
10. 라즈베리파이 없이도 시연 모드로 이상 상황 재현

## 실제 하드웨어가 연결되지 않은 부분

- AI 대화/하루 기록: 시연용 샘플 데이터
- 기기 연결 상태: 시뮬레이션
- Firebase/서버: 미연결

화면과 상태관리 구조는 나중에 실제 서버 데이터로 교체할 수 있도록 분리되어 있습니다.

## 실행 전 권장 명령

```bash
flutter clean
flutter pub get
dart run flutter_launcher_icons
dart run flutter_native_splash:create
flutter run
```

Chrome 확인만 할 경우:

```bash
flutter run -d chrome
```

## APK

```bash
flutter build apk --release
```

출력 위치(일반적인 경우):

`build/app/outputs/flutter-apk/app-release.apk`
