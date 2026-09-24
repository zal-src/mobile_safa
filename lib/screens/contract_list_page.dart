import 'package:flutter/material.dart';

import '../models/user.dart';
import '../models/loan_contract.dart';
import '../services/contract_service.dart';
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

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    _loadContracts();
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

      if (!mounted) return;

      setState(() {
        _contracts = contracts;
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
    switch (contract.status) {
      case 'draft':
        return 'รอลงลายมือชื่อ';

      case 'active':
        return 'มีผลแล้ว';

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
    switch (contract.status) {
      case 'draft':
        return AppColors.accent;

      case 'active':
        return AppColors.primary;

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
    switch (contract.status) {
      case 'draft':
        return Icons.pending_actions;

      case 'active':
        return Icons.verified;

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

  Widget _buildContractCard(LoanContract contract) {
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

                        Text(
                          'บทบาท: $role',
                          style: TextStyle(color: Colors.grey.shade600),
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
      appBar: AppBar(title: const Text('สัญญาของฉัน')),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateContract,
        icon: const Icon(Icons.add),
        label: const Text('เพิ่มสัญญา'),
      ),

      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadContracts,
                child: _contracts.isEmpty
                    ? LayoutBuilder(
                        builder: (context, constraints) {
                          return SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: SizedBox(
                              height: constraints.maxHeight,
                              child: _buildEmptyState(),
                            ),
                          );
                        },
                      )
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                        itemCount: _contracts.length,
                        itemBuilder: (context, index) {
                          return _buildContractCard(_contracts[index]);
                        },
                      ),
              ),
      ),
    );
  }
}
