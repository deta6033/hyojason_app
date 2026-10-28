import os
import hmac
import logging
import io
import wave

from google.cloud import firestore
import functions_framework
from flask import jsonify, Response
from openai import OpenAI, OpenAIError
import firebase_admin
from firebase_admin import messaging, auth as firebase_auth
from datetime import datetime
from zoneinfo import ZoneInfo


# =====================================================
# 효자손 Cloud Run AI 서버
#
# GET  /      : 서버 정상 작동 확인
# POST /      : 기존 ESP32 기기 인증 테스트
# POST /chat  : 실제 AI 텍스트 대화
#
# 환경 변수:
# OPENAI_API_KEY
# HYOJASON_DEVICE_TOKEN
# =====================================================


# AI 모델 설정
# 초기 개발에서는 비용과 응답 속도를 고려한 모델 사용
AI_MODEL = "gpt-4.1-mini"

# 입력 및 출력 제한
MAX_MESSAGE_LENGTH = 500
MAX_OUTPUT_TOKENS = 200


# =====================================================
# 1. 기기 인증 검사
# =====================================================
def check_device_auth(request):
    """
    Authorization 헤더의 Bearer 토큰이
    서버의 기기 인증 토큰과 일치하는지 확인.
    """

    saved_token = os.environ.get(
        "HYOJASON_DEVICE_TOKEN", ""
    )

    if not saved_token:
        return False

    auth_header = request.headers.get(
        "Authorization", ""
    )

    prefix = "Bearer "

    if not auth_header.startswith(prefix):
        return False

    received_token = auth_header[len(prefix):]

    return hmac.compare_digest(
        received_token,
        saved_token
    )


# =====================================================
# 2. AI 답변 생성
# =====================================================
def generate_ai_reply(message):
    """
    사용자 질문을 OpenAI API에 전달하고
    답변 텍스트를 반환.
    """

    client = OpenAI(
        api_key=os.environ["OPENAI_API_KEY"],
        timeout=25.0,
        max_retries=0
    )

    response = client.responses.create(
        model=AI_MODEL,

        # 서버가 이전 응답을 저장하지 않도록 설정
        store=False,

        instructions=(
            "너는 '효자손'이라는 어르신 돌봄 AI의 "
            "친절하고 차분한 음성 대화 도우미다. "
            "항상 자연스러운 한국어로 대답한다. "
            "답변은 듣기 편하게 짧고 명확하게 한다. "
            "질문에 필요한 내용부터 답한다. "
            "의료 진단이나 약물 변경을 단정하지 않는다. "
            "응급 상황에서는 즉시 긴급 도움을 요청하도록 안내한다. "
            "너는 실제 보호자나 의료진을 대신하지 않는다."
        ),

        input=message,

        max_output_tokens=MAX_OUTPUT_TOKENS
    )

    return response.output_text.strip()


# =====================================================
# 3. JSON 응답을 반환하는 편의 함수
# =====================================================
def error_response(message, status_code):
    """
    클라이언트에 에러 메시지와
    HTTP 상태 코드를 함께 반환.
    """

    return jsonify({
        "status": "error",
        "error": message
    }), status_code

# ==========================================
# 효자손 음성 인식(STT)
# ==========================================

STT_MODEL = "gpt-4o-mini-transcribe"
MAX_AUDIO_BYTES = 120000


def transcribe_audio(wav_data):
    """
    ESP32에서 받은 WAV 파일을
    OpenAI API로 전송해 한국어로 변환한다.
    """

    client = OpenAI(
        api_key=os.environ["OPENAI_API_KEY"],
        timeout=40.0,
        max_retries=0
    )

    result = client.audio.transcriptions.create(
        model=STT_MODEL,
        file=("speech.wav", wav_data, "audio/wav"),
        language="ko"
    )

    return result.text.strip()


def validate_audio(wav_data):
    """
    WAV 데이터가 16kHz, 16비트, 모노인지 검사한다.
    """

    try:
        with wave.open(io.BytesIO(wav_data), "rb") as audio:
            return (
                audio.getnchannels() == 1
                and audio.getsampwidth() == 2
                and audio.getframerate() == 16000
                and 16000 <= audio.getnframes() <= 48000
            )

    except (wave.Error, EOFError, ValueError):
        return False

# =====================================================
# 효자손 TTS 설정
# =====================================================

TTS_MODEL = "gpt-4o-mini-tts"
TTS_VOICE = "alloy"

# 긴 텍스트로 불필요하게 비용이 발생하지 않도록 제한
MAX_TTS_CHARACTERS = 500


# =====================================================
# AI 답변을 음성으로 변환
# =====================================================
def generate_speech(text):
    """
    한국어 텍스트를 OpenAI TTS로 변환한다.

    반환값:
        WAV 형식의 바이너리 오디오 데이터
    """

    client = OpenAI(
        api_key=os.environ["OPENAI_API_KEY"],
        timeout=60.0,
        max_retries=0
    )

    response = client.audio.speech.create(
        model=TTS_MODEL,
        voice=TTS_VOICE,

        input=text,

        # WAV 파일로 생성
        response_format="wav",

        # 어르신이 듣기 편한 말투
        instructions=(
            "한국어로 자연스럽고 따뜻하게 말하세요. "
            "어르신이 이해하기 쉽도록 "
            "또렷하게 발음하고 차분하게 말하세요."
        )
    )

    # 생성한 오디오 바이트 반환
    return response.content

# =====================================================
# 효자손 Firestore 대화 기록 저장
# =====================================================

FIRESTORE_PROJECT_ID = "hyojason-512909"
DEVICE_ID = "hyojason-001"


def save_conversation(question, reply):
    """
    AI와 나눈 질문·답변을 Firestore에 저장한다.

    저장 위치:
    devices/hyojason-001/conversations/{자동 문서 ID}

    Cloud Run 서비스 계정으로 인증하므로
    별도의 Firebase 비밀키 파일은 필요하지 않다.
    """

    # 기존 Google Cloud 프로젝트의 Firestore 사용
    db = firestore.Client(
        project=FIRESTORE_PROJECT_ID
    )

    # 기기별 대화 기록 컬렉션
    conversations = (
        db.collection("devices")
          .document(DEVICE_ID)
          .collection("conversations")
    )

    # Firestore가 문서 ID를 자동 생성
    conversations.add({
        "question": question,
        "reply": reply,
        "createdAt": firestore.SERVER_TIMESTAMP,
        "source": "cloud-run",
        "deviceId": DEVICE_ID
    })


# =====================================================
# 기기 상태/GPS/긴급호출: 기존 기기 Bearer 인증 사용
# =====================================================
def _valid_number(value, minimum, maximum):
    """GPS/배터리 입력값의 자료형과 허용 범위를 검사한다."""
    if isinstance(value, bool) or not isinstance(value, (float, int)):
        return None
    return value if minimum <= value <= maximum else None


def _guardian_from_token(request):
    """Firebase ID 토큰을 확인해 등록된 보호자만 허용합니다."""
    bearer = request.headers.get("Authorization", "")
    if not bearer.startswith("Bearer "):
        return None
    if not firebase_admin._apps:
        firebase_admin.initialize_app()
    try:
        decoded = firebase_auth.verify_id_token(bearer[7:])
        uid = decoded["uid"]
        root = firestore.Client(project=FIRESTORE_PROJECT_ID).collection(
            "devices").document(DEVICE_ID)
        guardian = root.collection("guardians").document(uid).get()
        return root if guardian.exists and (guardian.to_dict() or {}).get("enabled") is True else None
    except Exception:
        logging.exception("Guardian authentication failed")
        return None


def handle_daily_summary(request):
    """실제 대화만 근거로 오늘의 AI 하루 요약을 생성합니다."""
    device = _guardian_from_token(request)
    if device is None:
        return error_response("보호자 인증이 필요합니다.", 401)
    today = datetime.now(ZoneInfo("Asia/Seoul")).date().isoformat()
    body = request.get_json(silent=True) if request.is_json else None
    if not isinstance(body, dict) or body.get("date") != today:
        return error_response("오늘 날짜의 요약만 생성할 수 있습니다.", 400)
    try:
        # 가장 최근 데이터만 사용. AI가 없는 내용을 추정하지 않도록 지시합니다.
        docs = device.collection("conversations").order_by(
            "createdAt", direction=firestore.Query.DESCENDING
        ).limit(100).stream()
        lines = []
        for snapshot in docs:
            data = snapshot.to_dict() or {}
            when = data.get("createdAt")
            if when is None or when.astimezone(ZoneInfo("Asia/Seoul")).date().isoformat() != today:
                continue
            question = str(data.get("question") or "").strip()
            answer = str(data.get("reply") or "").strip()
            if question:
                lines.append(f"어르신: {question[:500]}")
            if answer:
                lines.append(f"AI: {answer[:500]}")
            if len(lines) >= 60:
                break
        if not lines:
            return error_response("오늘 기록된 대화가 없습니다.", 404)
        if not os.environ.get("OPENAI_API_KEY"):
            return error_response("AI 서버 설정 오류", 503)
        response = OpenAI(
            api_key=os.environ["OPENAI_API_KEY"],
            timeout=25.0, max_retries=0,
        ).responses.create(
            model=AI_MODEL,
            store=False,
            instructions=(
                "너는 어르신의 대화 내용을 보호자에게 요약한다. "
                "제공된 대화에 실제로 언급된 정보만 두세 문장으로 요약하라. "
                "식사·복약·외출 사실은 명시적으로 확인된 경우만 언급하라. "
                "감정 상태나 건강 문제를 진단하거나 추정하지 마라. "
                "민감한 개인정보를 불필요하게 반복하지 마라. "
                "한국어로 간결하게 작성하라."
            ),
            input="\n".join(lines),
            max_output_tokens=260,
        )
        summary = response.output_text.strip()
        if not summary:
            return error_response("요약 생성 결과가 비어 있습니다.", 502)
        device.collection("dailySummaries").document(today).set({
            "summary": summary,
            "date": today,
            "conversationCount": len(lines),
            "updatedAt": firestore.SERVER_TIMESTAMP,
            "source": "openai-conversation-summary",
        })
        return jsonify({"status": "success", "summary": summary, "date": today}), 200
    except Exception:
        logging.exception("Daily summary generation failed")
        return error_response("AI 하루 요약 생성에 실패했습니다.", 500)


def handle_device_config(request):
    """인증된 ESP32에 목표 음량 설정만 반환합니다."""
    root = firestore.Client(project=FIRESTORE_PROJECT_ID).collection("devices").document(DEVICE_ID)
    settings = root.collection("controls").document("audio").get()
    value = (settings.to_dict() or {}).get("volumePercent") if settings.exists else 25
    if isinstance(value, bool) or not isinstance(value, int) or not 0 <= value <= 100:
        value = 25
    return jsonify({"status": "success", "volumePercent": value}), 200


def send_emergency_push(device):
    """권한 있는 보호자 기기에게 긴급 푸시를 개별 전송합니다."""
    if not firebase_admin._apps:
        firebase_admin.initialize_app()
    delivered = 0
    for guardian in device.collection("guardians").stream():
        info = guardian.to_dict() or {}
        if info.get("enabled") is not True:
            continue
        for registration in guardian.reference.collection("pushTokens").stream():
            token = (registration.to_dict() or {}).get("token")
            if not isinstance(token, str) or not token:
                continue
            try:
                messaging.send(messaging.Message(
                    token=token,
                    notification=messaging.Notification(
                        title="효자손 긴급호출",
                        body="기기에서 긴급호출이 발생했습니다. 즉시 확인해 주세요.",
                    ),
                    data={"type": "emergency", "deviceId": DEVICE_ID},
                    android=messaging.AndroidConfig(
                        priority="high",
                        notification=messaging.AndroidNotification(
                            channel_id="hyojason_emergency",
                            priority="high",
                            sound="default",
                        ),
                    ),
                ))
                delivered += 1
            except Exception:
                logging.exception("Failed to send guardian push")
    return delivered


def handle_device_report(request):
    """Cloud Run에서 기기 상태 또는 긴급호출 기록을 Firestore에 저장한다.

    기존 hello_http의 공통 기기 인증을 통과한 요청만 이 함수를 호출한다.
    """
    if request.content_length is not None and request.content_length > 4096:
        return error_response("요청 크기가 너무 큽니다.", 413)
    if not request.is_json:
        return error_response("JSON 요청만 허용합니다.", 415)
    body = request.get_json(silent=True)
    if not isinstance(body, dict):
        return error_response("올바른 JSON이 아닙니다.", 400)
    if body.get("deviceId", DEVICE_ID) != DEVICE_ID:
        return error_response("알 수 없는 기기 ID입니다.", 403)

    try:
        device = firestore.Client(project=FIRESTORE_PROJECT_ID).collection(
            "devices").document(DEVICE_ID)

        if request.path == "/device/status":
            update = {
                "online": True,
                "lastSeenAt": firestore.SERVER_TIMESTAMP,
            }
            battery = _valid_number(body.get("battery"), 0, 100)
            if battery is not None:
                update["battery"] = int(battery)
            network = body.get("networkName")
            if isinstance(network, str) and len(network) <= 64:
                update["networkName"] = network
            latitude = _valid_number(body.get("latitude"), -90, 90)
            longitude = _valid_number(body.get("longitude"), -180, 180)
            if latitude is not None and longitude is not None:
                update["location"] = {
                    "latitude": latitude,
                    "longitude": longitude,
                    "updatedAt": firestore.SERVER_TIMESTAMP,
                }
            device.set(update, merge=True)
            return jsonify({"status": "success", "deviceId": DEVICE_ID}), 200

        # 새 긴급 이벤트에서만 FCM 전송. 동일 eventId는 중복 전송하지 않는다.
        event_id = body.get("eventId")
        if event_id is not None and (
            not isinstance(event_id, str) or
            not (1 <= len(event_id) <= 96) or
            not all(ch.isascii() and (ch.isalnum() or ch in "-_") for ch in event_id)
        ):
            return error_response("eventId 형식이 잘못되었습니다.", 400)
        event = {
            "title": "효자손 긴급호출",
            "message": "효자손 기기에서 긴급호출 버튼이 눌렸습니다. 즉시 확인해 주세요.",
            "type": "warning",
            "read": False,
            "time": firestore.SERVER_TIMESTAMP,
            "source": "device-emergency",
            "deviceId": DEVICE_ID,
        }
        notifications = device.collection("notifications")
        created = True
        if event_id:
            # 동일한 eventId 재전송이 알림을 여러 개 만들지 않도록 한다.
            ref = notifications.document("emergency_" + event_id)
            try:
                ref.create(event)
            except Exception as exc:
                from google.api_core.exceptions import Conflict
                if not isinstance(exc, Conflict):
                    raise
                created = False
        else:
            ref = notifications.document()
            ref.set(event)
        delivered = 0
        if created:
            try:
                delivered = send_emergency_push(device)
            except Exception:
                logging.exception("Emergency push dispatch failed")
        logging.warning("Emergency event recorded for device %s", DEVICE_ID)
        return jsonify({"status": "success", "eventId": ref.id,
                        "pushSent": delivered}), 200
    except Exception:
        logging.exception("Device report save failed")
        return error_response("기기 이벤트 저장에 실패했습니다.", 500)


# =====================================================
# 4. Cloud Run HTTP 진입점
# =====================================================
@functions_framework.http
def hello_http(request):
    """
    Cloud Run에서 HTTP 요청을 처리하는 함수.
    기존 함수 진입점 이름을 유지한다.
    """

    # ---------------------------------------------
    # GET / : 서버 상태 확인
    # ---------------------------------------------
    if request.method == "GET":

        if request.path == "/device/config":
            if not check_device_auth(request):
                return error_response("인증되지 않은 기기입니다.", 401)
            try:
                return handle_device_config(request)
            except Exception:
                logging.exception("Device config read failed")
                return error_response("설정을 읽지 못했습니다.", 500)

        if request.path != "/":
            return error_response(
                "존재하지 않는 경로입니다.", 404
            )

        return jsonify({
            "status": "success",
            "device": "Hyojason",
            "message": "효자손 서버 정상 작동"
        }), 200

    # 보호자 전용 AI 하루 요약은 Firebase ID 토큰으로 별도 인증합니다.
    if request.method == "POST" and request.path == "/summary":
        return handle_daily_summary(request)

    # POST 외의 메서드는 허용하지 않음
    if request.method != "POST":
        return error_response(
            "허용되지 않은 요청입니다.", 405
        )

    # ---------------------------------------------
    # 공통 기기 인증
    # ---------------------------------------------
    if not os.environ.get(
        "HYOJASON_DEVICE_TOKEN"
    ):
        return error_response(
            "기기 인증 설정이 완료되지 않았습니다.",
            503
        )

    if not check_device_auth(request):
        return error_response(
            "인증되지 않은 기기입니다.",
            401
        )

    # ---------------------------------------------
    # POST / : 기존 인증 성공 테스트 유지
    # ---------------------------------------------
    if request.path == "/":

        return jsonify({
            "status": "success",
            "message": "효자손 기기 인증 성공"
        }), 200

    # ---------------------------------------------
    # POST /chat : 실제 AI 대화
    # ---------------------------------------------
    # 기기 heartbeat/GPS 및 긴급버튼 이벤트는 기존 Bearer 인증 후 처리한다.
    if request.path in ("/device/status", "/device/emergency"):
        return handle_device_report(request)

    if request.path == "/chat":

        # 지나치게 큰 요청 방지
        if (
            request.content_length is not None
            and request.content_length > 4096
        ):
            return error_response(
                "요청 크기가 너무 큽니다.", 413
            )

        # JSON만 허용
        if not request.is_json:
            return error_response(
                "JSON 요청만 허용합니다.", 415
            )

        data = request.get_json(silent=True)

        if not isinstance(data, dict):
            return error_response(
                "올바른 JSON이 아닙니다.", 400
            )

        message = data.get("message")

        if not isinstance(message, str):
            return error_response(
                "message 문자열이 필요합니다.", 400
            )

        message = message.strip()

        if not message:
            return error_response(
                "질문을 입력해 주세요.", 400
            )

        if len(message) > MAX_MESSAGE_LENGTH:
            return error_response(
                "질문이 너무 깁니다.", 400
            )

        # OpenAI API 키 설정 확인
        if not os.environ.get("OPENAI_API_KEY"):
            return error_response(
                "AI 서버 설정이 완료되지 않았습니다.",
                503
            )

        try:
            # OpenAI API 호출
            reply = generate_ai_reply(message)

            if not reply:
                return error_response(
                    "AI 답변이 비어 있습니다.", 502
                )

            # AI 답변을 Firestore에 저장
            # 저장에 실패해도 이미 생성한 AI 답변은 반환
            try:
                save_conversation(message, reply)

            except Exception:
                logging.exception(
                    "Firestore conversation save failed"
                )

            # 기존 AI 대화 응답은 그대로 유지
            return jsonify({
                "status": "success",
                "reply": reply
            }), 200

        except OpenAIError:
            # API 키나 내부 오류 세부 내용을
            # 클라이언트에 노출하지 않음
            logging.exception("OpenAI request failed")

            return error_response(
                "AI 서비스 요청에 실패했습니다.",
                502
            )

        except Exception:
            logging.exception("Unexpected chat error")

            return error_response(
                "서버 내부 오류가 발생했습니다.",
                500
            )

    # ==========================================
    # POST /transcribe : 음성 인식
    # ==========================================
    if request.path == "/transcribe":

        # WAV 파일만 허용
        if request.mimetype != "audio/wav":
            return error_response(
                "WAV 파일만 허용합니다.", 415
            )

        # 음성 데이터 크기 제한
        wav_data = request.stream.read(
            MAX_AUDIO_BYTES + 1
        )

        if len(wav_data) > MAX_AUDIO_BYTES:
            return error_response(
                "음성 데이터가 너무 큽니다.", 413
            )

        # WAV 형식 검사
        if not validate_audio(wav_data):
            return error_response(
                "WAV 형식이 올바르지 않습니다.", 400
            )

        # OpenAI API 키 확인
        if not os.environ.get("OPENAI_API_KEY"):
            return error_response(
                "OpenAI API 설정 오류", 503
            )

        try:
            # 음성 인식 실행
            recognized_text = transcribe_audio(wav_data)

            return jsonify({
                "status": "success",
                "text": recognized_text
            }), 200

        except OpenAIError:
            logging.exception("STT API error")

            return error_response(
                "음성 인식 API 오류", 502
            )

        except Exception:
            logging.exception("STT server error")

            return error_response(
                "음성 인식 서버 오류", 500
            )
    
        # ==========================================
    # POST /tts : 한국어 음성 생성
    # ==========================================
    if request.path == "/tts":

        # 요청 크기 제한
        if (
            request.content_length is not None
            and request.content_length > 4096
        ):
            return error_response(
                "요청 크기가 너무 큽니다.", 413
            )

        # JSON 요청인지 확인
        if not request.is_json:
            return error_response(
                "JSON 요청만 허용합니다.", 415
            )

        data = request.get_json(silent=True)

        if not isinstance(data, dict):
            return error_response(
                "잘못된 JSON 요청입니다.", 400
            )

        # 음성으로 만들 텍스트
        text = data.get("text")

        if not isinstance(text, str):
            return error_response(
                "text 문자열이 필요합니다.", 400
            )

        text = text.strip()

        if not text:
            return error_response(
                "음성으로 변환할 텍스트가 없습니다.", 400
            )

        if len(text) > MAX_TTS_CHARACTERS:
            return error_response(
                "텍스트가 너무 깁니다.", 400
            )

        # OpenAI API 키 확인
        if not os.environ.get("OPENAI_API_KEY"):
            return error_response(
                "OpenAI API 설정 오류", 503
            )

        try:
            # 실제 TTS API 호출
            audio_data = generate_speech(text)

            if not audio_data:
                return error_response(
                    "음성 생성 결과가 비어 있습니다.", 502
                )

            # WAV 파일 데이터를 직접 반환
            return Response(
                audio_data,
                status=200,
                mimetype="audio/wav",
                headers={
                    "Content-Disposition":
                        'attachment; filename="hyojason.wav"',
                    "Cache-Control": "no-store"
                }
            )

        except OpenAIError:
            logging.exception("TTS API error")

            return error_response(
                "음성 생성 API 오류", 502
            )

        except Exception:
            logging.exception("TTS server error")

            return error_response(
                "음성 생성 서버 오류", 500
            )

    # ---------------------------------------------
    # 잘못된 API 경로
    # ---------------------------------------------
    return error_response(
        "존재하지 않는 경로입니다.", 404
    )