import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../database/database_helper.dart';
import '../models/loan_contract.dart';
import '../models/user.dart';
import 'contract_detail_page.dart';
import 'contract_list_page.dart';
import 'contract_role_page.dart';
import 'login_page.dart';
import 'knowledge_page.dart';
import '../theme/app_theme.dart';

class HomePage extends StatefulWidget {
  final User user;

  const HomePage({super.key, required this.user});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final DatabaseHelper _database = DatabaseHelper.instance;

  int _currentIndex = 0;
  bool _isLoading = true;

  double _totalLent = 0;
  double _totalBorrowed = 0;
  int _contractCount = 0;

  List<Map<String, dynamic>> _recentContracts = [];

  final NumberFormat _moneyFormat = NumberFormat('#,##0.00', 'en_US');
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    final userId = widget.user.userId;

    if (userId == null) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      return;
    }

    try {
      final database = await _database.database;

      final lentResult = await database.rawQuery(
        '''
        SELECT COALESCE(SUM(amount), 0) AS total
        FROM loan_contracts
        WHERE lender_id = ?
        ''',
        [userId],
      );

      final borrowedResult = await database.rawQuery(
        '''
        SELECT COALESCE(SUM(amount), 0) AS total
        FROM loan_contracts
        WHERE borrower_id = ?
        ''',
        [userId],
      );

      final countResult = await database.rawQuery(
        '''
        SELECT COUNT(*) AS total
        FROM loan_contracts
        WHERE lender_id = ? OR borrower_id = ?
        ''',
        [userId, userId],
      );

      final recentResult = await database.rawQuery(
        '''
        SELECT
          lc.*,
          lender.full_name AS lender_name,
          borrower.full_name AS borrower_name
        FROM loan_contracts lc
        INNER JOIN users lender ON lender.user_id = lc.lender_id
        INNER JOIN users borrower ON borrower.user_id = lc.borrower_id
        WHERE lc.lender_id = ? OR lc.borrower_id = ?
        ORDER BY COALESCE(lc.updated_at, lc.created_at) DESC,
                 lc.contract_id DESC
        LIMIT 5
        ''',
        [userId, userId],
      );

      if (!mounted) return;

      setState(() {
        _totalLent = (lentResult.first['total'] as num?)?.toDouble() ?? 0;
        _totalBorrowed =
            (borrowedResult.first['total'] as num?)?.toDouble() ?? 0;
        _contractCount = (countResult.first['total'] as num?)?.toInt() ?? 0;
        _recentContracts = recentResult;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('HomePage: load dashboard error: $e');

      if (!mounted) return;

      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ไม่สามารถโหลดข้อมูลหน้าแรกได้')),
      );
    }
  }

  void _openCreateContract() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ContractRolePage(user: widget.user),
      ),
    ).then((_) => _loadDashboard());
  }

  void _openContracts() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ContractListPage(user: widget.user),
      ),
    ).then((_) {
      if (!mounted) return;
      setState(() => _currentIndex = 0);
      _loadDashboard();
    });
  }



  void _openContractDetail(Map<String, dynamic> contract) {
    try {
      final loanContract = LoanContract.fromMap(contract);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              ContractDetailPage(user: widget.user, contract: loanContract),
        ),
      ).then((_) => _loadDashboard());
    } catch (e) {
      debugPrint('HomePage: open contract error: $e');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ไม่สามารถเปิดรายละเอียดสัญญาได้')),
      );
    }
  }

  void _onBottomNavigationTap(int index) {
    switch (index) {
      case 0:
        if (_currentIndex != 0) {
          setState(() => _currentIndex = 0);
        }
        _loadDashboard();
        break;

      case 1:
        setState(() => _currentIndex = 1);
        _openContracts();
        break;

      case 2:
        setState(() => _currentIndex = 2);
        break;

      case 3:
        setState(() => _currentIndex = 3);
        _showProfile().whenComplete(() {
          if (!mounted) return;
          setState(() => _currentIndex = 0);
        });
        break;
    }
  }

  Future<void> _showProfile() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: AppColors.purpleSoft,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(
                        Icons.person_outline,
                        color: AppColors.primary,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.user.fullName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.user.email,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'ข้อมูลบัญชี',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF101828),
                  ),
                ),
                const SizedBox(height: 12),
                _ProfileInfoRow(
                  icon: Icons.person_outline,
                  title: 'ชื่อ-นามสกุล',
                  value: widget.user.fullName,
                ),
                _ProfileInfoRow(
                  icon: Icons.email_outlined,
                  title: 'อีเมล',
                  value: widget.user.email,
                ),
                if (widget.user.phone != null &&
                    widget.user.phone!.trim().isNotEmpty)
                  _ProfileInfoRow(
                    icon: Icons.phone_outlined,
                    title: 'เบอร์โทรศัพท์',
                    value: widget.user.phone!,
                  ),
                if (widget.user.idCard != null &&
                    widget.user.idCard!.trim().isNotEmpty)
                  _ProfileInfoRow(
                    icon: Icons.badge_outlined,
                    title: 'เลขบัตรประชาชน',
                    value: widget.user.idCard!,
                  ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      _showLogoutDialog();
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text('ออกจากระบบ'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFD92D20),
                      side: const BorderSide(color: Color(0xFFFECACA)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showLogoutDialog() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('ออกจากระบบ'),
          content: const Text('คุณต้องการออกจากระบบหรือไม่?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('ยกเลิก'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _logout();
              },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF101828),
              ),
              child: const Text('ออกจากระบบ'),
            ),
          ],
        );
      },
    );
  }

  void _logout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (route) => false,
    );
  }

  String _formatMoney(double value) => _moneyFormat.format(value);

  String _formatDate(String? date) {
    if (date == null || date.trim().isEmpty) return '-';

    try {
      return _dateFormat.format(DateTime.parse(date));
    } catch (_) {
      return date;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      appBar: _currentIndex == 2 ? null : AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: const Color(0xFFF8F9FC),
        surfaceTintColor: Colors.transparent,
        titleSpacing: 18,
        title: const Text(
          'ภาพรวม',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: Color(0xFF101828),
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'โปรไฟล์',
            onPressed: _showProfile,
            icon: const Icon(Icons.person_outline, color: Color(0xFF344054)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _currentIndex == 2 
          ? KnowledgePage(user: widget.user)
          : RefreshIndicator(
        onRefresh: _loadDashboard,
        color: const Color(0xFF101828),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF101828)),
              )
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildWelcomeCard(),
                    const SizedBox(height: 18),
                    _buildSummarySection(),
                    const SizedBox(height: 24),
                    _buildRecentContractsSection(),
                    const SizedBox(height: 18),
                    _buildCreateContractButton(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF101828),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.account_balance_wallet_outlined,
              color: Colors.white,
              size: 27,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ยินดีต้อนรับกลับมา',
                  style: TextStyle(fontSize: 13, color: Color(0xFFD0D5DD)),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.user.fullName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'จัดการสัญญา Qard Hasan ของคุณ',
                  style: TextStyle(fontSize: 12, color: Color(0xFF98A2B3)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'สรุปบัญชี',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF101828),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _SummaryCard(
                title: 'เงินที่ให้กู้',
                value: _formatMoney(_totalLent),
                icon: Icons.arrow_upward_rounded,
                iconBackground: const Color(0xFFE8F7F1),
                iconColor: const Color(0xFF087443),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryCard(
                title: 'เงินที่กู้',
                value: _formatMoney(_totalBorrowed),
                icon: Icons.arrow_downward_rounded,
                iconBackground: const Color(0xFFFFEDED),
                iconColor: const Color(0xFFD92D20),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _SummaryWideCard(
          title: 'สัญญาทั้งหมด',
          value: '$_contractCount รายการ',
          icon: Icons.description_outlined,
          onTap: _openContracts,
        ),
      ],
    );
  }

  Widget _buildRecentContractsSection() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'สัญญาที่ใช้งานและล่าสุด',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF101828),
          ),
        ),
        const SizedBox(height: 10),
        if (_recentContracts.isEmpty)
          _buildEmptyContracts()
        else
          Column(
            mainAxisSize: MainAxisSize.min,
            children: _recentContracts
                .map((contract) => _buildContractCard(contract))
                .toList(),
          ),
      ],
    );
  }

  Widget _buildEmptyContracts() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE4E7EC)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFF2F4F7),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.description_outlined,
              color: Color(0xFF667085),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'ยังไม่มีสัญญา',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF101828),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'สร้างสัญญา Qard Hasan รายการแรกของคุณ',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildContractCard(Map<String, dynamic> contract) {
    final userId = widget.user.userId;
    final lenderId = (contract['lender_id'] as num?)?.toInt();

    final isLender = lenderId == userId;

    final otherPerson = isLender
        ? (contract['borrower_name']?.toString() ?? '-')
        : (contract['lender_name']?.toString() ?? '-');

    final amount = (contract['amount'] as num?)?.toDouble() ?? 0;

    final agreementId = contract['agreement_id']?.toString() ?? '-';

    final returnDate = contract['return_date']?.toString();

    final status = contract['status']?.toString();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openContractDetail(contract),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE4E7EC)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.025),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: isLender
                          ? const Color(0xFFEFF8F4)
                          : const Color(0xFFF1EEFF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isLender ? 'ผู้ให้กู้' : 'ผู้กู้',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isLender
                            ? const Color(0xFF087443)
                            : const Color(0xFF5A4FCF),
                      ),
                    ),
                  ),
                  const Spacer(),
                  _StatusBadge(status: status),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isLender ? 'ผู้กู้' : 'ผู้ให้กู้',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          otherPerson,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF101828),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          agreementId,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '฿${_formatMoney(amount)}',
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF101828),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ครบกำหนด ${_formatDate(returnDate)}',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'ดูรายละเอียด',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF667085),
                    ),
                  ),
                  SizedBox(width: 3),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: Color(0xFF98A2B3),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCreateContractButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: FilledButton.icon(
        onPressed: _openCreateContract,
        icon: const Icon(Icons.add_circle_outline, size: 22),
        label: const Text(
          'สร้างสัญญาใหม่',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF101828),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return NavigationBar(
      selectedIndex: _currentIndex,
      onDestinationSelected: _onBottomNavigationTap,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 8,
      height: 68,
      indicatorColor: const Color(0xFFE9E7FF),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Color(0xFF101828),
          );
        }

        return const TextStyle(fontSize: 11, color: Color(0xFF667085));
      }),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.grid_view_outlined),
          selectedIcon: Icon(Icons.grid_view_rounded),
          label: 'ภาพรวม',
        ),
        NavigationDestination(
          icon: Icon(Icons.description_outlined),
          selectedIcon: Icon(Icons.description_rounded),
          label: 'สัญญา',
        ),
        NavigationDestination(
          icon: Icon(Icons.menu_book_outlined),
          selectedIcon: Icon(Icons.menu_book_rounded),
          label: 'ความรู้',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person_rounded),
          label: 'โปรไฟล์',
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconBackground;
  final Color iconColor;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 142),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE4E7EC)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconBackground,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            style: const TextStyle(fontSize: 12, color: Color(0xFF667085)),
          ),
          const SizedBox(height: 5),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              '฿$value',
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: Color(0xFF101828),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryWideCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  const _SummaryWideCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE4E7EC)),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1EEFF),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: const Color(0xFF5A4FCF), size: 21),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF667085),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF101828),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFF98A2B3)),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String? status;

  const _StatusBadge({required this.status});

  String get label {
    switch (status) {
      case 'active':
        return 'กำลังใช้งาน';
      case 'completed':
        return 'เสร็จสิ้น';
      case 'draft':
        return 'รอลงนาม';
      case 'cancelled':
        return 'ยกเลิก';
      default:
        return 'ไม่ระบุสถานะ';
    }
  }

  Color get backgroundColor {
    switch (status) {
      case 'active':
        return const Color(0xFFE8F7F1);
      case 'completed':
        return const Color(0xFFEFF1F5);
      case 'draft':
        return const Color(0xFFFFF4D6);
      case 'cancelled':
        return const Color(0xFFFEECEC);
      default:
        return const Color(0xFFF2F4F7);
    }
  }

  Color get textColor {
    switch (status) {
      case 'active':
        return const Color(0xFF087443);
      case 'completed':
        return const Color(0xFF475467);
      case 'draft':
        return const Color(0xFFB54708);
      case 'cancelled':
        return const Color(0xFFD92D20);
      default:
        return const Color(0xFF475467);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
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
