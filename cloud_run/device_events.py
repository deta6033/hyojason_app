"""효자손 Cloud Run 기기 이벤트 처리 모듈.

기존 hello_http 함수에서 dispatch_device_event(request)를 호출해 사용합니다.
이 모듈만 GitHub에 추가해도 Cloud Run에 자동 배포되지는 않습니다.
기기 토큰은 환경변수 또는 Secret Manager로만 전달하세요.
"""
import hmac
import os
from datetime import datetime, timezone

from google.cloud import firestore

DEVICE_ID = "hyojason-001"
_db = None


def _database():
    global _db
    if _db is None:
        _db = firestore.Client()
    return _db


def _error(message, status=400):
    return {"status": "error", "message": message}, status


def _authenticate(request):
    expected = os.environ.get("HYOJASON_DEVICE_TOKEN", "")
    received = request.headers.get("X-Device-Token", "")
    # 기존 엔드포인트와 인증 헤더 형식이 같아야 합니다.
    return bool(expected) and hmac.compare_digest(expected, received)


def _number(value, low, high):
    if isinstance(value, bool) or not isinstance(value, (float, int)):
        return None
    return value if low <= value <= high else None


def dispatch_device_event(request):
    """기기 상태/긴급 호출 요청만 처리합니다. 그 외 경로는 None 반환."""
    path = request.path.rstrip("/")
    if path not in ("/device/status", "/device/emergency"):
        return None

    if request.method != "POST":
        return _error("POST only", 405)
    if not _authenticate(request):
        return _error("Unauthorized device", 401)

    payload = request.get_json(silent=True)
    if not isinstance(payload, dict):
        return _error("Expected JSON object")
    if payload.get("deviceId", DEVICE_ID) != DEVICE_ID:
        return _error("Invalid deviceId", 403)

    device = _database().collection("devices").document(DEVICE_ID)
    now = firestore.SERVER_TIMESTAMP

    if path == "/device/status":
        data = {"online": True, "lastSeenAt": now}
        battery = _number(payload.get("battery"), 0, 100)
        if battery is not None:
            data["battery"] = int(battery)
        network = payload.get("networkName")
        if isinstance(network, str) and len(network) <= 64:
            data["networkName"] = network

        latitude = _number(payload.get("latitude"), -90, 90)
        longitude = _number(payload.get("longitude"), -180, 180)
        if latitude is not None and longitude is not None:
            data["location"] = {
                "latitude": latitude,
                "longitude": longitude,
                "updatedAt": now,
            }
        device.set(data, merge=True)
        return {"status": "success", "deviceId": DEVICE_ID}, 200

    # 버튼 입력 이벤트 기록: 서버가 저장하며, 앱은 기존 notifications 스트림으로 조회.
    # 이 기록만으로 FCM 푸시/전화/SMS가 발송되는 것은 아닙니다.
    event = {
        "title": "효자손 긴급호출",
        "message": "기기에서 긴급 버튼 신호를 수신했습니다. 즉시 상태를 확인하세요.",
        "type": "warning",
        "read": False,
        "time": now,
        "source": "device-emergency",
        "deviceId": DEVICE_ID,
    }
    ref = device.collection("notifications").document()
    ref.set(event)
    return {"status": "success", "eventId": ref.id}, 200
