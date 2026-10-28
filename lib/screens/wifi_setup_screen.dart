import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// 설정용 ESP32 AP에 접속한 후 주변 네트워크를 조회합니다.
/// AP 자체에는 인터넷이 없으며, 스마트폰 Wi-Fi에서 먼저 연결해야 합니다.
class WifiSetupScreen extends StatefulWidget {
  const WifiSetupScreen({super.key});
  @override
  State<WifiSetupScreen> createState() => _WifiSetupScreenState();
}

class _WifiSetupScreenState extends State<WifiSetupScreen> {
  static const base = 'http://192.168.4.1';
  final client = http.Client();
  bool loading = false;
  String? error;
  List<Map<String, dynamic>> networks = [];

  @override
  void dispose() {
    client.close();
    super.dispose();
  }

  Future<void> scan() async {
    setState(() { loading = true; error = null; });
    try {
      final response = await client.get(Uri.parse('$base/networks'))
          .timeout(const Duration(seconds: 20));
      if (response.statusCode != 200) throw StateError('기기 응답: ${response.statusCode}');
      final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final items = (data['networks'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>().toList();
      items.sort((a, b) => ((b['rssi'] as num?) ?? -100)
          .compareTo((a['rssi'] as num?) ?? -100));
      if (mounted) setState(() => networks = items);
    } catch (_) {
      if (mounted) setState(() => error =
          '기기에 연결하지 못했어요. 휴대폰 Wi-Fi 설정에서 Hyojason-... 네트워크에 연결한 뒤 다시 검색해 주세요.');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> connect(Map<String, dynamic> network) async {
    final ssid = (network['ssid'] ?? '').toString();
    final secured = network['secured'] == true;
    final controller = TextEditingController();
    final password = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('$ssid 연결'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(secured ? 'Wi-Fi 비밀번호를 입력하세요.' : '비밀번호가 없는 네트워크입니다.'),
          if (secured) TextField(
            controller: controller,
            obscureText: true,
            autofocus: true,
            decoration: const InputDecoration(labelText: '비밀번호'),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext),
              child: const Text('취소')),
          FilledButton(onPressed: () =>
              Navigator.pop(dialogContext, secured ? controller.text : ''),
              child: const Text('연결')),
        ],
      ),
    );
    controller.dispose();
    if (password == null || !mounted) return;
    setState(() { loading = true; error = null; });
    try {
      final response = await client.post(
        Uri.parse('$base/connect'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'ssid': ssid, 'password': password}),
      ).timeout(const Duration(seconds: 24));
      if (response.statusCode != 200) {
        throw StateError(response.statusCode == 422
            ? 'Wi-Fi 연결 실패: 비밀번호 또는 신호를 확인하세요.'
            : '기기 연결 오류 (HTTP ${response.statusCode})');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$ssid 연결 성공! 기기가 설정을 저장했어요.')),
        );
      }
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('네트워크 설정')),
    body: ListView(padding: const EdgeInsets.all(20), children: [
      const Card(child: Padding(
        padding: EdgeInsets.all(16),
        child: Text('① 효자손 기기에 전원을 연결하세요.\n'
            '② 처음 연결할 때 휴대폰의 Wi-Fi 설정에서 Hyojason-...에 접속하세요.\n'
            '③ 설정망 비밀번호를 입력한 후 앱으로 돌아와 검색하세요.\n'
            '④ 아래에서 실제 사용할 2.4GHz Wi-Fi를 선택하세요.\n\n'
            '기존 Wi-Fi가 연결된 기기는 시리얼 /wifi-setup 명령으로 설정망을 열 수 있습니다.'),
      )),
      const SizedBox(height: 12),
      FilledButton.icon(
        onPressed: loading ? null : scan,
        icon: const Icon(Icons.wifi_find),
        label: Text(loading ? '검색 중...' : '주변 Wi-Fi 검색'),
      ),
      if (loading) const Padding(
        padding: EdgeInsets.all(16), child: LinearProgressIndicator()),
      if (error != null) Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(error!, style: const TextStyle(color: Colors.red))),
      ...networks.map((network) => Card(
        child: ListTile(
          leading: const Icon(Icons.wifi),
          title: Text((network['ssid'] ?? '').toString()),
          subtitle: Text('신호 ${network['rssi'] ?? '?'} dBm'),
          trailing: Icon(network['secured'] == true
              ? Icons.lock_outline : Icons.lock_open),
          onTap: loading ? null : () => connect(network),
        ),
      )),
      const SizedBox(height: 16),
      const Text('현재 방식은 Android 앱용 초기 연결 기능입니다. '
        '연결 성공 후에는 기기가 저장된 Wi-Fi로 자동 연결합니다. '
        '기기 설정망은 민감한 비밀번호를 전달하므로 공공장소에서 사용하지 말고 '
        '기기별 설정망 암호를 반드시 변경하세요.'),
    ]),
  );
}
