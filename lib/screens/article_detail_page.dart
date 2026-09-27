import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/knowledge_article.dart';
import '../models/user.dart';
import '../theme/app_theme.dart';
import '../widgets/responsive_container.dart';

class ArticleDetailPage extends StatelessWidget {
  final KnowledgeArticle article;
  final User user;

  const ArticleDetailPage({
    super.key,
    required this.article,
    required this.user,
  });

  void _openUrl(BuildContext context, String url) {
    // In a real app, this would use url_launcher
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('กำลังเปิด: $url'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      appBar: AppTheme.buildSafaAppBar(
        context,
        title: article.category,
        actions: [
          IconButton(
            tooltip: 'แชร์บทความ',
            icon: const Icon(Icons.ios_share, color: AppColors.ink),
            onPressed: () => _showShareModal(context),
          ),
        ],
      ),
      body: ResponsiveBody(
        child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEECFF),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      article.category,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF5A4FCF),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    article.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF101828),
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article.content,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF344054),
                      height: 1.7,
                    ),
                  ),
                  if (article.references.isNotEmpty) ...[
                    const SizedBox(height: 32),
                    const Divider(color: Color(0xFFEAECF0)),
                    const SizedBox(height: 24),
                    const Text(
                      'แหล่งอ้างอิง',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF101828),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...article.references.map((ref) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: InkWell(
                            onTap: () => _openUrl(context, ref.url),
                            borderRadius: BorderRadius.circular(8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.link_rounded, size: 20, color: Color(0xFF087443)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    ref.title,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF087443),
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )),
                  ],
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFEAECF0)),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline, color: Color(0xFF667085), size: 20),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'หมายเหตุ: เนื้อหานี้จัดทำเพื่อให้ความรู้ทั่วไป ไม่ใช่คำปรึกษาทางกฎหมาย หากมีข้อพิพาทหรือกรณีเฉพาะ ควรปรึกษาผู้เชี่ยวชาญด้านกฎหมาย',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF667085),
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  const Divider(color: Color(0xFFEAECF0)),
                  const SizedBox(height: 24),
                  const Center(
                    child: Text(
                      'บทความนี้มีประโยชน์ไหม?',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF101828),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildFeedbackButton(Icons.thumb_up_alt_outlined, 'มีประโยชน์'),
                      const SizedBox(width: 16),
                      _buildFeedbackButton(Icons.thumb_down_alt_outlined, 'ไม่มีประโยชน์'),
                    ],
                  ),
                  const SizedBox(height: 40),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF101828),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'พร้อมทำสัญญาแล้วหรือยัง?',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'ส่งต่อความรู้ให้คู่สัญญาอ่านก่อน\nแล้วเริ่มทำสัญญาที่ปลอดภัยร่วมกัน',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFFD0D5DD),
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              // Simulate creating a contract
                              Navigator.pop(context);
                              // Typically we would push to Create Contract Page
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF101828),
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'สร้างสัญญาใหม่',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildFeedbackButton(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEAECF0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: const Color(0xFF475467)),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF475467),
            ),
          ),
        ],
      ),
    );
  }

  void _showShareModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'แชร์บทความ 📤',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF101828),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'ส่งความรู้ให้คู่สัญญาอ่านก่อนทำสัญญา เพื่อความเข้าใจที่ตรงกัน',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF667085),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFEAECF0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.article_outlined, color: Color(0xFF4B39EF), size: 32),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          article.title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF101828),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'อ่านก่อนทำสัญญา',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF087443),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildShareIcon(Icons.chat_bubble_outline, 'LINE', const Color(0xFF00B900)),
                _buildShareIcon(Icons.message_outlined, 'Messenger', const Color(0xFF0084FF)),
                InkWell(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: 'อ่านบทความ ${article.title}'));
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('คัดลอกลิงก์แล้ว')),
                    );
                  },
                  child: Column(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: const Icon(Icons.link, color: Color(0xFF475569)),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'คัดลอกลิงก์',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF475569),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildShareIcon(IconData icon, String label, Color color) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF475569),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
