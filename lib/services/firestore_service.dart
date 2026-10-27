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
  Future<bool> isAuthorized() async {
    if (auth.currentUser == null) return false;
    final document = await device.collection('guardians').doc(uid).get();
    return document.exists && document.data()?['enabled'] == true;
  }
  Stream<QuerySnapshot<Map<String, dynamic>>> conversations() =>
      device.collection('conversations').orderBy('createdAt', descending: true).limit(150).snapshots();
  Stream<DocumentSnapshot<Map<String, dynamic>>> deviceStatus() => device.snapshots();
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
