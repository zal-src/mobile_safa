import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../models/user.dart';
import '../models/loan_contract.dart';
import '../services/auth_service.dart';
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
  final AuthService _authService = AuthService();
  final DatabaseHelper _database = DatabaseHelper.instance;

  late User _currentUser;
  Map<String, dynamic>? _currentAddress;

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
    _currentUser = widget.user;
    _loadUserProfile();
    _loadContracts();
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
        if (_selectedFilter == 'เกินกำหนด' && status == 'เกินกำหนด')
          return true;
        if (_selectedFilter == 'เสร็จสิ้น' && status == 'ชำระครบแล้ว')
          return true;
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
      if (pA != pB)
        return pB.compareTo(
          pA,
        ); // เรียงจากมากไปน้อย (เกินกำหนด/มีผลแล้ว ขึ้นก่อน)

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
                MaterialPageRoute(builder: (context) => const AiChatPage()),
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
