# 효자손 서버·앱 GPS/긴급 이벤트 통합

## 구현된 파일
- `cloud_run/main.py`: **실제로 전달받은 Cloud Run 소스**에 `/device/status` 및 `/device/emergency`를 추가한 통합본. **기존 /, /chat, /transcribe, /tts 경로와 `Authorization: Bearer <device token>` 인증 방식 유지.**
- `lib/screens/device_monitor_screen.dart`: Firestore 기기 heartbeat·GPS·배터리·네트워크 상태를 조회하는 화면.
- `lib/screens/settings_screen.dart`: '기기 상태 및 GPS 위치' 메뉴 추가.

## Cloud Run 배포 전 확인
- 기존 Cloud Run 서비스 `hyojason-api`의 엔트리 포인트 `hello_http` 유지.
- 기존 환경변수 `OPENAI_API_KEY`, `HYOJASON_DEVICE_TOKEN` 유지(값을 소스나 GitHub에 올리지 말 것).
- 기존 `requirements.txt`의 `functions-framework`, `google-cloud-firestore`, `openai`, `flask` 호환성 확인.
- GitHub에 코드를 추가한 것만으로 Cloud Run은 변경되지 않음. 관리자가 배포해야 적용됨.
- 배포 후에는 기존 `/chat`, `/transcribe`, `/tts` 회귀 테스트 필요. **ESP32 전원을 켜지 않고 소프트웨어 테스트부터 실시**.

## 새 API 사양
동일하게 `Authorization: Bearer <HYOJASON_DEVICE_TOKEN>` 헤더와 `Content-Type: application/json`이 필요함.

1. `POST /device/status`
```json
{"deviceId":"hyojason-001","battery":85,"networkName":"Wi-Fi","latitude":37.0,"longitude":127.0}
```
- Firestore `devices/hyojason-001`의 `online:true`, `lastSeenAt`, 옵션 배터리·네트워크·GPS 위치를 서버 타임스탬프와 함께 저장함.
- **GPS 좌표와 배터리 수치를 받지 않았다면 업데이트하지 않음. 임의 데이터를 실제 위치로 사용하지 말 것.**
- 앱은 마지막 heartbeat가 2분을 넘으면 오프라인으로 판정하려 함. 최종 화면 갱신 정책은 추가 테스트 필요.

2. `POST /device/emergency`
```json
{"deviceId":"hyojason-001","eventId":"button-unique-event-001"}
```
- Firestore `devices/hyojason-001/notifications`에 `type:"warning"` 알림 저장.
- `eventId`가 있으면 같은 ID로 중복 요청 시 알림 문서 중복 생성 방지.
- **FCM 푸시, 전화, 문자, 긴급 구조기관 연결은 아직 구현되지 않음.** 보호자 앱의 알림 탭에서 조회되는 것만으로 긴급 연락 기능이 완성된 것은 아님.
- 실제 기기에서 서버로 보내는 ESP32 코드 역시 추후 구현·검증 필요.

## 안전과 보안
- ESP32 스피커 과열/탄 냄새 문제가 해결되고 전문가가 확인하기 전까지 기기 전원을 켜지 말 것.
- 기기 인증 토큰을 Flutter 클라이언트/채팅/GitHub에 저장하지 말 것.
- 긴급호출은 응급 구조 시스템의 대체재가 아니며 실패 재시도·보호자 확인·FCM 알림·장애 시 대체 채널을 별도로 검증해야 함.
- **아직 배포하거나 실제 Cloud Run/Flutter 환경에서 실행 테스트하지 않았음.**
