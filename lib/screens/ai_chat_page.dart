import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/user.dart';
import '../services/contract_service.dart';
import '../services/ollama_chat_service.dart';
import '../services/pdf_service_printable.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';
import '../widgets/responsive_container.dart';
import 'contract_list_page.dart';
import 'create_contract_page.dart';

// ============================================================
// Data Model & Actions
// ============================================================

class WebReference {
  final String title;
  final String url;

  const WebReference({required this.title, required this.url});
}

class AppChatAction {
  final String type; // 'CREATE_CONTRACT', 'VIEW_CONTRACTS', 'BLANK_PDF'
  final Map<String, dynamic> data;

  AppChatAction({required this.type, required this.data});
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final AppChatAction? action;

  ChatMessage({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
    this.action,
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
          'คุณสามารถสั่งฉันให้ทำรายการได้ เช่น:\n'
          '• ➕ *"สร้างสัญญาให้หน่อย กู้ 5,000 บาท"*\n'
          '• 📋 *"สรุปข้อมูลสัญญาของฉัน"*\n'
          '• 📄 *"ขอแบบฟอร์มสัญญาเปล่า"*\n\n'
          'พิมพ์บอกฉันได้เลยค่ะ!',
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
  // Action Handlers
  // ============================================================

  void _handleCreateContractAction(Map<String, dynamic> data, String role) {
    final user = widget.user;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเข้าสู่ระบบก่อนสร้างสัญญาค่ะ')),
      );
      return;
    }

    double? amount;
    if (data['amount'] != null) {
      amount = double.tryParse(data['amount'].toString());
    }
    final purpose = data['purpose']?.toString();
    final returnDate = data['return_date']?.toString();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateContractPage(
          user: user,
          role: role,
          initialAmount: amount,
          initialPurpose: purpose,
          initialReturnDate: returnDate,
        ),
      ),
    );
  }

  void _handleViewContractsAction() {
    final user = widget.user;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเข้าสู่ระบบก่อนดูรายการสัญญาค่ะ')),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ContractListPage(user: user),
      ),
    );
  }

  Future<void> _handleBlankPdfAction() async {
    try {
      await PrintablePdfService().printBlankContractTemplate();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ไม่สามารถเปิด PDF เปล่าได้: $e')),
      );
    }
  }

  Future<void> _launchExternalUrl(String rawUrl) async {
    var url = rawUrl.trim();
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }

    final uri = Uri.tryParse(url);
    if (uri == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ลิงก์ไม่ถูกต้อง: $rawUrl')),
        );
      }
      return;
    }

    bool launched = false;
    try {
      if (await canLaunchUrl(uri)) {
        launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('launchUrl error: $e');
    }

    // Fallback on Windows if platform plugins are restricted
    if (!launched && !kIsWeb && Platform.isWindows) {
      try {
        final result = await Process.run('cmd', ['/c', 'start', '', url]);
        if (result.exitCode == 0) {
          launched = true;
        }
      } catch (_) {}
    }

    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ไม่สามารถเปิดลิงก์ภายนอกได้: $url')),
      );
    }
  }

  String _cleanActionText(String text) {
    return text.replaceAll(RegExp(r'<<<ACTION:.*?>>>', dotAll: true), '').trim();
  }

  AppChatAction? _extractAction(String aiText, {required String userPrompt}) {
    // 1. ตรวจจับจาก Action tag ที่ AI ส่งมา
    final match = RegExp(r'<<<ACTION:([A-Z_]+):(.*?)(?:>>>|$)', dotAll: true).firstMatch(aiText);
    if (match != null) {
      final type = match.group(1)!.trim();
      final jsonStr = match.group(2)!.trim();
      Map<String, dynamic> data = {};
      try {
        if (jsonStr.isNotEmpty) {
          data = jsonDecode(jsonStr) as Map<String, dynamic>;
        }
      } catch (_) {}
      return AppChatAction(type: type, data: data);
    }

    // 2. Fallback ตรวจจับจากเจตนาของผู้ใช้ในข้อความ prompt
    final lowerPrompt = userPrompt.toLowerCase();
    if (lowerPrompt.contains('สร้างสัญญา') ||
        lowerPrompt.contains('ทำสัญญา') ||
        lowerPrompt.contains('สร้างรายการ') ||
        lowerPrompt.contains('เพิ่มสัญญา') ||
        lowerPrompt.contains('ขอกู้') ||
        lowerPrompt.contains('ให้กู้') ||
        lowerPrompt.contains('ยืมเงิน')) {
      final amountMatch = RegExp(r'(\d+[\d,]*)\s*(?:บาท|฿)?').firstMatch(userPrompt);
      double? amount;
      if (amountMatch != null) {
        amount = double.tryParse(amountMatch.group(1)!.replaceAll(',', ''));
      }
      String? role;
      if (lowerPrompt.contains('ให้กู้') || lowerPrompt.contains('ให้ยืม')) {
        role = 'lender';
      } else if (lowerPrompt.contains('ขอกู้') || lowerPrompt.contains('ขอยืม')) {
        role = 'borrower';
      }
      final data = <String, dynamic>{};
      if (amount != null && amount > 0) {
        data['amount'] = amount;
      }
      if (role != null) {
        data['role'] = role;
      }
      return AppChatAction(
        type: 'CREATE_CONTRACT',
        data: data,
      );
    }

    if (lowerPrompt.contains('ดูรายการสัญญา') ||
        lowerPrompt.contains('เปิดดูสัญญา') ||
        lowerPrompt.contains('ดูสัญญา')) {
      return AppChatAction(type: 'VIEW_CONTRACTS', data: {});
    }

    if (lowerPrompt.contains('สัญญาเปล่า') ||
        lowerPrompt.contains('แบบฟอร์มเปล่า') ||
        lowerPrompt.contains('พิมพ์สัญญา')) {
      return AppChatAction(type: 'BLANK_PDF', data: {});
    }

    return null;
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
      final currentText = buffer.toString();
      final tagIndex = currentText.indexOf('<<<ACTION:');
      final displayText = tagIndex != -1 ? currentText.substring(0, tagIndex).trim() : currentText;
      setState(() => _streamingText = displayText);
      _scrollToBottom();
    }

    if (!mounted) return;

    final rawText = buffer.toString();
    final action = _extractAction(rawText, userPrompt: text);
    final cleanText = _cleanActionText(rawText);

    setState(() {
      _messages.add(ChatMessage(
        text: cleanText.isNotEmpty ? cleanText : 'ดำเนินการเรียบร้อยแล้วค่ะ',
        isUser: false,
        action: action,
      ));
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
                  text: 'เริ่มต้นการสนทนาใหม่แล้วค่ะ 🔄\n\nถามข้อมูลสัญญาหรือสั่งสร้างรายการได้เลยค่ะ',
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
                              Icons.bolt_rounded,
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
    '➕ สร้างสัญญาเงินกู้ใหม่',
    '📋 สรุปข้อมูลสัญญาของฉัน',
    '🤝 Qard Hasan คืออะไร?',
    '⚖️ สิทธิของผู้กู้มีอะไรบ้าง?',
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
                      final cleanStreaming = _cleanActionText(_streamingText);
                      return _buildMessageBubble(
                        ChatMessage(text: cleanStreaming, isUser: false),
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

  Widget _buildActionCard(AppChatAction action) {
    if (action.type == 'CREATE_CONTRACT') {
      final amount = action.data['amount'];
      final purpose = action.data['purpose'];
      final role = action.data['role']?.toString();

      return Container(
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.primarySoft,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primaryBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.post_add_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'รายการสร้างสัญญาเงินกู้ (Qard Hasan)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
              ],
            ),
            if (amount != null || purpose != null) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE4E7EC)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (amount != null)
                      Text(
                        '💰 ยอดเงินกู้: $amount บาท',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink,
                        ),
                      ),
                    if (purpose != null && purpose.toString().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        '🎯 วัตถุประสงค์: $purpose',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            const SizedBox(height: 10),
            if (role == 'lender') ...[
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                  label: const Text(
                    'เปิดหน้าสร้างสัญญา (ฉันเป็นผู้ให้กู้)',
                    style: TextStyle(fontSize: 12.5),
                  ),
                  onPressed: () => _handleCreateContractAction(action.data, 'lender'),
                ),
              ),
            ] else if (role == 'borrower') ...[
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                  label: const Text(
                    'เปิดหน้าสร้างสัญญา (ฉันเป็นผู้กู้)',
                    style: TextStyle(fontSize: 12.5),
                  ),
                  onPressed: () => _handleCreateContractAction(action.data, 'borrower'),
                ),
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      icon: const Icon(Icons.volunteer_activism_rounded, size: 15),
                      label: const Text(
                        'ฉันเป็นผู้ให้กู้',
                        style: TextStyle(fontSize: 12),
                      ),
                      onPressed: () => _handleCreateContractAction(action.data, 'lender'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryDark,
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      icon: const Icon(Icons.handshake_rounded, size: 15),
                      label: const Text(
                        'ฉันเป็นผู้กู้',
                        style: TextStyle(fontSize: 12),
                      ),
                      onPressed: () => _handleCreateContractAction(action.data, 'borrower'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      );
    } else if (action.type == 'VIEW_CONTRACTS') {
      return Container(
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF2F4F7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFD0D5DD)),
        ),
        child: Row(
          children: [
            const Icon(Icons.folder_shared_rounded, color: AppColors.primary, size: 24),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'ดูรายการสัญญาเงินกู้ทั้งหมด',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                visualDensity: VisualDensity.compact,
              ),
              onPressed: _handleViewContractsAction,
              child: const Text('เปิดดู', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      );
    } else if (action.type == 'BLANK_PDF') {
      return Container(
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF2F4F7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFD0D5DD)),
        ),
        child: Row(
          children: [
            const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFFD92D20), size: 24),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'แบบฟอร์มสัญญาเปล่า (PDF)',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
              ),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.ink,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                visualDensity: VisualDensity.compact,
              ),
              icon: const Icon(Icons.print_rounded, size: 14),
              label: const Text('พิมพ์', style: TextStyle(fontSize: 12)),
              onPressed: _handleBlankPdfAction,
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
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
                  if (!isUser && !isStreaming)
                    _buildReferencesSection(message.text),
                  if (message.action != null && !isStreaming)
                    _buildActionCard(message.action!),
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

  List<WebReference> _extractReferences(String text) {
    final list = <WebReference>[];
    final seen = <String>{};

    // 1. [Title](URL)
    final mdRegex = RegExp(
      r'\[(.*?)\]\(((?:https?:\/\/|www\.)[^\s\)]+)\)',
      caseSensitive: false,
    );
    for (final m in mdRegex.allMatches(text)) {
      final title = m.group(1)?.trim() ?? '';
      var url = m.group(2)?.trim() ?? '';
      if (url.isNotEmpty && !seen.contains(url)) {
        seen.add(url);
        list.add(WebReference(title: title.isNotEmpty ? title : url, url: url));
      }
    }

    // 2. Standalone URL
    final urlRegex = RegExp(
      r'((?:https?:\/\/)[^\s\)\],]+)',
      caseSensitive: false,
    );
    for (final m in urlRegex.allMatches(text)) {
      final url = m.group(1)?.trim() ?? '';
      if (url.isNotEmpty && !seen.contains(url)) {
        seen.add(url);
        final domain = Uri.tryParse(url)?.host ?? url;
        list.add(WebReference(title: domain, url: url));
      }
    }

    return list;
  }

  Widget _buildReferencesSection(String text) {
    final refs = _extractReferences(text);
    if (refs.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.link_rounded, size: 15, color: AppColors.primary),
              SizedBox(width: 6),
              Text(
                'แหล่งอ้างอิงทางการ (แตะเพื่อเปิดเว็บไซต์จริง):',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: refs.map((ref) {
              return InkWell(
                onTap: () => _launchExternalUrl(ref.url),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF86EFAC)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.public_rounded, size: 13, color: AppColors.primary),
                      const SizedBox(width: 5),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 220),
                        child: Text(
                          ref.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.open_in_new_rounded, size: 11, color: AppColors.primary),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFormattedText(String text, {required bool isUser}) {
    final color = isUser ? Colors.white : AppColors.ink;
    final linkColor = isUser ? const Color(0xFFE0F2FE) : const Color(0xFF0284C7);

    // Match Markdown link: [Title](URL) or standalone (https?://...)
    final linkRegex = RegExp(
      r'\[(.*?)\]\(((?:https?:\/\/|www\.)[^\s\)]+)\)|((?:https?:\/\/)[^\s\)\],]+)',
      caseSensitive: false,
    );

    final spans = <InlineSpan>[];
    int lastEnd = 0;

    for (final match in linkRegex.allMatches(text)) {
      if (match.start > lastEnd) {
        final preceding = text.substring(lastEnd, match.start);
        spans.addAll(_parseBoldSpans(preceding, color));
      }

      if (match.group(1) != null && match.group(2) != null) {
        final title = match.group(1)!;
        final url = match.group(2)!;
        spans.add(
          TextSpan(
            text: '$title ↗',
            style: TextStyle(
              color: linkColor,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.underline,
              decorationColor: linkColor,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () => _launchExternalUrl(url),
          ),
        );
      } else if (match.group(3) != null) {
        final url = match.group(3)!;
        spans.add(
          TextSpan(
            text: '$url ↗',
            style: TextStyle(
              color: linkColor,
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              decoration: TextDecoration.underline,
              decorationColor: linkColor,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () => _launchExternalUrl(url),
          ),
        );
      }

      lastEnd = match.end;
    }

    if (lastEnd < text.length) {
      final remaining = text.substring(lastEnd);
      spans.addAll(_parseBoldSpans(remaining, color));
    }

    return Text.rich(
      TextSpan(children: spans),
      style: const TextStyle(height: 1.5),
    );
  }

  List<InlineSpan> _parseBoldSpans(String text, Color defaultColor) {
    final spans = <InlineSpan>[];
    final boldRegex = RegExp(r'\*\*(.*?)\*\*');
    int lastEnd = 0;

    for (final match in boldRegex.allMatches(text)) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: text.substring(lastEnd, match.start),
          style: TextStyle(color: defaultColor, fontSize: 14, height: 1.5),
        ));
      }
      spans.add(TextSpan(
        text: match.group(1),
        style: TextStyle(
          color: defaultColor,
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
        style: TextStyle(color: defaultColor, fontSize: 14, height: 1.5),
      ));
    }

    return spans;
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
                  hintText: 'ถามอะไรก็ได้ เช่น "สร้างสัญญาให้หน่อย 5000 บาท"',
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
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 4, 10, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
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
