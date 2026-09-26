import 'package:flutter/material.dart';

import '../models/user.dart';
import '../models/knowledge_article.dart';
import '../utils/responsive.dart';
import '../widgets/responsive_container.dart';
import 'article_detail_page.dart';
import 'financial_health_check_page.dart';

class KnowledgePage extends StatelessWidget {
  final User user;

  const KnowledgePage({super.key, required this.user});

  void _openArticle(BuildContext context, KnowledgeArticle article) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ArticleDetailPage(article: article, user: user),
      ),
    );
  }

  void _openFinancialCheck(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const FinancialHealthCheckPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lawArticles = KnowledgeData.articles.where((a) => a.category == 'กฎหมายที่ควรรู้').toList();
    final moneyArticles = KnowledgeData.articles.where((a) => a.category == 'จัดการเงินของฉัน').toList();
    final debtArticles = KnowledgeData.articles.where((a) => a.category == 'ความรู้เรื่องหนี้').toList();
    final safeArticles = KnowledgeData.articles.where((a) => a.category == 'ความปลอดภัย').toList();

    final hPadding = Responsive.horizontalPadding(context);

    return ResponsiveBody(
      child: SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(hPadding, 50, hPadding, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAppHeader(),
          const SizedBox(height: 32),
          _buildHeader(),
          const SizedBox(height: 24),
          _buildSection(
            context: context,
            title: 'กฎหมายที่ควรรู้',
            subtitle: 'เข้าใจสิทธิและหน้าที่',
            icon: Icons.gavel_rounded,
            iconColor: const Color(0xFF4B39EF),
            iconBgColor: const Color(0xFFEEECFF),
            badgeText: '⚖️ กฎหมาย',
            articles: lawArticles,
          ),
          const SizedBox(height: 24),
          _buildSection(
            context: context,
            title: 'จัดการเงินของฉัน',
            subtitle: 'วางแผนวันนี้ เพื่ออนาคต',
            icon: Icons.account_balance_wallet_outlined,
            iconColor: const Color(0xFF087443),
            iconBgColor: const Color(0xFFE8F7F1),
            badgeText: '💰 การเงิน',
            articles: moneyArticles,
          ),
          const SizedBox(height: 24),
          _buildSection(
            context: context,
            title: 'ความรู้เรื่องหนี้',
            subtitle: 'รับมือปัญหาหนี้อย่างฉลาด',
            icon: Icons.menu_book_outlined,
            iconColor: const Color(0xFF5A4FCF),
            iconBgColor: const Color(0xFFF1EEFF),
            badgeText: '📚 เรื่องหนี้',
            articles: debtArticles,
          ),
          const SizedBox(height: 24),
          _buildSection(
            context: context,
            title: 'ความปลอดภัย',
            subtitle: 'ปกป้องข้อมูลและตัวคุณ',
            icon: Icons.security_outlined,
            iconColor: const Color(0xFFD92D20),
            iconBgColor: const Color(0xFFFEE4E2),
            badgeText: '🔐 ป้องกัน',
            articles: safeArticles,
          ),
          const SizedBox(height: 24),
          _buildAssessmentBanner(context),
        ],
      ),
    ),
    );
  }

  Widget _buildAppHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.eco, color: const Color(0xFF4B6F60), size: 28),
            const SizedBox(width: 8),
            const Text(
              'Qard Hasan',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1A1C3D),
              ),
            ),
          ],
        ),
        const Icon(Icons.notifications_none, size: 28, color: Color(0xFF101828)),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'ความรู้และการจัดการเงิน',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF101828),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'รู้สิทธิ วางแผนเงิน จัดการหนี้อย่างมีวินัย',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: const Color(0xFFE8F7F1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(
            Icons.eco,
            color: Color(0xFF087443),
            size: 40,
          ),
        ),
      ],
    );
  }

  Widget _buildSection({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String badgeText,
    required List<KnowledgeArticle> articles,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFEAECF0)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF101828),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF667085),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FC),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  badgeText,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF475467),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Column(
            children: articles
                .asMap()
                .entries
                .map(
                  (entry) => Padding(
                    padding: EdgeInsets.only(
                        bottom: entry.key != articles.length - 1 ? 12 : 0),
                    child: _buildListItem(
                      context: context,
                      article: entry.value,
                      iconColor: iconColor,
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildListItem({
    required BuildContext context,
    required KnowledgeArticle article,
    required Color iconColor,
  }) {
    return InkWell(
      onTap: () => _openArticle(context, article),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEAECF0)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    article.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF101828),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            const Icon(Icons.chevron_right, size: 20, color: Color(0xFF98A2B3)),
          ],
        ),
      ),
    );
  }

  Widget _buildAssessmentBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F7F1),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF087443).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.monitor_heart_outlined,
                color: Color(0xFF087443), size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'เช็กสุขภาพการเงิน',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF101828),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'ใช้เวลาไม่กี่นาที',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _openFinancialCheck(context),
            style: ElevatedButton.styleFrom(
              minimumSize: Size.zero,
              backgroundColor: const Color(0xFF101828),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Text('เริ่มประเมิน',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
