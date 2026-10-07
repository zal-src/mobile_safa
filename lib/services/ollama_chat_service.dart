import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/app_secrets.dart';

/// ประเภทของ AI Provider
enum AiProvider {
  gemini, // Google Gemini (Cloud Direct - ฟรี ไม่ต้องลงอะไรในเครื่อง)
  ollama, // Local Ollama (รันบนเครื่องตนเอง)
}

/// Service สำหรับเชื่อมต่อ AI ของแอป Safa
/// โดยค่าเริ่มต้นจะใช้ Google Gemini API (ฟรี ไม่ต้องลงโปรแกรมหรือรันเซิร์ฟเวอร์ใดๆ)
/// เหมาะสำหรับการทำงานร่วมกันบน GitHub — เพื่อน Clone โค้ดไปก็ใช้งานได้ทันที
class OllamaChatService {
  OllamaChatService._();
  static final OllamaChatService instance = OllamaChatService._();

  /// Provider ปัจจุบัน (ค่าเริ่มต้น: Gemini Cloud Direct)
  AiProvider currentProvider = AiProvider.gemini;

  /// รายชื่อโมเดล Gemini ฟรี ที่จะลองเรียกใช้ตามลำดับ
  static const List<String> candidateGeminiModels = [
    'gemini-3.5-flash',
    'gemini-3.8-flash',
    'gemini-flash-latest',
  ];

  // ============================================================
  // Ollama Settings (สำหรับผู้ที่ต้องการรัน Local)
  // ============================================================

  static String get defaultOllamaUrl {
    if (!kIsWeb && Platform.isAndroid) {
      return 'http://10.0.2.2:11434';
    }
    return 'http://localhost:11434';
  }

  String _ollamaUrl = defaultOllamaUrl;
  String get baseUrl => _ollamaUrl;
  set baseUrl(String url) {
    var trimmed = url.trim();
    if (trimmed.isEmpty) {
      _ollamaUrl = defaultOllamaUrl;
      return;
    }
    if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
      trimmed = 'http://$trimmed';
    }
    _ollamaUrl = trimmed.replaceAll(RegExp(r'/+$'), '');
  }

  static const String _ollamaModel = 'llama3.2:1b';

  /// ประวัติแชท (เพื่อให้โมเดลจำบริบทการสนทนา)
  final List<Map<String, String>> _history = [];

  // ============================================================
  // System Instruction
  // ============================================================

  static const String _systemPrompt = '''
คุณคือ "Safa AI" ผู้ช่วยอัจฉริยะของแอปพลิเคชัน Safa สำหรับให้ความรู้ด้านการเงิน กฎหมาย และระบบ Qard Hasan (กัรฎ ฮะซัน — สัญญาเงินกู้ไม่คิดดอกเบี้ยตามหลักการเงินอิสลาม)

กฎการตอบ:
1. ตอบเป็นภาษาไทยเสมอ ยกเว้นศัพท์เทคนิคที่ไม่มีคำแปลที่เหมาะสม
2. ตอบกระชับ ชัดเจน เข้าใจง่าย ไม่เยิ่นเย้อ
3. หากมีข้อมูลสัญญาของผู้ใช้ที่ระบุไว้ในบริบท ให้ใช้ข้อมูลนั้นสรุป ตอบ หรืออธิบายสถานะสัญญาของผู้ใช้อย่างถูกต้อง แม่นยำ
4. ทุกครั้งที่ให้ข้อมูลความรู้ทั่วไป ต้องอ้างอิงแหล่งที่มาเสมอ โดยใส่ไว้ท้ายข้อความในรูปแบบ:
   📎 แหล่งอ้างอิง:
   - [ชื่อแหล่ง](URL หรือชื่อกฎหมาย/มาตรา)
5. หากไม่มี URL ให้ระบุชื่อกฎหมาย มาตรา หรือหลักการที่ชัดเจน เช่น "พ.ร.บ.การเงินอิสลาม พ.ศ. 2565 มาตรา 12"
6. หากไม่แน่ใจในข้อมูล ให้แจ้งผู้ใช้ตรงๆ ว่าไม่แน่ใจ และแนะนำให้ปรึกษาผู้เชี่ยวชาญ
7. ห้ามให้คำแนะนำด้านการลงทุนเฉพาะเจาะจง
8. ตอบเฉพาะหัวข้อที่เกี่ยวข้องกับ: การเงินส่วนบุคคล, สัญญาและข้อมูลเงินกู้ในแอป Safa, กฎหมายหนี้สิน, สัญญากู้ยืม, Qard Hasan, สิทธิผู้กู้/ผู้ให้กู้, การวางแผนการเงิน
9. หากถูกถามเรื่องที่ไม่เกี่ยวข้อง ให้ปฏิเสธอย่างสุภาพ
10. ใช้อีโมจิประกอบพอเหมาะเพื่อความสบายตา
''';

  // ============================================================
  // Testing & Verification
  // ============================================================

  /// ทดสอบการเชื่อมต่อ Google Gemini API
  Future<Map<String, dynamic>> testGeminiConnection() async {
    final apiKey = AppSecrets.geminiApiKey;
    if (apiKey.isEmpty) {
      return {
        'success': false,
        'message': '❌ ไม่พบ Gemini API Key ในระบบ',
      };
    }

    try {
      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models?key=$apiKey',
      );
      final res = await http.get(url).timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        return {
          'success': true,
          'message': '✅ เชื่อมต่อ Google Gemini สำเร็จ (ใช้งานได้ฟรี ไม่ต้องเปิดเซิร์ฟเวอร์)',
        };
      } else {
        return {
          'success': false,
          'message': '❌ Gemini API ตอบกลับด้วยรหัส ${res.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': '❌ ไม่สามารถเชื่อมต่อกับ Google AI ได้ (ตรวจสอบอินเทอร์เน็ต)',
      };
    }
  }

  /// ทดสอบการเชื่อมต่อ Ollama
  Future<Map<String, dynamic>> testOllamaConnection([String? customUrl]) async {
    final target = customUrl ?? _ollamaUrl;
    try {
      final res = await http
          .get(Uri.parse('$target/api/tags'))
          .timeout(const Duration(seconds: 3));
      if (res.statusCode == 200) {
        return {
          'success': true,
          'message': '✅ เชื่อมต่อ Local Ollama สำเร็จ ($target)',
        };
      }
    } catch (_) {}

    return {
      'success': false,
      'message': '❌ ไม่พบ Ollama บน $target (ต้องเปิด ollama serve)',
    };
  }

  /// เช็คสถานะ Provider ปัจจุบัน
  Future<bool> isServerRunning() async {
    if (currentProvider == AiProvider.gemini) {
      final res = await testGeminiConnection();
      return res['success'] == true;
    } else {
      final res = await testOllamaConnection();
      return res['success'] == true;
    }
  }

  /// รีเซ็ตประวัติแชท
  void resetChat() {
    _history.clear();
  }

  // ============================================================
  // Send Message Stream
  // ============================================================

  /// ส่งข้อความแบบ Stream (ทยอยแสดงทีละคำ)
  Stream<String> sendMessageStream(
    String message, {
    String? extraContext,
  }) async* {
    _history.add({'role': 'user', 'content': message});

    if (currentProvider == AiProvider.gemini) {
      yield* _streamFromGeminiDirect(message, extraContext);
    } else {
      yield* _streamFromOllama(message, extraContext);
    }
  }

  /// สตรีมคำตอบโดยตรงจาก Google Gemini API (Cloud Direct - ฟรี)
  Stream<String> _streamFromGeminiDirect(
    String message,
    String? extraContext,
  ) async* {
    final apiKey = AppSecrets.geminiApiKey;
    if (apiKey.isEmpty) {
      yield '❌ ยังไม่ได้ตั้งค่า Gemini API Key';
      return;
    }

    final effectiveSystemPrompt =
        (extraContext != null && extraContext.trim().isNotEmpty)
            ? '$_systemPrompt\n\n--- ข้อมูลสัญญาและผู้ใช้ปัจจุบัน ---\n${extraContext.trim()}\n--------------------------------'
            : _systemPrompt;

    // เตรียม contents (ประวัติแชท + ข้อความล่าสุด)
    final contents = <Map<String, dynamic>>[];
    for (final h in _history) {
      final role = h['role'] == 'user' ? 'user' : 'model';
      final text = h['content'] ?? '';
      if (text.isNotEmpty) {
        contents.add({
          'role': role,
          'parts': [{'text': text}],
        });
      }
    }

    final payload = jsonEncode({
      'system_instruction': {
        'parts': [{'text': effectiveSystemPrompt}],
      },
      'contents': contents,
      'generationConfig': {
        'temperature': 0.7,
        'maxOutputTokens': 1024,
      },
    });

    final fullResponse = StringBuffer();
    bool success = false;
    String lastError = '';

    // วนทดสอบ candidate models หากตัวใดตัวหนึ่งติดขัด (เช่น Spikes in demand)
    for (final model in candidateGeminiModels) {
      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/$model:streamGenerateContent?alt=sse&key=$apiKey',
      );

      final client = http.Client();
      try {
        final request = http.Request('POST', url);
        request.headers['Content-Type'] = 'application/json';
        request.body = payload;

        final streamedResponse = await client.send(request).timeout(
              const Duration(seconds: 35),
            );

        if (streamedResponse.statusCode != 200) {
          lastError = 'HTTP ${streamedResponse.statusCode}';
          client.close();
          continue;
        }

        success = true;

        await for (final chunk in streamedResponse.stream.transform(utf8.decoder)) {
          for (final line in chunk.split('\n')) {
            final trimmed = line.trim();
            if (trimmed.isEmpty) continue;

            if (trimmed.startsWith('data: ')) {
              final jsonStr = trimmed.substring(6).trim();
              if (jsonStr == '[DONE]') break;

              try {
                final json = jsonDecode(jsonStr) as Map<String, dynamic>;
                final candidates = json['candidates'] as List?;
                if (candidates != null && candidates.isNotEmpty) {
                  final parts = candidates[0]['content']?['parts'] as List?;
                  if (parts != null && parts.isNotEmpty) {
                    final text = parts[0]['text'] as String?;
                    if (text != null && text.isNotEmpty) {
                      fullResponse.write(text);
                      yield text;
                    }
                  }
                }
              } catch (_) {}
            }
          }
        }

        client.close();

        if (fullResponse.isNotEmpty) {
          _history.add({
            'role': 'assistant',
            'content': fullResponse.toString(),
          });
          return;
        }
      } catch (e) {
        lastError = e.toString();
        client.close();
        continue;
      }
    }

    if (!success || fullResponse.isEmpty) {
      yield '❌ ไม่สามารถเชื่อมต่อกับ AI ได้ในขณะนี้ ($lastError)\n\n'
          'กรุณาตรวจสอบว่าอุปกรณ์เชื่อมต่ออินเทอร์เน็ตแล้วหรือไม่ค่ะ';
      if (_history.isNotEmpty && _history.last['role'] == 'user') {
        _history.removeLast();
      }
    }
  }

  /// สตรีมคำตอบจาก Local Ollama (กรณีเลือกโหมด Ollama)
  Stream<String> _streamFromOllama(
    String message,
    String? extraContext,
  ) async* {
    final effectiveSystemPrompt =
        (extraContext != null && extraContext.trim().isNotEmpty)
            ? '$_systemPrompt\n\n--- ข้อมูลสัญญาและผู้ใช้ปัจจุบัน ---\n${extraContext.trim()}\n--------------------------------'
            : _systemPrompt;

    final messages = [
      {'role': 'system', 'content': effectiveSystemPrompt},
      ..._history,
    ];

    try {
      final request = http.Request(
        'POST',
        Uri.parse('$_ollamaUrl/api/chat'),
      );
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode({
        'model': _ollamaModel,
        'messages': messages,
        'stream': true,
        'options': {
          'temperature': 0.7,
          'num_predict': 1024,
        },
      });

      final streamedResponse = await request.send().timeout(
            const Duration(seconds: 60),
          );

      if (streamedResponse.statusCode != 200) {
        yield '❌ Ollama ตอบกลับด้วย status ${streamedResponse.statusCode}';
        return;
      }

      final fullResponse = StringBuffer();

      await for (final chunk in streamedResponse.stream.transform(utf8.decoder)) {
        for (final line in chunk.split('\n')) {
          if (line.trim().isEmpty) continue;
          try {
            final json = jsonDecode(line) as Map<String, dynamic>;
            final content =
                (json['message'] as Map<String, dynamic>?)?['content'] as String?;
            if (content != null && content.isNotEmpty) {
              fullResponse.write(content);
              yield content;
            }

            if (json['done'] == true) {
              _history.add({
                'role': 'assistant',
                'content': fullResponse.toString(),
              });
              return;
            }
          } catch (_) {}
        }
      }
    } catch (e) {
      yield '❌ ไม่สามารถเชื่อมต่อ Ollama ได้ ($e)\n'
          'คำแนะนำ: แนะนำให้กดปุ่ม ⚙️ ด้านบนแล้วเลือกโหมด Google Gemini (ฟรี ไม่ต้องลงโปรแกรม)';
      if (_history.isNotEmpty && _history.last['role'] == 'user') {
        _history.removeLast();
      }
    }
  }

  bool get isReady => true;

  String get modelName =>
      currentProvider == AiProvider.gemini ? 'Google Gemini (Cloud Free)' : _ollamaModel;
}
