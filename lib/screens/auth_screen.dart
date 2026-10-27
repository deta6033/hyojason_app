import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// 계정 생성은 Firebase Console 관리자만 수행한다. 앱에서는 로그인만 지원한다.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}
class _AuthScreenState extends State<AuthScreen> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool busy = false;
  String? error;
  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }
  Future<void> login() async {
    if (busy) return;
    setState(() { busy = true; error = null; });
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.text.trim(), password: password.text);
    } on FirebaseAuthException catch (ex) {
      if (mounted) setState(() => error = '로그인 실패: ${ex.code}');
    } catch (_) {
      if (mounted) setState(() => error = '서버 연결을 확인해 주세요.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('효자손 보호자 로그인')),
    body: Center(child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 440),
      child: SingleChildScrollView(padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.volunteer_activism, size: 66),
          const SizedBox(height: 12),
          const Text('등록된 보호자 계정으로 로그인해 주세요.'),
          const SizedBox(height: 24),
          TextField(controller: email, keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: '이메일')),
          const SizedBox(height: 12),
          TextField(controller: password, obscureText: true,
            decoration: const InputDecoration(labelText: '비밀번호'),
            onSubmitted: (_) => login()),
          if (error != null) Padding(padding: const EdgeInsets.only(top: 12),
            child: Text(error!, style: const TextStyle(color: Colors.red))),
          const SizedBox(height: 20),
          SizedBox(width: double.infinity, child: FilledButton(
            onPressed: busy ? null : login,
            child: Text(busy ? '로그인 중...' : '로그인'))),
        ]),
      ),
    )),
  );
}
