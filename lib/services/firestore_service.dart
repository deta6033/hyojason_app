import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/models.dart';

// 기존 Cloud Run에서 기록 중인 동일한 기기 경로를 사용한다.
class FirestoreService {
  static const deviceId = 'hyojason-001';
  final FirebaseFirestore db = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;
  DocumentReference<Map<String, dynamic>> get device => db.collection('devices').doc(deviceId);
  String get uid {
    final user = auth.currentUser;
    if (user == null) throw StateError('보호자 로그인이 필요합니다.');
    return user.uid;
  }
  // 토큰은 사용자별 하위 컬렉션에 보관하고 원본을 문서 ID에 쓰지 않습니다.
  String _tokenId(String token) => sha256.convert(utf8.encode(token)).toString();
  Future<void> savePushToken(String token) =>
      device.collection('guardians').doc(uid).collection('pushTokens')
          .doc(_tokenId(token)).set({
            'token': token,
            'platform': 'android',
            'updatedAt': FieldValue.serverTimestamp(),
          });
  Future<void> deletePushToken(String token) =>
      device.collection('guardians').doc(uid).collection('pushTokens')
          .doc(_tokenId(token)).delete();

  Future<bool> isAuthorized() async {
    if (auth.currentUser == null) return false;
    final document = await device.collection('guardians').doc(uid).get();
    return document.exists && document.data()?['enabled'] == true;
  }
  Stream<QuerySnapshot<Map<String, dynamic>>> conversations() =>
      device.collection('conversations').orderBy('createdAt', descending: true).limit(150).snapshots();
  Stream<DocumentSnapshot<Map<String, dynamic>>> deviceStatus() => device.snapshots();
  // 보호자가 지정한 목표 음량. 실제 ESP32 적용은 추후 펌웨어에서 구현.
  Stream<DocumentSnapshot<Map<String, dynamic>>> volumeSettings() =>
      device.collection('controls').doc('audio').snapshots();
  Future<void> saveTargetVolume(int percent) async {
    if (percent < 0 || percent > 100) {
      throw ArgumentError.value(percent, 'percent', '0~100이어야 합니다.');
    }
    await device.collection('controls').doc('audio').set({
      'volumePercent': percent,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': uid,
    });
  }
  // 생성된 AI 요약은 기기 서버가 쓰고 보호자는 읽기만 합니다.
  Stream<DocumentSnapshot<Map<String, dynamic>>> dailySummary(String date) =>
      device.collection('dailySummaries').doc(date).snapshots();
  Stream<DocumentSnapshot<Map<String, dynamic>>> voiceSettings() =>
      device.collection('controls').doc('ttsVoice').snapshots();
  Future<void> saveTTSVoice(String voice) async {
    if (!const {'alloy', 'nova', 'shimmer'}.contains(voice)) {
      throw ArgumentError.value(voice, 'voice', '허용되지 않은 음성입니다.');
    }
    await device.collection('controls').doc('ttsVoice').set({
      'voice': voice,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': uid,
    });
  }
  Stream<QuerySnapshot<Map<String, dynamic>>> medications() =>
      device.collection('medications').snapshots();
  Stream<QuerySnapshot<Map<String, dynamic>>> notifications() =>
      device.collection('notifications').orderBy('time', descending: true).limit(100).snapshots();
  Future<void> saveMedication(MedicationSchedule m) =>
      device.collection('medications').doc(m.id).set(m.toJson());
  Future<void> deleteMedication(String id) =>
      device.collection('medications').doc(id).delete();
  Future<void> addNotification(AppNotificationItem n) =>
      device.collection('notifications').doc(n.id).set({
        ...n.toJson(), 'time': Timestamp.fromDate(n.time),
      });
  Future<void> markRead(String id) =>
      device.collection('notifications').doc(id).update({'read': true});
  Future<void> markAllRead(Iterable<String> ids) async {
    final batch = db.batch();
    for (final id in ids) {
      batch.update(device.collection('notifications').doc(id), {'read': true});
    }
    await batch.commit();
  }
}
