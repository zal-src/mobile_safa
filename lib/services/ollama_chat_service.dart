import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Service สำหรับเชื่อมต่อ Ollama (Local LLM)
/// ใช้ llama3.2:1b รันบนเครื่อง local
/// รองรับ streaming response
class OllamaChatService {
  OllamaChatService._() {
    _baseUrl = defaultBaseUrl;
  }
  static final OllamaChatService instance = OllamaChatService._();

  /// URL เริ่มต้นตาม Platform
  /// Android Emulator เข้าถึง Host Machine ผ่าน 10.0.2.2
  static String get defaultBaseUrl {
    if (!kIsWeb && Platform.isAndroid) {
      return 'http://10.0.2.2:11434';
    }
    return 'http://localhost:11434';
  }

  /// URL ของ Ollama server
  String _baseUrl = defaultBaseUrl;

  String get baseUrl => _baseUrl;
  set baseUrl(String url) {
    var trimmed = url.trim();
    if (trimmed.isEmpty) {
      _baseUrl = defaultBaseUrl;
      return;
    }
    if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
      trimmed = 'http://$trimmed';
    }
    _baseUrl = trimmed.replaceAll(RegExp(r'/+$'), '');
  }

  /// โมเดลที่ใช้
  static const String _model = 'llama3.2:1b';

  /// ประวัติแชท (เพื่อให้โมเดลจำบริบทการสนทนา)
  final List<Map<String, String>> _history = [];

  // ============================================================
  // System Instruction
  // ============================================================

  static const String _systemPrompt = '''
คุณคือ "Safa AI" ผู้ช่วยอัจฉริยะของแอป Safa สำหรับให้ความรู้ด้านการเงิน กฎหมาย และระบบ Qard Hasan (กัรฎ ฮะซัน — สัญญาเงินกู้ไม่คิดดอกเบี้ยตามหลักอิสลาม)

กฎการตอบ:
1. ตอบเป็นภาษาไทยเสมอ ยกเว้นศัพท์เทคนิคที่ไม่มีคำแปลที่เหมาะสม
2. ตอบสั้น กระชับ เข้าใจง่าย ไม่เกิน 300 คำ
3. หากมีข้อมูลสัญญาของผู้ใช้ที่ระบุไว้ในบริบท ให้ใช้ข้อมูลนั้นสรุปหรือตอบคำถามของผู้ใช้อย่างถูกต้อง แม่นยำ
4. ทุกครั้งที่ให้ข้อมูลความรู้ทั่วไป ต้องอ้างอิงแหล่งที่มาเสมอ โดยใส่ไว้ท้ายข้อความในรูปแบบ:
   📎 แหล่งอ้างอิง:
   - [ชื่อแหล่ง](URL หรือชื่อกฎหมาย/มาตรา)
5. หากไม่มี URL ให้ระบุชื่อกฎหมาย มาตรา หรือแหล่งที่มาที่ชัดเจน เช่น "พ.ร.บ.การเงินอิสลาม พ.ศ. 2565 มาตรา 12"
6. หากไม่แน่ใจในข้อมูล ให้แจ้งผู้ใช้ตรงๆ ว่าไม่แน่ใจ และแนะนำให้ปรึกษาผู้เชี่ยวชาญ
7. ห้ามให้คำแนะนำด้านการลงทุนเฉพาะเจาะจง
8. ตอบเฉพาะหัวข้อที่เกี่ยวข้องกับ: การเงินส่วนบุคคล, สัญญาและข้อมูลเงินกู้ในแอป Safa, กฎหมายหนี้สิน, สัญญากู้ยืม, Qard Hasan, สิทธิผู้กู้/ผู้ให้กู้, การวางแผนการเงิน
9. หากถูกถามเรื่องที่ไม่เกี่ยวข้อง ให้ปฏิเสธอย่างสุภาพ
10. ใช้อีโมจิประกอบเล็กน้อยเพื่อให้อ่านง่าย
''';

  // ============================================================
  // Candidate discovery & verification
  // ============================================================

  /// รายการ URLs ที่จะทดสอบเชื่อมต่ออัตโนมัติ
  List<String> get candidateUrls {
    final list = <String>[];
    if (_baseUrl.isNotEmpty) list.add(_baseUrl);

    if (!kIsWeb && Platform.isAndroid) {
      for (final u in [
        'http://10.0.2.2:11434',
        'http://127.0.0.1:11434',
        'http://localhost:11434',
      ]) {
        if (!list.contains(u)) list.add(u);
      }
    } else {
      for (final u in [
        'http://localhost:11434',
        'http://127.0.0.1:11434',
        'http://10.0.2.2:11434',
      ]) {
        if (!list.contains(u)) list.add(u);
      }
    }
    return list;
  }

  /// ทดสอบ URL ที่ระบุว่าสามารถติดต่อ Ollama ได้หรือไม่
  Future<bool> testUrl(String url) async {
    try {
      var target = url.trim();
      if (!target.startsWith('http://') && !target.startsWith('https://')) {
        target = 'http://$target';
      }
      target = target.replaceAll(RegExp(r'/+$'), '');

      final res = await http
          .get(Uri.parse('$target/api/tags'))
          .timeout(const Duration(milliseconds: 2000));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// ค้นหา URL ที่ใช้งานได้จริงจาก candidate URLs
  Future<String?> findWorkingBaseUrl() async {
    for (final candidate in candidateUrls) {
      if (await testUrl(candidate)) {
        _baseUrl = candidate;
        return candidate;
      }
    }
    return null;
  }

  /// เช็คว่า Ollama server พร้อมใช้งานหรือไม่
  Future<bool> isServerRunning() async {
    if (await testUrl(_baseUrl)) return true;
    final working = await findWorkingBaseUrl();
    return working != null;
  }

  /// รีเซ็ตประวัติแชท
  void resetChat() {
    _history.clear();
  }

  // ============================================================
  // Send Message
  // ============================================================

  Future<http.StreamedResponse> _sendChatRequest(
    String url,
    String body,
  ) async {
    final request = http.Request(
      'POST',
      Uri.parse('$url/api/chat'),
    );
    request.headers['Content-Type'] = 'application/json';
    request.body = body;

    return await request.send().timeout(
          const Duration(seconds: 60),
        );
  }

  /// ส่งข้อความแบบ Stream (ทยอยแสดงทีละคำ)
  /// รองรับ [extraContext] เพื่อส่งข้อมูลบริบท เช่น สัญญาของผู้ใช้
  Stream<String> sendMessageStream(
    String message, {
    String? extraContext,
  }) async* {
    // เพิ่มข้อความผู้ใช้เข้าประวัติ
    _history.add({'role': 'user', 'content': message});

    final effectiveSystemPrompt =
        (extraContext != null && extraContext.trim().isNotEmpty)
            ? '$_systemPrompt\n\n--- ข้อมูลสัญญาและผู้ใช้ปัจจุบัน ---\n${extraContext.trim()}\n--------------------------------'
            : _systemPrompt;

    // สร้าง messages payload (system + history)
    final messages = [
      {'role': 'system', 'content': effectiveSystemPrompt},
      ..._history,
    ];

    final body = jsonEncode({
      'model': _model,
      'messages': messages,
      'stream': true,
      'options': {
        'temperature': 0.7,
        'num_predict': 1024,
      },
    });

    String currentUrl = _baseUrl;
    http.StreamedResponse? streamedResponse;

    try {
      try {
        streamedResponse = await _sendChatRequest(currentUrl, body);
      } catch (e) {
        // หากเชื่อมต่อล้มเหลว ลองค้นหา candidate URL อื่นที่ตอบสนองแล้ว retry
        final working = await findWorkingBaseUrl();
        if (working != null && working != currentUrl) {
          currentUrl = working;
          streamedResponse = await _sendChatRequest(currentUrl, body);
        } else {
          rethrow;
        }
      }

      if (streamedResponse.statusCode != 200) {
        yield '❌ Ollama server ตอบกลับด้วย status ${streamedResponse.statusCode}';
        return;
      }

      final fullResponse = StringBuffer();

      await for (final chunk
          in streamedResponse.stream.transform(utf8.decoder)) {
        // แต่ละ chunk อาจมีหลาย JSON lines
        for (final line in chunk.split('\n')) {
          if (line.trim().isEmpty) continue;
          try {
            final json = jsonDecode(line) as Map<String, dynamic>;
            final content =
                (json['message'] as Map<String, dynamic>?)?['content']
                    as String?;
            if (content != null && content.isNotEmpty) {
              fullResponse.write(content);
              yield content;
            }

            // ถ้า done = true หมายความว่าจบแล้ว
            if (json['done'] == true) {
              // บันทึก response เข้าประวัติ
              _history.add({
                'role': 'assistant',
                'content': fullResponse.toString(),
              });
              return;
            }
          } catch (e) {
            debugPrint('Ollama parse error: $e | line: $line');
          }
        }
      }
    } on Exception catch (e) {
      final errMsg = e.toString();
      debugPrint('Ollama Error: $errMsg (URL: $currentUrl)');

      if (errMsg.contains('Connection refused') ||
          errMsg.contains('SocketException') ||
          errMsg.contains('Failed host lookup')) {
        yield '❌ ไม่สามารถเชื่อมต่อ Ollama ได้ ($currentUrl)\n\n'
            'กรุณาตรวจสอบ:\n'
            '1. เปิด Ollama บนคอมพิวเตอร์แล้วหรือยัง? (ollama serve)\n'
            '2. สำหรับ Android Emulator ค่าเริ่มต้นคือ http://10.0.2.2:11434\n'
            '3. สำหรับเครื่องจริง ให้เชื่อมต่อ WiFi เดียวกันและระบุ IP คอมพิวเตอร์\n'
            '4. ตรวจสอบว่าดาวน์โหลดโมเดลแล้ว: ollama pull llama3.2:1b\n\n'
            '💡 คุณสามารถกดไอคอน ⚙️ ด้านบนขวาเพื่อตั้งค่าและทดสอบการเชื่อมต่อได้ค่ะ';
      } else if (errMsg.contains('TimeoutException')) {
        yield '⏳ Ollama ใช้เวลานานเกินไป กรุณาลองใหม่อีกครั้ง';
      } else {
        yield '❌ เกิดข้อผิดพลาด: $errMsg';
      }

      // ลบ message ล่าสุดออกจาก history เพราะไม่ได้รับคำตอบ
      if (_history.isNotEmpty && _history.last['role'] == 'user') {
        _history.removeLast();
      }
    }
  }

  /// ตรวจสอบว่า service พร้อมใช้งานหรือไม่
  bool get isReady => true;

  /// โมเดลที่ใช้งานอยู่
  String get modelName => _model;
}
