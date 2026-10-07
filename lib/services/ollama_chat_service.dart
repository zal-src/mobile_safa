import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Service สำหรับเชื่อมต่อ Ollama (Local LLM)
/// ใช้ llama3.2:1b รันบนเครื่อง local
/// รองรับ streaming response
class OllamaChatService {
  OllamaChatService._();
  static final OllamaChatService instance = OllamaChatService._();

  /// URL ของ Ollama server (default: localhost:11434)
  static const String _baseUrl = 'http://localhost:11434';

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
3. ทุกครั้งที่ให้ข้อมูลความรู้ ต้องอ้างอิงแหล่งที่มาเสมอ โดยใส่ไว้ท้ายข้อความในรูปแบบ:
   📎 แหล่งอ้างอิง:
   - [ชื่อแหล่ง](URL หรือชื่อกฎหมาย/มาตรา)
4. หากไม่มี URL ให้ระบุชื่อกฎหมาย มาตรา หรือแหล่งที่มาที่ชัดเจน เช่น "พ.ร.บ.การเงินอิสลาม พ.ศ. 2565 มาตรา 12"
5. หากไม่แน่ใจในข้อมูล ให้แจ้งผู้ใช้ตรงๆ ว่าไม่แน่ใจ และแนะนำให้ปรึกษาผู้เชี่ยวชาญ
6. ห้ามให้คำแนะนำด้านการลงทุนเฉพาะเจาะจง
7. ตอบเฉพาะหัวข้อที่เกี่ยวข้องกับ: การเงินส่วนบุคคล, กฎหมายหนี้สิน, สัญญากู้ยืม, Qard Hasan, สิทธิผู้กู้/ผู้ให้กู้, การวางแผนการเงิน, ความรู้อิสลามิกการเงิน
8. หากถูกถามเรื่องที่ไม่เกี่ยวข้อง ให้ปฏิเสธอย่างสุภาพ
9. ใช้อีโมจิประกอบเล็กน้อยเพื่อให้อ่านง่าย
''';

  // ============================================================
  // Initialization
  // ============================================================

  /// เช็คว่า Ollama server พร้อมใช้งานหรือไม่
  Future<bool> isServerRunning() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/api/tags'))
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// รีเซ็ตประวัติแชท
  void resetChat() {
    _history.clear();
  }

  // ============================================================
  // Send Message
  // ============================================================

  /// ส่งข้อความแบบ Stream (ทยอยแสดงทีละคำ)
  Stream<String> sendMessageStream(String message) async* {
    // เพิ่มข้อความผู้ใช้เข้าประวัติ
    _history.add({'role': 'user', 'content': message});

    // สร้าง messages payload (system + history)
    final messages = [
      {'role': 'system', 'content': _systemPrompt},
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

    try {
      final request = http.Request(
        'POST',
        Uri.parse('$_baseUrl/api/chat'),
      );
      request.headers['Content-Type'] = 'application/json';
      request.body = body;

      final streamedResponse = await request.send().timeout(
            const Duration(seconds: 60),
          );

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
            // บางบรรทัดอาจ parse ไม่ได้ ข้ามไป
            debugPrint('Ollama parse error: $e | line: $line');
          }
        }
      }
    } on Exception catch (e) {
      final errMsg = e.toString();
      debugPrint('Ollama Error: $errMsg');

      if (errMsg.contains('Connection refused') ||
          errMsg.contains('SocketException')) {
        yield '❌ ไม่สามารถเชื่อมต่อ Ollama ได้\n\n'
            'กรุณาตรวจสอบ:\n'
            '1. เปิด Ollama แล้วหรือยัง? (ollama serve)\n'
            '2. ดาวน์โหลด model แล้วหรือยัง? (ollama pull llama3.2:1b)';
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
  bool get isReady => true; // Ollama ไม่ต้องการ API key

  /// โมเดลที่ใช้งานอยู่
  String get modelName => _model;
}
