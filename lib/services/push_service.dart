import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'firestore_service.dart';

/// Android 보호자에게 긴급 알림을 보내기 위한 FCM 토큰을 Firebase에 등록합니다.
/// 웹에서는 브라우저 알림 구성(VAPID, service worker) 전까지 실행하지 않습니다.
class PushService {
  PushService._();
  static final instance = PushService._();

  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<String>? _refreshSubscription;
  String? _registeredToken;

  Future<void> initialize() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;

    _authSubscription ??=
        FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (user == null) {
        _registeredToken = null;
        return;
      }
      try {
        final authorized = await FirestoreService().isAuthorized();
        if (!authorized) return;
        final messaging = FirebaseMessaging.instance;
        await messaging.requestPermission(alert: true, badge: true, sound: true);
        // ignore: deprecated_member_use
        final token = await messaging.getToken();
        if (token != null) await _register(token);
      } catch (e) {
        debugPrint('[FCM] 토큰 등록 실패: $e');
      }
    });

    // TODO: 현재 Firebase Messaging API의 register/onRegistered 방식으로 이행.
    _refreshSubscription ??=
        // ignore: deprecated_member_use
        FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
      try {
        if (FirebaseAuth.instance.currentUser != null &&
            await FirestoreService().isAuthorized()) {
          await _register(token);
        }
      } catch (e) {
        debugPrint('[FCM] 갱신 실패: $e');
      }
    });
  }

  Future<void> _register(String token) async {
    if (_registeredToken == token) return;
    await FirestoreService().savePushToken(token);
    _registeredToken = token;
  }

  /// 로그아웃 시 이 보호자 기기의 현재 토큰 등록을 해제합니다.
  Future<void> unregister() async {
    try {
      if (_registeredToken != null) {
        await FirestoreService().deletePushToken(_registeredToken!);
      }
    } catch (e) {
      debugPrint('[FCM] 토큰 해제 실패: $e');
    }
    _registeredToken = null;
  }
}
