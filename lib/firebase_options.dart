// Firebase Console에 등록된 효자손 Android/Web 앱의 공개 클라이언트 설정입니다.
// API 키는 서버 비밀키가 아니지만 Firebase 보안 규칙과 API 키 제한은 별도로 관리해야 합니다.
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError('이 플랫폼의 Firebase 설정은 아직 지원하지 않습니다.');
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCLbg-nc-DQrdqgALb9IrOtIQRRO4szKos',
    appId: '1:230429142822:web:b539082c07580578869be7',
    messagingSenderId: '230429142822',
    projectId: 'hyojason-512909',
    authDomain: 'hyojason-512909.firebaseapp.com',
    storageBucket: 'hyojason-512909.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCLbg-nc-DQrdqgALb9IrOtIQRRO4szKos',
    appId: '1:230429142822:android:43021778d4144005869be7',
    messagingSenderId: '230429142822',
    projectId: 'hyojason-512909',
    storageBucket: 'hyojason-512909.firebasestorage.app',
  );
}
