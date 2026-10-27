# 효자손 기기 상태·긴급 이벤트 연동

## 구현 범위
- `lib/screens/device_monitor_screen.dart`: Firestore `devices/hyojason-001`에서 마지막 heartbeat, 네트워크, 배터리, GPS 위치를 읽는 화면.
- `cloud_run/device_events.py`: 기기에서 전송하는 상태·긴급 버튼 이벤트를 Firestore에 저장하는 **배포 전 준비 코드**.
- 기존 보호자 앱의 **알림 탭**은 `devices/hyojason-001/notifications`에서 서버가 만든 `type=warning` 긴급 이벤트를 표시할 수 있음.

## 서버 통합 (배포 전 검토 필수)
기존 Cloud Run의 `main.py` `hello_http(request)` 최상단에서 인증 로직과 충돌하지 않도록 아래 연결 코드를 검토해 추가하세요.

```python
from device_events import dispatch_device_event

def hello_http(request):
    event_response = dispatch_device_event(request)
    if event_response is not None:
        return event_response
    # 기존 /chat, /tts, /transcribe 라우팅 코드를 유지합니다.
    ...
```

서버에 `google-cloud-firestore`가 설치되어 있어야 합니다(기존 저장 기능에서 사용 중). `HYOJASON_DEVICE_TOKEN` 환경변수가 있고 기존 헤더 형식이 `X-Device-Token`인지 **실제 서버 코드와 대조**하세요. 다른 형식이라면 인증 로직을 통일해야 합니다. 신규 코드만 올리면 실제 Cloud Run에 반영되지 않습니다. ESP32 펌웨어에도 해당 경로로 JSON을 보내는 구현이 필요합니다.

### 예시 요청 본문 (실제 기기 없이 설계 확인)
- `POST /device/status`: `{"deviceId":"hyojason-001","battery":85,"networkName":"home-wifi","latitude":37.0,"longitude":127.0}`
- `POST /device/emergency`: `{"deviceId":"hyojason-001"}`

인증 토큰은 GitHub/앱 코드/문서에 저장하지 않습니다. 개발 중 임의로 온라인 상태를 생성하지 마세요. 과거 위치는 마지막 보고값이며 현재 위치를 보장하지 않습니다.

## 안전 및 남은 작업
1. **긴급 이벤트 Firestore 저장은 FCM 푸시 발송이 아닙니다.** 앱이 꺼져 있어도 받는 긴급 알림을 위해 FCM 토큰 등록 및 서버 발송 기능을 별도로 구현·검증해야 합니다.
2. 긴급 시스템은 신뢰성 테스트, 중복 방지, 전송 실패 시 재시도·확인 절차가 필요합니다. 실제 응급 구조 서비스 대체용이 아닙니다.
3. 기존 스피커 과열 문제로 ESP32 전원을 연결하지 마세요. 하드웨어 담당자의 안전 점검 후 기기 통합 테스트를 진행합니다.
4. 화면 및 백엔드 코드는 **GitHub에 추가되었으나 로컬 Flutter/Cloud Run에서 아직 실행 검증되지 않았습니다.**
