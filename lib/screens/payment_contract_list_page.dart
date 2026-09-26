import 'package:flutter/material.dart';

import '../models/user.dart';
import '../models/loan_contract.dart';
import '../models/repayment.dart';
import '../services/repayment_service.dart';
import '../services/contract_service.dart';
import '../utils/responsive.dart';
import '../widgets/responsive_container.dart';
import 'repayment_page.dart';
import '../theme/app_theme.dart';

class PaymentContractListPage extends StatefulWidget {
  final User user;

  const PaymentContractListPage({super.key, required this.user});

  @override
  State<PaymentContractListPage> createState() =>
      _PaymentContractListPageState();
}

class _PaymentContractListPageState extends State<PaymentContractListPage> {
  final ContractService _contractService = ContractService();
  final RepaymentService _repaymentService = RepaymentService();

  List<LoanContract> _contracts = [];
  final Map<int, List<Repayment>> _repaymentsByContract = {};

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadContracts();
  }

  Future<void> _loadContracts() async {
    try {
      final userId = widget.user.userId;

      if (userId == null) {
        throw Exception('ไม่พบรหัสผู้ใช้');
      }

      final contracts = await _contractService.getUserContracts(userId);

      final repaymentEntries = await Future.wait(
        contracts
            .where((contract) => contract.contractId != null)
            .map(
              (contract) async => MapEntry(
                contract.contractId!,
                await _repaymentService.getRepayments(contract.contractId!),
              ),
            ),
      );

      if (!mounted) return;

      setState(() {
        _contracts = contracts;
        _repaymentsByContract
          ..clear()
          ..addEntries(repaymentEntries);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  String _getRole(LoanContract contract) {
    if (contract.lenderId == widget.user.userId) {
      return 'ผู้ให้กู้';
    }

    return 'ผู้กู้';
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'draft':
        return 'รอลงชื่อ';

      case 'active':
        return 'กำลังชำระ';

      case 'completed':
        return 'ชำระครบแล้ว';

      case 'cancelled':
        return 'ยกเลิก';

      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return AppColors.primary;

      case 'active':
        return AppColors.primary;

      case 'draft':
        return AppColors.accent;

      case 'cancelled':
        return Colors.red;

      default:
        return Colors.grey;
    }
  }

  Future<void> _openRepayment(LoanContract contract) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            RepaymentPage(user: widget.user, contract: contract),
      ),
    );

    if (!mounted) return;

    await _loadContracts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTheme.buildSafaAppBar(context, title: 'การชำระเงิน'),
      body: ResponsiveBody(
        child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _contracts.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: _loadContracts,
              child: ListView.builder(
                padding: EdgeInsets.all(
                  Responsive.horizontalPadding(context),
                ),
                itemCount: _contracts.length,
                itemBuilder: (context, index) {
                  final contract = _contracts[index];

                  return _buildPaymentCard(contract);
                },
              ),
            ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return RefreshIndicator(
      onRefresh: _loadContracts,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.25),
          const Icon(Icons.payments_outlined, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'ยังไม่มีสัญญา',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'เมื่อมีสัญญาที่เกี่ยวข้อง\n'
            'รายการชำระเงินจะแสดงที่หน้านี้',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentCard(LoanContract contract) {
    final statusColor = _getStatusColor(contract.status);
    final repayments = contract.contractId == null
        ? const <Repayment>[]
        : _repaymentsByContract[contract.contractId!] ?? const <Repayment>[];
    final paidAmount = repayments
        .where((repayment) => repayment.status == 'paid')
        .fold<double>(0, (sum, repayment) => sum + repayment.amount);
    final remainingAmount = repayments
        .where((repayment) => repayment.status != 'paid')
        .fold<double>(0, (sum, repayment) => sum + repayment.amount);
    final nextRepayment = repayments.where((repayment) {
      return repayment.status != 'paid';
    }).firstOrNull;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          _openRepayment(contract);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: AppColors.primarySoft,
                    ),
                    child: const Icon(Icons.payments, color: AppColors.primary),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          contract.agreementId,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'บทบาท: ${_getRole(contract)}',
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
                    child: Text(
                      _getStatusText(contract.status),
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),

              const Divider(height: 24),

              Row(
                children: [
                  Expanded(
                    child: _buildInfo(
                      'จำนวนเงิน',
                      '${contract.amount.toStringAsFixed(2)} บาท',
                    ),
                  ),
                  Expanded(
                    child: _buildInfo(
                      'แผนชำระ',
                      repayments.isEmpty
                          ? 'ยังไม่มีแผน'
                          : '${repayments.length} งวด',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xffd3ebe2)),
                ),
                child: repayments.isEmpty
                    ? const Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 18,
                            color: AppColors.primary,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'ยังไม่มีรายการงวดชำระ กดเพื่อดูรายละเอียดหรือสร้างแผนชำระ',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.payments_outlined,
                                size: 18,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'ชำระแล้ว ${_formatMoney(paidAmount)} บาท',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                'เหลือ ${_formatMoney(remainingAmount)} บาท',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xff176b5b),
                                ),
                              ),
                            ],
                          ),
                          if (nextRepayment != null) ...[
                            const SizedBox(height: 7),
                            Text(
                              'งวดถัดไป: ${_formatMoney(nextRepayment.amount)} บาท  |  ครบกำหนด ${nextRepayment.dueDate}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xff5e6b78),
                              ),
                            ),
                          ],
                        ],
                      ),
              ),

              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    _openRepayment(contract);
                  },
                  icon: const Icon(Icons.arrow_forward),
                  label: Text(
                    contract.status == 'completed'
                        ? 'ดูประวัติการชำระเงิน'
                        : 'ดูการชำระเงิน',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfo(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }

  String _formatMoney(double amount) {
    return amount.toStringAsFixed(2);
  }
}
