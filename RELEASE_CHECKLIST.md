# 효자손 보호자 앱 통합 릴리스 체크리스트 (2026-10-28)

## 구현 범위
- 보호자 로그인, Firebase 권한 확인, 실시간 AI 대화·복약·알림 조회: 기존 기능 유지
- 하단 **지도** 탭: 마지막 실제 GPS 좌표(위치 마커·측정 시간). 좌표가 없으면 미확인.
- **설정**: 0~100% 목표 음량 선택, AI TTS 목소리(alloy, nova, shimmer) 선택.
- **AI 하루 요약**: 로그인한 등록 보호자가 오늘의 실제 대화에 기반하여 생성. 결과는 Firestore dailySummaries에 저장.
- **FCM 긴급 푸시**: Android 보호자 휴대폰의 FCM 토큰 등록, 긴급호출 이벤트 발생 시 Cloud Run에서 승인된 보호자에게 알림.
- **복약 일정**: 기존 Firebase CRUD 및 로컬 예약 알림 유지.
- Android/Web Firebase 공개 설정을 코드에 포함. **기기 비밀 토큰, OpenAI API 키는 앱 코드에 포함하지 않습니다.**

## 병합/개발 환경
1. GitHub의 앱 PR #4를 병합합니다. 서버 API 통합 내용이 포함되어 있어 기존 앱 PR #3의 서버 코드와 중복되며, **PR #3은 별도로 병합할 필요가 없습니다**.
2. 사용자 PC GitHub Desktop에서 Fetch origin → Pull origin.
3. VS Code 프로젝트 루트에서 `flutter pub get`; `flutter run -d chrome` 실행.
4. Android는 `flutter run -d <android-device>` 또는 `flutter build apk --debug`. APK를 실제 휴대폰에 설치하여 로그인·권한·알림을 검증합니다.
5. 자동검사: GitHub Actions > Flutter checks / Flutter CI. PR 코드가 검사 통과 전까지 프로덕션 완료로 간주하지 않습니다.

## Firebase 배포 필수
1. Firebase Console > Firestore Database > Rules에서 **병합된 최신 `firestore.rules`를 Publish**합니다. GitHub 변경만으로 실제 보안 규칙은 바뀌지 않습니다.
2. Android Firebase app: `com.example.hyojason_app` (등록된 기존 패키지). 제공된 `google-services.json`은 **공개 클라이언트 설정**이며, 서버 비밀키가 아닙니다.
3. Firebase Authentication 이메일/비밀번호와 `devices/hyojason-001/guardians/<UID>` 문서의 `enabled=true`가 필요합니다.
4. Android 13 이상 알림 권한을 허용합니다. FCM 등록 성공 시 `guardians/<UID>/pushTokens/<sha256>`에 토큰이 저장됩니다.
5. FCM Cloud Messaging API 활성화 및 Cloud Run 실행 서비스 계정의 FCM 메시지 전송 권한(IAM)을 점검합니다.

## Cloud Run 배포 필수
1. Google Cloud Console의 기존 서비스 `hyojason-api`(asia-northeast3)의 함수 소스에서 **`cloud_run/main.py`**를 적용합니다.
2. 기존 함수 진입점 `hello_http` 유지.
3. `cloud_run/requirements.txt`를 적용합니다(`firebase-admin` 추가).
4. 기존 환경 변수 `OPENAI_API_KEY`, `HYOJASON_DEVICE_TOKEN`은 보존합니다. 채팅, 음성 인식, 음성 생성 엔드포인트를 변경하지 않았습니다.
5. 재배포 완료 후 `GET /` 상태, 보호자 로그인, `POST /summary`, 장치 인증 `GET /device/config`, `POST /device/status`, `POST /device/emergency`를 테스트합니다. 실제 긴급 이벤트를 테스트하면 알림이 발송될 수 있으니 **사전 합의한 테스트 기기로만** 진행합니다.

## ESP32 펌웨어 (별도 PR #1)
- 서버 재배포 후 펌웨어 PR #1을 병합·컴파일·업로드합니다.
- 60초마다 `/device/config` 및 `/device/status`를 호출하며 긴급버튼으로 `/device/emergency` 요청합니다.
- 장치 인증은 기존 Bearer device token을 사용합니다.
- **GPS 위치 전송은 아직 미구현**: GPS UART 배선 및 좌표 검증 없이 핀 번호를 임의 결정하지 않습니다.
- 8Ω 1W 스피커는 기존 소프트웨어의 보수적인 진폭 상한을 유지합니다. 앱 100%는 물리 최대 음량을 뜻하지 않습니다.
- 소프트웨어 개발 단계에서는 장치 전원 인가나 음량 증가를 요구하지 않습니다.

## 필수 실제 검증
- 앱 로그인, 마지막 GPS 미보고 안내, Firestore 지도 좌표, 음량 슬라이더 Firebase 저장.
- Firebase TTS 음색 변경 후 서버에서 생성한 새 음성 반영.
- AI 하루 요약: 대화 있는 날만 생성, 생성된 내용의 실제 대화 근거 검토.
- 복약 일정 CRUD와 알림 권한·알림 시간; Android 앱을 닫은 상태에서 알림 표시.
- 긴급버튼 이벤트 기록 및 FCM 토큰 등록, 잠금화면·앱 종료 상태 푸시 수신.
- 접근 권한 없는 계정에서 기기·토큰·음량·요약 조회 차단.
- Cloud Run 로그, 비용, 데이터 보관 정책 점검.

## 현재 미완료 / 운영상 제한
- Cloud Run/Firebase Rules **실제 배포 및 실기기 검증은 코드 작성과 별개**입니다.
- 실제 GPS 하드웨어 좌표 송신, 범용 기기 페어링(BLE/QR), iOS 지원, 사람 목소리 복제는 포함하지 않았습니다.
- 긴급 푸시는 인터넷/권한/전원 상태에 따라 지연·유실될 수 있으며 119 신고 등 기존 긴급 안전망을 대체하지 못합니다.
- Firestore의 `online=true` 플래그는 서버 측 TTL로 지워지지 않지만 앱은 마지막 보고 120초 초과 시 오프라인으로 표시합니다.
