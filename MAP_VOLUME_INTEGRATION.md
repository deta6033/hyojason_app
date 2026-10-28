# 지도 탭 및 기기 음량 제어 통합

## 보호자 앱
- 하단 메뉴: 홈 / 기록 / 복약 / 알림 / 지도 / 설정 (총 6개)
- 지도: Firestore `devices/hyojason-001` 문서의 `location.latitude`, `location.longitude`, `location.updatedAt`을 읽습니다. `location.lat/lng` 및 최상위 `latitude/longitude`도 호환됩니다.
- 기기가 좌표를 한 번도 보고하지 않으면 지도에 가짜 위치를 표시하지 않습니다.
- OpenStreetMap 타일을 사용합니다. 외부 지도 서비스 접근이 필요하고, 위치 정보는 권한 있는 보호자에게만 표시해야 합니다.
- 설정 > 효자손 기기 아래 음량 슬라이더 추가. `devices/hyojason-001/controls/audio` 문서에 `volumePercent` (0~100), `updatedAt`, `updatedBy`를 저장합니다.

## 적용 단계
1. 이 PR을 병합하고 PC에서 `git pull` 또는 GitHub Desktop Pull origin.
2. `flutter pub get` 후 `flutter run -d chrome`으로 화면 확인.
3. Firebase Console > Firestore Database > Rules에서 바뀐 `firestore.rules`를 배포해야 슬라이더를 저장할 수 있습니다. GitHub 파일 변경만으로는 보안 규칙이 자동 배포되지 않습니다.
4. ESP32가 Cloud Run으로 GPS 및 상태를 보고해야 실제 위치가 표시됩니다. 본 변경에는 기기의 GPS 전송 코드를 포함하지 않았습니다.
5. 현재 ESP32는 Firestore 목표 음량을 읽지 않으므로 **슬라이더를 움직여도 실제 스피커 음량은 아직 바뀌지 않습니다.**
6. 다음 단계에서 인증된 ESP32용 서버 설정 조회 API와 설정 폴링 또는 동기화를 만들고, 펌웨어 `limitVolume`에서 안전한 최대 진폭으로 매핑해야 합니다. 적용 완료 ACK를 별도 필드에 기록하면 보호자 앱에서 실제 적용 여부를 표시할 수 있습니다.
7. 8Ω 1W 스피커 출력 한계는 UI의 100%와 무관합니다. 증폭기 이득/전원/발열을 재점검하고 펌웨어에서 안전한 상한을 강제해야 합니다.

## 검증 체크
- 권한 있는 보호자로 로그인 > 지도 탭 열기 > GPS 미보고 상태 안내
- 실제 좌표 문서가 있으면 지도에 마커가 위치하고 시각 표시
- 설정 > 음량 저장 후 Firestore controls/audio 문서 확인
- 권한 없는 Firebase 계정에서 지도 및 controls 접근 차단 확인
- Android 환경에서 지도 타일 네트워크 접근과 화면 가로폭 확인
- ESP32 실기기 음량 변경 및 ACK는 미구현/미검증
