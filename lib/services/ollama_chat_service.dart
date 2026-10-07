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

/// ข้อมูลโมเดล AI แต่ละตัว
class AiModelInfo {
  final String id;
  final String displayName;
  final String subtitle;
  final AiProvider provider;
  final bool isRecommended;

  const AiModelInfo({
    required this.id,
    required this.displayName,
    required this.subtitle,
    required this.provider,
    this.isRecommended = false,
  });
}

/// Service สำหรับเชื่อมต่อ AI ของแอป Safa
/// โดยค่าเริ่มต้นจะใช้ Google Gemini API (ฟรี ไม่ต้องลงโปรแกรมหรือรันเซิร์ฟเวอร์ใดๆ)
/// เหมาะสำหรับการทำงานร่วมกันบน GitHub — เพื่อน Clone โค้ดไปก็ใช้งานได้ทันที
class OllamaChatService {
  OllamaChatService._();
  static final OllamaChatService instance = OllamaChatService._();

  /// Provider ปัจจุบัน (ค่าเริ่มต้น: Gemini Cloud Direct)
  AiProvider currentProvider = AiProvider.gemini;

  /// รายชื่อโมเดล AI ทั้งหมดที่รองรับ (ผ่านการทดสอบและใช้งานได้จริง 100%)
  static const List<AiModelInfo> supportedModels = [
    AiModelInfo(
      id: 'gemini-3.5-flash-lite',
      displayName: 'Gemini 3.5 Flash',
      subtitle: 'เร็วที่สุด ตอบไวมาก (แนะนำ)',
      provider: AiProvider.gemini,
      isRecommended: true,
    ),
    AiModelInfo(
      id: 'gemini-3-flash-preview',
      displayName: 'Gemini 3 Flash',
      subtitle: 'ฉลาด วิเคราะห์ข้อมูลสัญญาได้ดี',
      provider: AiProvider.gemini,
    ),
    AiModelInfo(
      id: 'gemma-4-26b-a4b-it',
      displayName: 'Gemma 4 (26B)',
      subtitle: 'โมเดลคุณภาพสูงจาก Google',
      provider: AiProvider.gemini,
    ),
  ];

  String _selectedModelId = 'gemini-3.5-flash-lite';

  String get selectedModelId => _selectedModelId;

  set selectedModelId(String id) {
    _selectedModelId = id;
    final model = supportedModels.firstWhere(
      (m) => m.id == id,
      orElse: () => supportedModels.first,
    );
    currentProvider = model.provider;
  }

  AiModelInfo get currentModel {
    return supportedModels.firstWhere(
      (m) => m.id == _selectedModelId,
      orElse: () => supportedModels.first,
    );
  }

  String get selectedModelDisplayName => currentModel.displayName;

  /// รายชื่อโมเดล Gemini ฟรี ที่จะลองเรียกใช้เป็นตัวสำรองกรณีโมเดลหลักติดคิว
  static const List<String> candidateGeminiModels = [
    'gemini-3.5-flash-lite',
    'gemini-3-flash-preview',
    'gemma-4-26b-a4b-it',
  ];

  String? _customApiKey;

  /// API Key ที่ใช้งานจริง (ดึงจาก Custom Key ก่อน หรือจาก AppSecrets / .env)
  String get effectiveGeminiApiKey {
    if (_customApiKey != null && _customApiKey!.trim().isNotEmpty) {
      return _customApiKey!.trim();
    }
    return AppSecrets.geminiApiKey;
  }

  set customApiKey(String? key) {
    _customApiKey = key?.trim();
  }

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
11. การโต้ตอบและการสั่งงานแอปพลิเคชัน (App Action):
หากผู้ใช้ต้องการทำรายการหรือสั่งงานในแอปพลิเคชัน เช่น:
- ขอสร้างสัญญาเงินกู้, สร้างรายการใหม่, อยากกู้เงิน, หรือให้ยืมเงิน
- ขอดูรายการสัญญาในระบบ
- ขอพิมพ์หรือดาวน์โหลดแบบฟอร์มสัญญาเปล่า (PDF)

ให้ตอบแนะนำอย่างเป็นมิตร และปิดท้ายข้อความด้วย Action Block เสมอในรูปแบบ:
<<<ACTION:TYPE:JSON_DATA>>>

ประเภท Actions ที่รองรับ:
- สร้างสัญญาใหม่: <<<ACTION:CREATE_CONTRACT:{"amount":5000,"purpose":"วัตถุประสงค์","role":"lender"}>>> (ใส่ข้อมูลเท่าที่ผู้ใช้ระบุ หากไม่ระบุให้ใส่ {})
- ดูรายการสัญญา: <<<ACTION:VIEW_CONTRACTS:{}>>>
- พิมพ์สัญญาเปล่า: <<<ACTION:BLANK_PDF:{}>>>
''';

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
    final apiKey = effectiveGeminiApiKey;
    if (apiKey.isEmpty) {
      yield '⚠️ ยังไม่ได้ระบุ Gemini API Key ในระบบ\n\n'
          'วิธีเริ่มใช้งาน (ฟรี 100%):\n'
          '1. รับ API Key ฟรีจาก https://aistudio.google.com/apikey\n'
          '2. ระบุในไฟล์ `.env` ที่โฟลเดอร์โปรเจกต์: `GEMINI_API_KEY=รหัสของคุณ`\n'
          '3. ใช้งานได้ทันทีโดยไม่ต้องลงโปรแกรมหรือรันเซิร์ฟเวอร์ใดๆ ค่ะ';
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
          'parts': [
            {'text': text},
          ],
        });
      }
    }

    final payload = jsonEncode({
      'system_instruction': {
        'parts': [
          {'text': effectiveSystemPrompt},
        ],
      },
      'contents': contents,
      'generationConfig': {
        'temperature': 0.7,
        'maxOutputTokens': 1024,
        'topK': 10,
      },
    });

    final fullResponse = StringBuffer();
    bool success = false;
    String lastError = '';

    // จัดลำดับโมเดล: นำโมเดลที่ผู้ใช้เลือกขึ้นก่อน หากติดขัด (เช่น Spikes in demand) จะสลับไปโมเดลสำรองให้อัตโนมัติ
    final modelsToTry = <String>[];
    if (currentModel.provider == AiProvider.gemini) {
      modelsToTry.add(_selectedModelId);
    }
    for (final candidate in candidateGeminiModels) {
      if (!modelsToTry.contains(candidate)) {
        modelsToTry.add(candidate);
      }
    }

    for (final model in modelsToTry) {
      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/$model:streamGenerateContent?alt=sse&key=$apiKey',
      );

      final client = http.Client();
      try {
        final request = http.Request('POST', url);
        request.headers['Content-Type'] = 'application/json';
        request.body = payload;

        final streamedResponse = await client
            .send(request)
            .timeout(const Duration(seconds: 35));

        if (streamedResponse.statusCode != 200) {
          lastError = 'HTTP ${streamedResponse.statusCode}';
          client.close();
          continue;
        }

        success = true;

        await for (final chunk in streamedResponse.stream.transform(
          utf8.decoder,
        )) {
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
      final request = http.Request('POST', Uri.parse('$_ollamaUrl/api/chat'));
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode({
        'model': _selectedModelId,
        'messages': messages,
        'stream': true,
        'options': {
          'temperature': 0.7,
          'num_predict': 1024,
          'top_k': 10,
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

      await for (final chunk in streamedResponse.stream.transform(
        utf8.decoder,
      )) {
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
          'คำแนะนำ: แนะนำให้เลือกโมเดล Google Gemini ที่แถบด้านล่าง (ใช้งานได้ฟรี ไม่ต้องลงโปรแกรม)';
      if (_history.isNotEmpty && _history.last['role'] == 'user') {
        _history.removeLast();
      }
    }
  }

  bool get isReady => true;

  String get modelName => selectedModelDisplayName;
}
