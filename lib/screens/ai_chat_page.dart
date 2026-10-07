import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/user.dart';
import '../services/contract_service.dart';
import '../services/ollama_chat_service.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';
import '../widgets/responsive_container.dart';

// ============================================================
// Data Model
// ============================================================

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

// ============================================================
// Page
// ============================================================

class AiChatPage extends StatefulWidget {
  final User? user;

  const AiChatPage({super.key, this.user});

  @override
  State<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends State<AiChatPage> with TickerProviderStateMixin {
  final OllamaChatService _ollama = OllamaChatService.instance;
  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final FocusNode _inputFocus = FocusNode();

  final List<ChatMessage> _messages = [];
  bool _isTyping = false;
  String _streamingText = '';
  String? _contractContext;

  // ============================================================
  // Lifecycle
  // ============================================================

  @override
  void initState() {
    super.initState();
    _loadUserContracts();
    _ollama.findWorkingBaseUrl();

    // ข้อความต้อนรับ
    _messages.add(ChatMessage(
      text: 'สวัสดีค่ะ! 👋\n\n'
          'ฉันคือ **Safa AI** ผู้ช่วยด้านความรู้การเงิน กฎหมาย และข้อมูลสัญญาของคุณ\n\n'
          'คุณสามารถถามฉันเกี่ยวกับ:\n'
          '• 📋 สรุปข้อมูลสัญญาที่ทำไว้\n'
          '• 💰 การจัดการเงินส่วนบุคคล\n'
          '• ⚖️ กฎหมายหนี้สินและสิทธิของคุณ\n'
          '• 🤝 สัญญากู้ยืมเงิน & Qard Hasan\n\n'
          'ถามมาได้เลยค่ะ!',
      isUser: false,
    ));
  }

  Future<void> _loadUserContracts() async {
    final user = widget.user;
    if (user?.userId == null) return;

    try {
      final contracts = await ContractService().getUserContracts(user!.userId!);
      if (contracts.isNotEmpty) {
        final buffer = StringBuffer();
        buffer.writeln('ผู้ใช้ปัจจุบัน: ${user.fullName} (อีเมล: ${user.email})');
        buffer.writeln('รายการสัญญาในระบบ (${contracts.length} รายการ):');
        for (final c in contracts) {
          final isLender = c.lenderId == user.userId;
          final role = isLender ? 'ผู้ให้กู้' : 'ผู้กู้';
          buffer.writeln(
            '- เลขที่สัญญา: ${c.agreementId}, บทบาท: $role, ยอดเงิน: ${c.amount} บาท, สถานะ: ${c.status}, วันที่กู้: ${c.loanDate}, วันครบกำหนด: ${c.returnDate}'
            '${c.purpose != null && c.purpose!.isNotEmpty ? ', วัตถุประสงค์: ${c.purpose}' : ''}',
          );
        }
        _contractContext = buffer.toString();
      }
    } catch (e) {
      debugPrint('Could not load user contracts for AI context: $e');
    }
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  // ============================================================
  // Actions
  // ============================================================

  Future<void> _sendMessage() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty || _isTyping) return;

    _inputCtrl.clear();

    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _isTyping = true;
      _streamingText = '';
    });

    _scrollToBottom();

    // ใช้ Stream เพื่อแสดงทีละส่วน พร้อมบริบทสัญญา
    final buffer = StringBuffer();
    await for (final chunk in _ollama.sendMessageStream(
      text,
      extraContext: _contractContext,
    )) {
      buffer.write(chunk);
      if (!mounted) return;
      setState(() => _streamingText = buffer.toString());
      _scrollToBottom();
    }

    if (!mounted) return;

    setState(() {
      _messages.add(ChatMessage(text: buffer.toString(), isUser: false));
      _streamingText = '';
      _isTyping = false;
    });

    _scrollToBottom();
  }

  void _clearChat() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('เริ่มแชทใหม่'),
        content: const Text('ต้องการลบประวัติแชททั้งหมดและเริ่มใหม่หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _ollama.resetChat();
              setState(() {
                _messages.clear();
                _messages.add(ChatMessage(
                  text: 'เริ่มต้นใหม่แล้วค่ะ! 🔄\n\nถามมาได้เลยค่ะ',
                  isUser: false,
                ));
              });
            },
            child: const Text('เริ่มใหม่'),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog() {
    final controller = TextEditingController(text: _ollama.baseUrl);
    bool testing = false;
    String? testResult;
    bool? testSuccess;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.tune_rounded, color: AppColors.primary),
                SizedBox(width: 8),
                Text('ตั้งค่า Ollama Server', style: TextStyle(fontSize: 18)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'URL ของ Ollama บนเครื่อง Local:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      hintText: 'http://10.0.2.2:11434',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'ตัวเลือกด่วน:',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      ActionChip(
                        label: const Text('Android (10.0.2.2)'),
                        onPressed: () {
                          setDialogState(() {
                            controller.text = 'http://10.0.2.2:11434';
                            testResult = null;
                          });
                        },
                      ),
                      ActionChip(
                        label: const Text('Localhost (127.0.0.1)'),
                        onPressed: () {
                          setDialogState(() {
                            controller.text = 'http://127.0.0.1:11434';
                            testResult = null;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        icon: testing
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.bolt, size: 18),
                        label: const Text('ทดสอบการเชื่อมต่อ'),
                        onPressed: testing
                            ? null
                            : () async {
                                setDialogState(() {
                                  testing = true;
                                  testResult = null;
                                });
                                final ok = await _ollama.testUrl(controller.text);
                                if (!dialogCtx.mounted) return;
                                setDialogState(() {
                                  testing = false;
                                  testSuccess = ok;
                                  testResult = ok
                                      ? '✅ เชื่อมต่อสำเร็จ พร้อมใช้งาน'
                                      : '❌ ไม่สามารถเชื่อมต่อได้ ตรวจสอบว่าเปิด ollama serve แล้วหรือยัง';
                                });
                              },
                      ),
                    ],
                  ),
                  if (testResult != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      testResult!,
                      style: TextStyle(
                        fontSize: 13,
                        color: testSuccess == true
                            ? Colors.green.shade700
                            : Colors.red.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('ยกเลิก'),
              ),
              FilledButton(
                onPressed: () {
                  _ollama.baseUrl = controller.text;
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('บันทึก Server URL: ${_ollama.baseUrl}'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                child: const Text('บันทึก'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ============================================================
  // Quick suggestions
  // ============================================================

  static const List<String> _suggestions = [
    'สรุปข้อมูลสัญญาของฉัน',
    'Qard Hasan คืออะไร?',
    'สิทธิของผู้กู้มีอะไรบ้าง?',
    'วิธีวางแผนชำระหนี้',
  ];

  // ============================================================
  // Build
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.page,
      appBar: AppTheme.buildSafaAppBar(
        context,
        title: 'Safa AI',
        actions: [
          IconButton(
            tooltip: 'ตั้งค่าการเชื่อมต่อ Ollama',
            icon: const Icon(Icons.settings_outlined),
            onPressed: _showSettingsDialog,
          ),
          IconButton(
            tooltip: 'เริ่มแชทใหม่',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _clearChat,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: ResponsiveBody(
          maxWidth: Responsive.formMaxWidth(context),
          child: Column(
            children: [
              // ---- Chat Messages ----
              Expanded(
                child: ListView.builder(
                  controller: _scrollCtrl,
                  padding: EdgeInsets.fromLTRB(
                    Responsive.horizontalPadding(context),
                    16,
                    Responsive.horizontalPadding(context),
                    8,
                  ),
                  itemCount: _messages.length +
                      (_isTyping && _streamingText.isNotEmpty ? 1 : 0) +
                      (_messages.length == 1 ? 1 : 0), // suggestions
                  itemBuilder: (context, index) {
                    // แสดง suggestions หลังข้อความต้อนรับ
                    if (_messages.length == 1 && index == 1) {
                      return _buildSuggestions();
                    }

                    final adjustedIndex =
                        (_messages.length == 1 && index > 1) ? index - 1 : index;

                    // ข้อความ streaming ที่กำลังพิมพ์
                    if (adjustedIndex >= _messages.length) {
                      return _buildMessageBubble(
                        ChatMessage(text: _streamingText, isUser: false),
                        isStreaming: true,
                      );
                    }

                    return _buildMessageBubble(_messages[adjustedIndex]);
                  },
                ),
              ),

              // ---- Typing indicator ----
              if (_isTyping && _streamingText.isEmpty)
                _buildTypingIndicator(),

              // ---- Input bar ----
              _buildInputBar(),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // Widgets
  // ============================================================

  Widget _buildSuggestions() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _suggestions.map((text) {
          return ActionChip(
            label: Text(
              text,
              style: const TextStyle(fontSize: 12, color: AppColors.primary),
            ),
            backgroundColor: AppColors.primarySoft,
            side: const BorderSide(color: AppColors.primaryBorder),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            onPressed: () {
              _inputCtrl.text = text;
              _sendMessage();
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, {bool isStreaming = false}) {
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                border: isUser
                    ? null
                    : Border.all(color: const Color(0xFFE4E7EC)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFormattedText(
                    message.text,
                    isUser: isUser,
                  ),
                  if (!isUser && !isStreaming) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        InkWell(
                          borderRadius: BorderRadius.circular(6),
                          onTap: () {
                            Clipboard.setData(
                                ClipboardData(text: message.text));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('คัดลอกข้อความแล้ว'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              Icons.copy_rounded,
                              size: 14,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }

  /// แสดงข้อความแบบ formatted (bold, bullet points)
  Widget _buildFormattedText(String text, {required bool isUser}) {
    final color = isUser ? Colors.white : AppColors.ink;
    final spans = <TextSpan>[];

    // แปลง **bold** เป็น TextSpan
    final boldRegex = RegExp(r'\*\*(.*?)\*\*');
    int lastEnd = 0;

    for (final match in boldRegex.allMatches(text)) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: text.substring(lastEnd, match.start),
          style: TextStyle(color: color, fontSize: 14, height: 1.5),
        ));
      }
      spans.add(TextSpan(
        text: match.group(1),
        style: TextStyle(
          color: color,
          fontSize: 14,
          fontWeight: FontWeight.bold,
          height: 1.5,
        ),
      ));
      lastEnd = match.end;
    }

    if (lastEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastEnd),
        style: TextStyle(color: color, fontSize: 14, height: 1.5),
      ));
    }

    return RichText(
      text: TextSpan(children: spans),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.horizontalPadding(context),
        vertical: 8,
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE4E7EC)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDot(0),
                const SizedBox(width: 4),
                _buildDot(1),
                const SizedBox(width: 4),
                _buildDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 600 + index * 200),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.3 + value * 0.5),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE4E7EC))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF7F8FA),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE4E7EC)),
              ),
              child: TextField(
                controller: _inputCtrl,
                focusNode: _inputFocus,
                maxLines: 4,
                minLines: 1,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                decoration: const InputDecoration(
                  hintText: 'ถามอะไรก็ได้เกี่ยวกับการเงิน...',
                  hintStyle: TextStyle(
                    color: Color(0xFF98A2B3),
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _isTyping ? Colors.grey.shade300 : AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              tooltip: 'ส่งข้อความ',
              onPressed: _isTyping ? null : _sendMessage,
              icon: Icon(
                Icons.send_rounded,
                color: _isTyping ? Colors.grey.shade500 : Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
