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

class _AiChatPageState extends State<AiChatPage> {
  final OllamaChatService _ollama = OllamaChatService.instance;
  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final FocusNode _inputFocus = FocusNode();

  final List<ChatMessage> _messages = [];
  bool _isTyping = false;
  String _streamingText = '';
  String? _contractContext;

  @override
  void initState() {
    super.initState();
    _inputCtrl.addListener(_onInputChanged);
    _loadUserContracts();

    // ข้อความเริ่มต้นต้อนรับ
    _messages.add(ChatMessage(
      text: 'สวัสดีค่ะ! 👋\n\n'
          'ฉันคือ **Safa AI** ผู้ช่วยด้านการเงิน กฎหมาย และข้อมูลสัญญาของคุณ\n\n'
          'คุณสามารถถามฉันเกี่ยวกับ:\n'
          '• 📋 สรุปข้อมูลสัญญาที่ทำไว้\n'
          '• 💰 การจัดการเงินส่วนบุคคล\n'
          '• ⚖️ กฎหมายหนี้สินและสิทธิของคุณ\n'
          '• 🤝 สัญญากู้ยืมเงิน & Qard Hasan\n\n'
          'ถามมาได้เลยค่ะ!',
      isUser: false,
    ));
  }

  void _onInputChanged() {
    setState(() {});
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
    _inputCtrl.removeListener(_onInputChanged);
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  // ============================================================
  // Actions
  // ============================================================

  Future<void> _sendMessage([String? presetText]) async {
    final text = (presetText ?? _inputCtrl.text).trim();
    if (text.isEmpty || _isTyping) return;

    if (presetText == null) {
      _inputCtrl.clear();
    }

    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _isTyping = true;
      _streamingText = '';
    });

    _scrollToBottom();

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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.refresh_rounded, color: AppColors.primary),
            SizedBox(width: 8),
            Text('เริ่มแชทใหม่'),
          ],
        ),
        content: const Text('ต้องการล้างประวัติการสนทนานี้และเริ่มใหม่หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _ollama.resetChat();
              setState(() {
                _messages.clear();
                _messages.add(ChatMessage(
                  text: 'เริ่มต้นการสนทนาใหม่แล้วค่ะ 🔄\n\nถามข้อมูลสัญญาหรือการเงินได้เลยค่ะ',
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

  void _showModelPickerSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'เลือกโมเดล AI',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: AppColors.ink,
                            ),
                          ),
                          Text(
                            'เลือกโมเดลที่ต้องการให้ตอบคำถามในการสนทนานี้',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () => Navigator.pop(sheetCtx),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(sheetCtx).size.height * 0.55,
                  ),
                  child: ListView(
                    shrinkWrap: true,
                    children: OllamaChatService.supportedModels.map((m) {
                      final isSelected = _ollama.selectedModelId == m.id;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primarySoft
                              : const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : const Color(0xFFEAECF0),
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 2,
                          ),
                          leading: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary
                                  : Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : const Color(0xFFD0D5DD),
                              ),
                            ),
                            child: Icon(
                              m.provider == AiProvider.gemini
                                  ? Icons.bolt_rounded
                                  : Icons.laptop_rounded,
                              size: 20,
                              color: isSelected ? Colors.white : AppColors.ink,
                            ),
                          ),
                          title: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  m.displayName,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.w600,
                                    color: isSelected
                                        ? AppColors.primaryDark
                                        : AppColors.ink,
                                  ),
                                ),
                              ),
                              if (m.isRecommended) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFECFDF3),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: const Color(0xFF6CE9A6),
                                    ),
                                  ),
                                  child: const Text(
                                    'แนะนำ',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF027A48),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          subtitle: Text(
                            m.subtitle,
                            style: TextStyle(
                              fontSize: 12,
                              color: isSelected
                                  ? AppColors.primaryDark.withValues(alpha: 0.8)
                                  : AppColors.muted,
                            ),
                          ),
                          trailing: isSelected
                              ? const Icon(
                                  Icons.check_circle_rounded,
                                  color: AppColors.primary,
                                  size: 22,
                                )
                              : null,
                          onTap: () {
                            setState(() {
                              _ollama.selectedModelId = m.id;
                            });
                            Navigator.pop(sheetCtx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('เปลี่ยนเป็นโมเดล: ${m.displayName}'),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
  // Suggestions
  // ============================================================

  static const List<String> _suggestions = [
    '📋 สรุปข้อมูลสัญญาของฉัน',
    '🤝 Qard Hasan คืออะไร?',
    '⚖️ สิทธิของผู้กู้มีอะไรบ้าง?',
    '💰 วิธีวางแผนชำระหนี้',
  ];

  // ============================================================
  // Build
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.page,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: AppColors.ink,
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.primaryBorder),
              ),
              child: const Icon(
                Icons.auto_awesome,
                size: 18,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Safa AI',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF12B76A),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'ผู้ช่วยอัจฉริยะ',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.muted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'เริ่มแชทใหม่',
            icon: const Icon(Icons.refresh_rounded, size: 22),
            color: AppColors.ink,
            onPressed: _clearChat,
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: const Color(0xFFEAECF0),
            height: 1,
          ),
        ),
      ),
      body: SafeArea(
        child: ResponsiveBody(
          maxWidth: Responsive.formMaxWidth(context),
          child: Column(
            children: [
              // ---- Chat Messages List ----
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
                      (_messages.length == 1 ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (_messages.length == 1 && index == 1) {
                      return _buildSuggestions();
                    }

                    final adjustedIndex =
                        (_messages.length == 1 && index > 1) ? index - 1 : index;

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

              // ---- Typing Indicator ----
              if (_isTyping && _streamingText.isEmpty)
                _buildTypingIndicator(),

              // ---- Redesigned Input Bar ----
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
          return InkWell(
            onTap: () => _sendMessage(text.replaceFirst(RegExp(r'^[\u{1F300}-\u{1F9FF}\s]+', unicode: true), '')),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primaryBorder),
              ),
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryDark,
                ),
              ),
            ),
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
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primaryBorder),
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: AppColors.primary,
                size: 17,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 18),
                ),
                border: isUser ? null : Border.all(color: const Color(0xFFE4E7EC)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
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
                    InkWell(
                      borderRadius: BorderRadius.circular(6),
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: message.text));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('คัดลอกข้อความแล้ว'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.copy_rounded,
                              size: 13,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'คัดลอก',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),
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

  Widget _buildFormattedText(String text, {required bool isUser}) {
    final color = isUser ? Colors.white : AppColors.ink;
    final spans = <TextSpan>[];
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

    return RichText(text: TextSpan(children: spans));
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
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primaryBorder),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: AppColors.primary,
              size: 17,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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

  /// แถบพิมพ์ข้อความดีไซน์ใหม่ที่กลมกลืนกับแอป สวยงาม สะอาดตา
  Widget _buildInputBar() {
    final canSend = !_isTyping && _inputCtrl.text.trim().isNotEmpty;

    return Container(
      padding: EdgeInsets.fromLTRB(
        Responsive.horizontalPadding(context),
        6,
        Responsive.horizontalPadding(context),
        10,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFD0D5DD), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // TextField ปรับแต่งให้ไม่มีพื้นหลังซ้ำซ้อน
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
              child: TextField(
                controller: _inputCtrl,
                focusNode: _inputFocus,
                maxLines: 4,
                minLines: 1,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 14.5,
                  height: 1.4,
                ),
                cursorColor: AppColors.primary,
                decoration: const InputDecoration(
                  hintText: 'ถามอะไรก็ได้เกี่ยวกับสัญญาหรือการเงิน...',
                  hintStyle: TextStyle(
                    color: Color(0xFF98A2B3),
                    fontSize: 14,
                  ),
                  filled: false,
                  fillColor: Colors.transparent,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                ),
              ),
            ),

            // แถบล่าง: [เลือกโมเดล AI ⌃] ... [ปุ่มส่ง ➔]
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 4, 10, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // ปุ่มเลือกโมเดล AI
                  InkWell(
                    onTap: _showModelPickerSheet,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2F4F7),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFEAECF0)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.auto_awesome,
                            size: 13,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            _ollama.selectedModelDisplayName,
                            style: const TextStyle(
                              color: Color(0xFF344054),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.keyboard_arrow_up_rounded,
                            size: 16,
                            color: Color(0xFF667085),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ปุ่มส่งข้อความ
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: canSend ? AppColors.primary : const Color(0xFFEAECF0),
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      tooltip: 'ส่งข้อความ',
                      onPressed: canSend ? () => _sendMessage() : null,
                      icon: Icon(
                        Icons.arrow_upward_rounded,
                        size: 19,
                        color: canSend ? Colors.white : const Color(0xFF98A2B3),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
