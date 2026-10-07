import 'package:flutter/material.dart';


import '../models/user.dart';
import '../models/loan_contract.dart';

import '../services/contract_service.dart';
import '../services/onboarding_service.dart';
import '../utils/responsive.dart';
import '../widgets/responsive_container.dart';
import '../widgets/onboarding_bottom_sheet.dart';
import 'ai_chat_page.dart';
import 'contract_detail_page.dart';
import 'contract_role_page.dart';

import '../theme/app_theme.dart';

class ContractListPage extends StatefulWidget {
  final User user;

  const ContractListPage({super.key, required this.user});

  @override
  State<ContractListPage> createState() => _ContractListPageState();
}

class _ContractListPageState extends State<ContractListPage> {
  final ContractService _contractService = ContractService();

  List<LoanContract> _contracts = [];
  String? _latestAgreementId;

  String _selectedFilter = 'ทั้งหมด';

  bool _isLoading = true;

  // GlobalKeys สำหรับ spotlight
  final _keyContractList = GlobalKey();
  final _keyFab = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadContracts();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeShowOnboarding();
    });
  }



  Future<void> _maybeShowOnboarding() async {
    final seen = await OnboardingService.instance.hasSeenOnboarding(
      OnboardingService.keyContracts,
    );
    if (!mounted || seen) return;
    await OnboardingService.instance.markAsSeen(OnboardingService.keyContracts);
    if (!mounted) return;

    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    await SpotlightTutorial.show(
      context,
      steps: [
        TutorialStep(
          title: 'รายการสัญญาของคุณ',
          description:
              'ที่นี่คุณจะเห็นสัญญา Qard Hasan ทั้งหมด\nแตะที่สัญญาเพื่อดูสถานะ (รอลงนาม / มีผล / ครบกำหนด)',
          targetKey: _keyContractList,
          spotlightPadding: const EdgeInsets.all(8),
        ),
        TutorialStep(
          title: 'เพิ่มสัญญาใหม่',
          description:
              'กดปุ่ม "+" เพื่อสร้างสัญญาใหม่\nระบบจะพาคุณกรอกรายละเอียดทีละขั้นตอนอย่างง่ายดาย',
          targetKey: _keyFab,
          spotlightPadding: const EdgeInsets.all(4),
          spotlightRadius: 32,
        ),
      ],
    );
  }

  // ============================================================
  // โหลดสัญญาของผู้ใช้
  // ============================================================

  Future<void> _loadContracts() async {
    if (widget.user.userId == null) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      return;
    }

    try {
      final contracts = await _contractService.getUserContracts(
        widget.user.userId!,
      );

      String? latestId;
      if (contracts.isNotEmpty) {
        final sortedByDate = List<LoanContract>.from(contracts)
          ..sort((a, b) {
            final dateA =
                DateTime.tryParse(a.createdAt ?? '') ?? DateTime(2000);
            final dateB =
                DateTime.tryParse(b.createdAt ?? '') ?? DateTime(2000);
            return dateB.compareTo(dateA);
          });
        latestId = sortedByDate.first.agreementId;
      }

      if (!mounted) return;

      setState(() {
        _contracts = contracts;
        _latestAgreementId = latestId;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'โหลดสัญญาไม่สำเร็จ: '
            '${e.toString().replaceFirst('Exception: ', '')}',
          ),
        ),
      );
    }
  }

  // ============================================================
  // กรองสัญญา
  // ============================================================

  List<LoanContract> get _filteredContracts {
    List<LoanContract> filtered;
    if (_selectedFilter == 'ทั้งหมด') {
      filtered = List.from(_contracts);
    } else {
      filtered = _contracts.where((contract) {
        final status = _statusText(contract);
        if (_selectedFilter == 'มีผลแล้ว' && status == 'มีผลแล้ว') return true;
        if (_selectedFilter == 'เกินกำหนด' && status == 'เกินกำหนด') {
          return true;
        }
        if (_selectedFilter == 'เสร็จสิ้น' && status == 'ชำระครบแล้ว') {
          return true;
        }
        return false;
      }).toList();
    }

    int getPriority(LoanContract c) {
      final text = _statusText(c);
      if (text == 'เกินกำหนด') return 4;
      if (text == 'มีผลแล้ว') return 3; // ต้องชำระ
      if (text == 'รอลงลายมือชื่อ') return 2;
      if (text == 'ชำระครบแล้ว') return 1;
      return 0;
    }

    filtered.sort((a, b) {
      final pA = getPriority(a);
      final pB = getPriority(b);
      if (pA != pB) {
        return pB.compareTo(
          pA,
        ); // เรียงจากมากไปน้อย (เกินกำหนด/มีผลแล้ว ขึ้นก่อน)
      }

      final dateA = DateTime.tryParse(a.createdAt ?? '') ?? DateTime(2000);
      final dateB = DateTime.tryParse(b.createdAt ?? '') ?? DateTime(2000);
      return dateB.compareTo(
        dateA,
      ); // ถ้า priority เท่ากัน เรียงตามวันที่ล่าสุด
    });

    return filtered;
  }

  // ============================================================
  // เปิดหน้าสร้างสัญญา
  // ============================================================

  Future<void> _openCreateContract() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ContractRolePage(user: widget.user),
      ),
    );

    if (result == true) {
      await _loadContracts();
    }
  }

  // ============================================================
  // เปิดรายละเอียดสัญญา
  // ============================================================

  Future<void> _openContractDetail(LoanContract contract) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ContractDetailPage(user: widget.user, contract: contract),
      ),
    );

    if (result == true) {
      await _loadContracts();
    } else {
      // โหลดใหม่ทุกครั้งที่กลับจากหน้ารายละเอียด
      // เพื่อให้สถานะล่าสุดแสดงทันที
      await _loadContracts();
    }
  }

  // ============================================================
  // แสดงข้อความสถานะ
  // ============================================================

  String _statusText(LoanContract contract) {
    if (contract.status == 'active') {
      final returnDate = DateTime.tryParse(contract.returnDate);
      if (returnDate != null) {
        final today = DateTime.now();
        final returnDateOnly = DateTime(
          returnDate.year,
          returnDate.month,
          returnDate.day,
        );
        final todayOnly = DateTime(today.year, today.month, today.day);
        if (todayOnly.isAfter(returnDateOnly)) {
          return 'เกินกำหนด';
        }
      }
      return 'มีผลแล้ว';
    }

    switch (contract.status) {
      case 'draft':
        return 'รอลงลายมือชื่อ';
      case 'completed':
        return 'ชำระครบแล้ว';
      default:
        return contract.status;
    }
  }

  // ============================================================
  // สีสถานะ
  // ============================================================

  Color _statusColor(LoanContract contract) {
    if (contract.status == 'active') {
      final returnDate = DateTime.tryParse(contract.returnDate);
      if (returnDate != null) {
        final today = DateTime.now();
        final returnDateOnly = DateTime(
          returnDate.year,
          returnDate.month,
          returnDate.day,
        );
        final todayOnly = DateTime(today.year, today.month, today.day);
        if (todayOnly.isAfter(returnDateOnly)) {
          return Colors.red;
        }
      }
      return AppColors.primary;
    }

    switch (contract.status) {
      case 'draft':
        return AppColors.accent;
      case 'completed':
        return AppColors.primary;
      default:
        return Colors.grey;
    }
  }

  // ============================================================
  // ไอคอนสถานะ
  // ============================================================

  IconData _statusIcon(LoanContract contract) {
    if (contract.status == 'active') {
      final returnDate = DateTime.tryParse(contract.returnDate);
      if (returnDate != null) {
        final today = DateTime.now();
        final returnDateOnly = DateTime(
          returnDate.year,
          returnDate.month,
          returnDate.day,
        );
        final todayOnly = DateTime(today.year, today.month, today.day);
        if (todayOnly.isAfter(returnDateOnly)) {
          return Icons.warning_amber_rounded;
        }
      }
      return Icons.verified;
    }

    switch (contract.status) {
      case 'draft':
        return Icons.pending_actions;
      case 'completed':
        return Icons.task_alt;
      default:
        return Icons.info_outline;
    }
  }

  // ============================================================
  // แสดงบทบาทของผู้ใช้
  // ============================================================

  String _roleText(LoanContract contract) {
    if (contract.lenderId == widget.user.userId) {
      return 'ผู้ให้กู้';
    }

    if (contract.borrowerId == widget.user.userId) {
      return 'ผู้กู้';
    }

    return '-';
  }

  // ============================================================
  // Card ของสัญญา
  // ============================================================

  Widget _buildContractCard(LoanContract contract, {bool isLatest = false}) {
    final statusColor = _statusColor(contract);

    final role = _roleText(contract);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          _openContractDetail(contract);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ==================================================
              // Header
              // ==================================================
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: AppColors.primarySoft,
                    ),
                    child: const Icon(
                      Icons.description_outlined,
                      color: AppColors.primary,
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          contract.agreementId,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Row(
                          children: [
                            Text(
                              'บทบาท: $role',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                            if (isLatest) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'ล่าสุด',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                            if (contract.status == 'active') ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade700,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'ต้องชำระ',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
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
                      borderRadius: BorderRadius.circular(20),
                      color: statusColor.withValues(alpha: 0.10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _statusIcon(contract),
                          size: 16,
                          color: statusColor,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          _statusText(contract),
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ==================================================
              // จำนวนเงิน
              // ==================================================
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey.shade50,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.account_balance_wallet_outlined,
                      color: Colors.grey.shade700,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'จำนวนเงิน',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${contract.amount.toStringAsFixed(2)} '
                            '${contract.currency}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // ==================================================
              // วันที่
              // ==================================================
              Row(
                children: [
                  Expanded(
                    child: _buildDateInfo(
                      icon: Icons.event,
                      title: 'วันให้กู้',
                      value: contract.loanDate,
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: _buildDateInfo(
                      icon: Icons.event_available,
                      title: 'วันคืนเงิน',
                      value: contract.returnDate,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // ==================================================
              // ประเภทการชำระเงิน
              // ==================================================
              Row(
                children: [
                  Icon(
                    Icons.calendar_month,
                    size: 18,
                    color: Colors.grey.shade600,
                  ),

                  const SizedBox(width: 8),

                  Text(
                    contract.repaymentType,
                    style: TextStyle(color: Colors.grey.shade700),
                  ),

                  const Spacer(),

                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ข้อมูลวันที่
  // ============================================================

  Widget _buildDateInfo({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // หน้าจอไม่มีสัญญา
  // ============================================================

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primarySoft,
              ),
              child: const Icon(
                Icons.description_outlined,
                size: 46,
                color: AppColors.primary,
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'ยังไม่มีสัญญา',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            Text(
              'คุณยังไม่มีสัญญากู้ยืมในระบบ',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),

            const SizedBox(height: 24),

            ElevatedButton.icon(
              onPressed: _openCreateContract,
              icon: const Icon(Icons.add),
              label: const Text('สร้างสัญญา'),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // Build
  // ============================================================


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.page,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: const Color(0xFFE4E7EC), height: 1.0),
        ),
        title: const Text('สัญญาของฉัน'),
        actions: [
          IconButton(
            tooltip: 'ค้นหาด้วย AI',
            icon: const Icon(Icons.search, color: Colors.black87),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AiChatPage(user: widget.user)),
              );
            },
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        key: _keyFab,
        onPressed: _openCreateContract,
        icon: const Icon(Icons.add),
        label: const Text('เพิ่มสัญญา'),
      ),

      body: SafeArea(
        child: ResponsiveBody(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  key: _keyContractList,
                  onRefresh: _loadContracts,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ตัวกรองสถานะ
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: EdgeInsets.symmetric(
                          horizontal: Responsive.horizontalPadding(context),
                          vertical: 12,
                        ),
                        child: Row(
                          children:
                              [
                                'ทั้งหมด',
                                'มีผลแล้ว',
                                'เกินกำหนด',
                                'เสร็จสิ้น',
                              ].map((filter) {
                                final isSelected = _selectedFilter == filter;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: ChoiceChip(
                                    label: Text(filter),
                                    selected: isSelected,
                                    onSelected: (selected) {
                                      if (selected) {
                                        setState(
                                          () => _selectedFilter = filter,
                                        );
                                      }
                                    },
                                    selectedColor: AppColors.primary,
                                    labelStyle: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.black87,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                );
                              }).toList(),
                        ),
                      ),

                      // รายการสัญญา
                      Expanded(
                        child: _filteredContracts.isEmpty
                            ? LayoutBuilder(
                                builder: (context, constraints) {
                                  return SingleChildScrollView(
                                    physics:
                                        const AlwaysScrollableScrollPhysics(),
                                    child: SizedBox(
                                      height: constraints.maxHeight,
                                      child: _buildEmptyState(),
                                    ),
                                  );
                                },
                              )
                            : ListView.builder(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: EdgeInsets.fromLTRB(
                                  Responsive.horizontalPadding(context),
                                  4,
                                  Responsive.horizontalPadding(context),
                                  100,
                                ),
                                itemCount: _filteredContracts.length,
                                itemBuilder: (context, index) {
                                  return _buildContractCard(
                                    _filteredContracts[index],
                                    isLatest:
                                        _filteredContracts[index].agreementId ==
                                        _latestAgreementId,
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
