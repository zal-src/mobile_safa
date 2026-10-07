import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../models/user.dart';
import '../models/knowledge_article.dart';
import '../services/auth_service.dart';
import '../services/onboarding_service.dart';
import '../utils/responsive.dart';
import '../widgets/responsive_container.dart';
import '../widgets/onboarding_bottom_sheet.dart';
import 'ai_chat_page.dart';
import 'article_detail_page.dart';
import 'financial_health_check_page.dart';

class KnowledgePage extends StatefulWidget {
  final User user;

  const KnowledgePage({super.key, required this.user});

  @override
  State<KnowledgePage> createState() => _KnowledgePageState();
}

class _KnowledgePageState extends State<KnowledgePage> {
  final AuthService _authService = AuthService();
  final DatabaseHelper _database = DatabaseHelper.instance;

  late User _currentUser;
  Map<String, dynamic>? _currentAddress;

  // GlobalKeys สำหรับ spotlight
  final _keyHeader = GlobalKey();
  final _keyFirstSection = GlobalKey();
  final _keyAssessment = GlobalKey();
  @override
  void initState() {
    super.initState();
    _currentUser = widget.user;
    _loadUserProfile();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeShowOnboarding();
    });
  }

  Future<void> _loadUserProfile() async {
    if (_currentUser.userId == null) return;

    final address = await _database.getUserAddress(_currentUser.userId!);
    if (!mounted) return;

    setState(() {
      _currentAddress = address;
    });
  }

  Future<void> _maybeShowOnboarding() async {
    final seen = await OnboardingService.instance.hasSeenOnboarding(
      OnboardingService.keyKnowledge,
    );
    if (!mounted || seen) return;
    await OnboardingService.instance.markAsSeen(OnboardingService.keyKnowledge);
    if (!mounted) return;

    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    await SpotlightTutorial.show(
      context,
      steps: [
        TutorialStep(
          title: 'คลังความรู้ด้านการเงิน',
          description:
              'หน้านี้รวบรวมความรู้ด้านการเงินอิสลาม\nที่ช่วยให้คุณจัดการเงินได้อย่างถูกต้องตามหลักการ',
          targetKey: _keyHeader,
          spotlightPadding: const EdgeInsets.all(8),
        ),
        TutorialStep(
          title: 'อ่านบทความแต่ละหมวด',
          description:
              'บทความถูกแบ่งเป็น 4 หมวดหลัก\nกฎหมาย · การเงิน · เรื่องหนี้ · ความปลอดภัย\nแตะสักหัวเพื่อเปิดรายละเอียดทันที',
          targetKey: _keyFirstSection,
          spotlightPadding: const EdgeInsets.all(6),
        ),
        TutorialStep(
          title: 'เช็กสุขภาพการเงินของคุณ',
          description:
              'กด "เริ่มประเมิน" เพื่อตรวจสุขภาพการเงินพร้อมรับ\nคำแนะนำเฉพาะบุคคลในเวลาไม่กี่นาที',
          targetKey: _keyAssessment,
          spotlightPadding: const EdgeInsets.all(6),
        ),
      ],
    );
  }

  void _openArticle(BuildContext context, KnowledgeArticle article) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ArticleDetailPage(article: article, user: widget.user),
      ),
    );
  }

  void _openFinancialCheck(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FinancialHealthCheckPage()),
    );
  }

  Future<void> _showEditProfileDialog() async {
    if (!mounted) return;

    final formKey = GlobalKey<FormState>();
    final fullNameController = TextEditingController(
      text: _currentUser.fullName,
    );
    final emailController = TextEditingController(text: _currentUser.email);
    final phoneController = TextEditingController(
      text: _currentUser.phone ?? '',
    );
    final idCardController = TextEditingController(
      text: _currentUser.idCard ?? '',
    );
    final houseNumberController = TextEditingController(
      text:
          (_currentAddress?['address'] as String?)
              ?.replaceFirst('บ้านเลขที่ ', '')
              .split(' ')
              .first ??
          '',
    );
    final villageController = TextEditingController(
      text: (_currentAddress?['address'] as String?)?.contains('หมู่') == true
          ? (_currentAddress?['address'] as String?)
                    ?.split('หมู่')
                    .last
                    .trim()
                    .split(' ')
                    .first ??
                ''
          : '',
    );
    final roadController = TextEditingController(
      text: (_currentAddress?['address'] as String?)?.contains('ถนน') == true
          ? (_currentAddress?['address'] as String?)
                    ?.split('ถนน')
                    .last
                    .trim()
                    .split(' ')
                    .first ??
                ''
          : '',
    );
    final subdistrictController = TextEditingController(
      text: _currentAddress?['subdistrict'] ?? '',
    );
    final districtController = TextEditingController(
      text: _currentAddress?['district'] ?? '',
    );
    final provinceController = TextEditingController(
      text: _currentAddress?['province'] ?? '',
    );
    final postalCodeController = TextEditingController(
      text: _currentAddress?['postal_code'] ?? '',
    );
    final passwordController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('แก้ไขข้อมูลบัญชี'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: fullNameController,
                    decoration: const InputDecoration(
                      labelText: 'ชื่อ-นามสกุล',
                    ),
                    validator: (value) =>
                        (value == null || value.trim().isEmpty)
                        ? 'กรุณากรอกชื่อ-นามสกุล'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'อีเมล'),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'กรุณากรอกอีเมล';
                      }
                      return RegExp(
                            r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                          ).hasMatch(value.trim())
                          ? null
                          : 'รูปแบบอีเมลไม่ถูกต้อง';
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'เบอร์โทรศัพท์',
                    ),
                    validator: (value) {
                      final text = value?.trim() ?? '';
                      if (text.isEmpty) return 'กรุณากรอกเบอร์โทรศัพท์';
                      return RegExp(r'^\d{10}$').hasMatch(text)
                          ? null
                          : 'เบอร์โทรศัพท์ต้องมี 10 หลัก';
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: idCardController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'เลขบัตรประชาชน',
                    ),
                    validator: (value) {
                      final text = value?.trim() ?? '';
                      if (text.isEmpty) return 'กรุณากรอกเลขบัตรประชาชน';
                      return RegExp(r'^\d{13}$').hasMatch(text)
                          ? null
                          : 'เลขบัตรประชาชนต้องมี 13 หลัก';
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: houseNumberController,
                    decoration: const InputDecoration(labelText: 'บ้านเลขที่'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: villageController,
                    decoration: const InputDecoration(labelText: 'หมู่'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: roadController,
                    decoration: const InputDecoration(labelText: 'ถนน'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: subdistrictController,
                    decoration: const InputDecoration(labelText: 'ตำบล'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: districtController,
                    decoration: const InputDecoration(labelText: 'อำเภอ'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: provinceController,
                    decoration: const InputDecoration(labelText: 'จังหวัด'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: postalCodeController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'รหัสไปรษณีย์',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'รหัสผ่านใหม่ (เว้นว่างถ้าไม่ต้องการเปลี่ยน)',
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('ยกเลิก'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(dialogContext, true);
                }
              },
              child: const Text('บันทึก'),
            ),
          ],
        );
      },
    );

    if (result != true || _currentUser.userId == null) return;

    try {
      final updatedUser = await _authService.updateProfile(
        userId: _currentUser.userId!,
        fullName: fullNameController.text,
        email: emailController.text,
        password: passwordController.text,
        phone: phoneController.text,
        idCard: idCardController.text,
        houseNumber: houseNumberController.text,
        village: villageController.text,
        road: roadController.text,
        subdistrict: subdistrictController.text,
        district: districtController.text,
        province: provinceController.text,
        postalCode: postalCodeController.text,
      );

      if (!mounted) return;

      if (updatedUser != null) {
        final refreshedAddress = await _database.getUserAddress(
          _currentUser.userId!,
        );
        if (!mounted) return;
        setState(() {
          _currentUser = updatedUser;
          _currentAddress = refreshedAddress;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('อัปเดตข้อมูลบัญชีสำเร็จ')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  String _formatAddress(Map<String, dynamic>? address) {
    if (address == null) {
      return 'ไม่ได้ระบุที่อยู่';
    }

    final parts = <String>[];
    final rawAddress = (address['address'] as String?) ?? '';
    if (rawAddress.trim().isNotEmpty) {
      parts.add(rawAddress.trim());
    }

    final subdistrict = (address['subdistrict'] as String?)?.trim();
    final district = (address['district'] as String?)?.trim();
    final province = (address['province'] as String?)?.trim();
    final postalCode = (address['postal_code'] as String?)?.trim();

    if (subdistrict != null && subdistrict.isNotEmpty) {
      parts.add('ตำบล$subdistrict');
    }
    if (district != null && district.isNotEmpty) {
      parts.add('อำเภอ$district');
    }
    if (province != null && province.isNotEmpty) {
      parts.add('จังหวัด$province');
    }
    if (postalCode != null && postalCode.isNotEmpty) {
      parts.add('รหัสไปรษณีย์ $postalCode');
    }

    return parts.isNotEmpty ? parts.join(' ') : 'ไม่ได้ระบุที่อยู่';
  }

  @override
  Widget build(BuildContext context) {
    final lawArticles = KnowledgeData.articles
        .where((a) => a.category == 'กฎหมายที่ควรรู้')
        .toList();
    final moneyArticles = KnowledgeData.articles
        .where((a) => a.category == 'จัดการเงินของฉัน')
        .toList();
    final debtArticles = KnowledgeData.articles
        .where((a) => a.category == 'ความรู้เรื่องหนี้')
        .toList();
    final safeArticles = KnowledgeData.articles
        .where((a) => a.category == 'ความปลอดภัย')
        .toList();

    final hPadding = Responsive.horizontalPadding(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: Colors.grey.shade200, height: 1.0),
        ),
        title: null,
        actions: [
          IconButton(
            tooltip: 'ค้นหาด้วย AI',
            icon: const Icon(Icons.search, color: Colors.black87),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AiChatPage()),
              );
            },
          ),
        ],
      ),
      body: ResponsiveBody(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(hPadding, 16, hPadding, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(key: _keyHeader),
              const SizedBox(height: 24),
              _buildSection(
                context: context,
                sectionKey: _keyFirstSection,
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
              _buildAssessmentBanner(context, key: _keyAssessment),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader({Key? key}) {
    return Row(
      key: key,
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
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSection({
    required BuildContext context,
    Key? sectionKey,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String badgeText,
    required List<KnowledgeArticle> articles,
  }) {
    return Container(
      key: sectionKey,
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
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
                      bottom: entry.key != articles.length - 1 ? 12 : 0,
                    ),
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

  Widget _buildAssessmentBanner(BuildContext context, {Key? key}) {
    return Container(
      key: key,
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
            child: const Icon(
              Icons.monitor_heart_outlined,
              color: Color(0xFF087443),
              size: 28,
            ),
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
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
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
            child: const Text(
              'เริ่มประเมิน',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileInfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _ProfileInfoRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF667085)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF98A2B3),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF101828),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
