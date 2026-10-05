import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import '../config/app_secrets.dart';

/// Service สำหรับเชื่อมต่อ Gemini AI
/// ใช้สำหรับแชทบอตให้ความรู้ด้านการเงิน กฎหมาย และ Qard Hasan
class GeminiChatService {
  GeminiChatService._();
  static final GeminiChatService instance = GeminiChatService._();

  GenerativeModel? _model;
  ChatSession? _chat;

  // ============================================================
  // System Instruction
  // ============================================================

  static const String _systemInstruction = '''
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

  /// เริ่มต้น model และ chat session ใหม่
  void initialize() {
    if (AppSecrets.geminiApiKey == 'YOUR_API_KEY_HERE' ||
        AppSecrets.geminiApiKey.isEmpty) {
      debugPrint(
        '⚠️ Gemini API Key ยังไม่ได้ตั้งค่า! '
        'กรุณาใส่ key ที่ lib/config/app_secrets.dart',
      );
      return;
    }

    _model = GenerativeModel(
      model: 'gemini-3.8-flash',
      apiKey: AppSecrets.geminiApiKey,
      systemInstruction: Content.system(_systemInstruction),
      generationConfig: GenerationConfig(
        temperature: 0.7,
        maxOutputTokens: 1024,
      ),
    );

    _chat = _model!.startChat();
  }

  /// รีเซ็ตประวัติแชท (เริ่มคุยใหม่)
  void resetChat() {
    if (_model != null) {
      _chat = _model!.startChat();
    }
  }

  // ============================================================
  // Send Message
  // ============================================================

  /// ส่งข้อความไปให้ Gemini แล้วรับคำตอบกลับมา
  Future<String> sendMessage(String message) async {
    if (_model == null || _chat == null) {
      return '⚠️ ระบบ AI ยังไม่พร้อมใช้งาน\n'
          'กรุณาตั้งค่า API Key ที่ lib/config/app_secrets.dart';
    }

    try {
      final response = await _chat!.sendMessage(Content.text(message));
      return response.text ?? 'ไม่สามารถประมวลผลคำตอบได้';
    } on GenerativeAIException catch (e) {
      debugPrint('Gemini API Error: $e');
      if (e.message.toLowerCase().contains('high demand') ||
          e.message.toLowerCase().contains('quota') ||
          e.message.contains('429')) {
        return '⏳ ขออภัยค่ะ ขณะนี้ AI มีผู้ใช้งานจำนวนมาก (High demand) กรุณารอสักครู่แล้วลองถามใหม่อีกครั้งนะคะ';
      }
      return '❌ เกิดข้อผิดพลาดจาก AI: ${e.message}';
    } catch (e) {
      debugPrint('Gemini Error: $e');
      return '❌ ไม่สามารถเชื่อมต่อกับ AI ได้\nกรุณาตรวจสอบอินเทอร์เน็ตแล้วลองใหม่';
    }
  }

  /// ส่งข้อความแบบ Stream (ทยอยแสดงทีละคำ)
  Stream<String> sendMessageStream(String message) async* {
    if (_model == null || _chat == null) {
      yield '⚠️ ระบบ AI ยังไม่พร้อมใช้งาน';
      return;
    }

    try {
      final response = _chat!.sendMessageStream(Content.text(message));
      await for (final chunk in response) {
        final text = chunk.text;
        if (text != null) yield text;
      }
    } on GenerativeAIException catch (e) {
      if (e.message.toLowerCase().contains('high demand') ||
          e.message.toLowerCase().contains('quota') ||
          e.message.contains('429')) {
        yield '⏳ ขออภัยค่ะ ขณะนี้ AI มีผู้ใช้งานจำนวนมาก (High demand) กรุณารอสักครู่แล้วลองถามใหม่อีกครั้งนะคะ';
      } else {
        yield '❌ เกิดข้อผิดพลาดจาก AI: ${e.message}';
      }
    } catch (e) {
      yield '❌ ไม่สามารถเชื่อมต่อได้ กรุณาลองใหม่';
    }
  }

  /// ตรวจสอบว่า service พร้อมใช้งานหรือไม่
  bool get isReady => _model != null && _chat != null;
}
