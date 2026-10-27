# 효자손 실제 Firebase 연결 방법

기존 프로젝트 `hyojason-512909`, Firestore `(default)`, 기기 `hyojason-001` 사용.

1. Firebase Console > Authentication > 로그인 방법 > **이메일/비밀번호** 활성화.
2. Authentication > 사용자에서 보호자 계정 생성. 생성된 **UID** 복사.
3. Firestore > `devices / hyojason-001 / guardians / (보호자 UID)` 문서를 추가하고 `enabled` 필드를 **boolean true**로 저장. (기존 상위 문서가 비어 있더라도 하위 컬렉션 생성 가능.)
4. Firestore > 규칙에 저장소의 `firestore.rules` 내용을 붙여 넣고 게시. **전체 공개 규칙 사용 금지**.
5. PC에서 FlutterFire CLI를 설치하고 앱 프로젝트 루트에서 `flutterfire configure --project=hyojason-512909` 실행. Android 앱 ID는 기존 `com.example.hyojason_app`과 일치시킨다. `lib/firebase_options.dart` 및 Android 구성 생성 확인.
6. `flutter pub get`, `flutter run -d chrome` 또는 Android 실행 후 보호자 계정으로 로그인.
7. Firebase Console에 존재하는 실제 대화가 최근 AI 대화/지난 기록에 표시되는지 확인.

## 데이터 연결
- 대화 기록: Cloud Run이 `devices/hyojason-001/conversations`에 저장하며 앱은 읽기 전용.
- 복약 일정: 보호자가 앱에서 작성한 실제 데이터만 Firestore에 저장. 복약 **완료 여부는 아직 수집하지 않음**.
- 알림: 실제 이벤트가 기록되기 전까지 빈 목록. 기기 긴급 알림 발송 기능은 미완성.
- 기기 상태: `devices/hyojason-001`에 heartbeat, battery 등의 실제 정보가 없으므로 확인 불가 표시.
- 하루 요약: 기록된 실제 대화 개수만 표시. 식사/외출/복약 여부를 임의로 만들지 않음.

## 보안
- ESP32의 기기 토큰과 OpenAI API 키는 **앱에 넣지 않는다**.
- 인증된 보호자만 Firestore 규칙으로 읽기 권한을 얻는다.
- 기존 Cloud Run /chat POST는 기기 토큰이 필요하므로 앱이 직접 호출하지 않는다.
- 발열이 있었던 스피커/앰프 회로는 점검 전까지 켜지 않는다.
