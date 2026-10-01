import 'package:flutter/material.dart';

import '../models/user.dart';
import '../models/loan_contract.dart';
import '../services/contract_service.dart';
import '../services/pdf_service_printable.dart';
import '../utils/responsive.dart';
import '../widgets/responsive_container.dart';
import '../theme/app_theme.dart';

class ContractDetailPage extends StatefulWidget {
  final User user;
  final LoanContract contract;

  const ContractDetailPage({
    super.key,
    required this.user,
    required this.contract,
  });

  @override
  State<ContractDetailPage> createState() => _ContractDetailPageState();
}

class _ContractDetailPageState extends State<ContractDetailPage> {
  final ContractService _contractService = ContractService();

  final PrintablePdfService _printablePdfService = PrintablePdfService();

  bool _isPrinting = false;

  late LoanContract _contract;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    _contract = widget.contract;

    _loadContractData();
  }

  // ============================================================
  // โหลดข้อมูลสัญญาล่าสุด
  // ============================================================

  Future<void> _loadContractData() async {
    final contractId = widget.contract.contractId;

    if (contractId == null) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      return;
    }

    try {
      final contract = await _contractService.getContract(contractId);

      if (!mounted) return;

      setState(() {
        if (contract != null) {
          _contract = contract;
        }

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
            'โหลดข้อมูลสัญญาไม่สำเร็จ: '
            '${e.toString().replaceFirst('Exception: ', '')}',
          ),
        ),
      );
    }
  }

  // ============================================================
  // สร้างและเปิดหน้า PDF
  // ============================================================

  Future<void> _printPdf() async {
    if (_isPrinting) {
      return;
    }

    setState(() {
      _isPrinting = true;
    });

    try {
      await _printablePdfService.printContract(_contract);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'สร้าง PDF ไม่สำเร็จ: '
            '${e.toString().replaceFirst('Exception: ', '')}',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isPrinting = false;
        });
      }
    }
  }

  // ============================================================
  // แสดงข้อความสถานะ
  // ============================================================

  String _statusText() {
    if (_contract.status == 'completed') {
      return 'ชำระเงินครบแล้ว';
    }
    if (_contract.status == 'active') {
      final returnDate = DateTime.tryParse(_contract.returnDate);
      if (returnDate != null) {
        final today = DateTime.now();
        final returnDateOnly = DateTime(returnDate.year, returnDate.month, returnDate.day);
        final todayOnly = DateTime(today.year, today.month, today.day);
        if (todayOnly.isAfter(returnDateOnly)) {
          return 'เกินกำหนด';
        }
      }
      return 'พร้อมพิมพ์และจัดการต่อ';
    }
    return 'สถานะสัญญา: ${_contract.status}';
  }

  // ============================================================
  // สีสถานะ
  // ============================================================

  Color _statusColor() {
    if (_contract.status == 'completed') {
      return Colors.green;
    }
    if (_contract.status == 'active') {
      final returnDate = DateTime.tryParse(_contract.returnDate);
      if (returnDate != null) {
        final today = DateTime.now();
        final returnDateOnly = DateTime(returnDate.year, returnDate.month, returnDate.day);
        final todayOnly = DateTime(today.year, today.month, today.day);
        if (todayOnly.isAfter(returnDateOnly)) {
          return Colors.red;
        }
      }
    }
    return AppColors.primary;
  }

  // ============================================================
  // ไอคอนสถานะ
  // ============================================================

  IconData _statusIcon() {
    if (_contract.status == 'completed') {
      return Icons.task_alt;
    }
    if (_contract.status == 'active') {
      final returnDate = DateTime.tryParse(_contract.returnDate);
      if (returnDate != null) {
        final today = DateTime.now();
        final returnDateOnly = DateTime(returnDate.year, returnDate.month, returnDate.day);
        final todayOnly = DateTime(today.year, today.month, today.day);
        if (todayOnly.isAfter(returnDateOnly)) {
          return Icons.warning_amber_rounded;
        }
      }
      return Icons.description_outlined;
    }
    return Icons.description_outlined;
  }

  // ============================================================
  // กล่องข้อมูล
  // ============================================================

  Widget _buildInfoCard({
    required String title,
    required String value,
    IconData? icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, color: Colors.grey.shade700),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
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
  // กล่องสถานะสัญญา
  // ============================================================

  Widget _buildStatusCard() {
    final statusColor = _statusColor();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: statusColor.withValues(alpha: 0.08),
        border: Border.all(color: statusColor.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          Icon(_statusIcon(), size: 42, color: statusColor),

          const SizedBox(height: 10),

          Text(
            _statusText(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: statusColor,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            'สถานะในฐานข้อมูล: '
            '${_contract.status}',
            style: TextStyle(color: Colors.grey.shade700),
          ),

          const SizedBox(height: 4),

          if (_contract.status == 'completed')
            const Text(
              'ชำระเงินครบทุกงวดแล้ว',
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            )
        ],
      ),
    );
  }

  // ============================================================
  // บันทึกช่วยจำการชำระเงิน (งวด)
  // ============================================================

  Future<void> _updateInstallments(int newValue) async {
    final contractId = _contract.contractId;
    if (contractId == null) return;
    try {
      await _contractService.updatePaidInstallments(contractId, newValue);
      await _loadContractData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
      );
    }
  }

  int _calculateTotalInstallments() {
    final loanDate = DateTime.tryParse(_contract.loanDate);
    final returnDate = DateTime.tryParse(_contract.returnDate);
    if (loanDate == null || returnDate == null) return 1;

    int months = (returnDate.year - loanDate.year) * 12 + returnDate.month - loanDate.month;
    if (returnDate.day < loanDate.day) {
      months--;
    }
    return months > 0 ? months : 1;
  }

  Widget _buildInstallmentTracker() {
    if (_contract.repaymentType != 'รายเดือน' || _contract.status == 'completed') {
      return const SizedBox.shrink();
    }

    final isLender = _contract.lenderId == widget.user.userId;
    final title = isLender ? 'เช็คยอดรับชำระแล้ว (เตือนความจำ)' : 'เช็คยอดชำระแล้ว (เตือนความจำ)';

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle_outline, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            '* แตะที่งวดเพื่อทำเครื่องหมายว่าชำระแล้ว',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _calculateTotalInstallments(),
            itemBuilder: (context, index) {
              final installmentNum = index + 1;
              final isPaid = installmentNum <= _contract.paidInstallments;

              return InkWell(
                onTap: () {
                  if (isPaid) {
                    _updateInstallments(index); // ยกเลิกอันนี้และอันถัดๆ ไป
                  } else {
                    _updateInstallments(installmentNum); // เลือกอันนี้และก่อนหน้า
                  }
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isPaid ? Icons.check_circle : Icons.circle_outlined,
                        color: isPaid ? AppColors.primary : Colors.grey,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'งวดที่ $installmentNum',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: isPaid ? FontWeight.bold : FontWeight.normal,
                          color: isPaid ? Colors.black : Colors.grey.shade700,
                        ),
                      ),
                      const Spacer(),
                      if (isPaid)
                        const Text(
                          'ชำระแล้ว',
                          style: TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          const Center(
            child: Text(
              '* ข้อมูลนี้บันทึกไว้ในเครื่องของคุณเท่านั้น สำหรับช่วยเตือนความจำส่วนตัว',
              style: TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          )
        ],
      ),
    );
  }

  // ============================================================
  // ปุ่มการชำระเงิน
  // ============================================================
  
  Future<void> _markAsCompleted() async {
    final contractId = _contract.contractId;
    if (contractId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยืนยันการชำระครบแล้ว'),
        content: const Text('คุณแน่ใจหรือไม่ว่าสัญญาฉบับนี้มีการชำระเงินครบถ้วนแล้ว?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('ยืนยัน'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _contractService.markContractAsCompleted(contractId);
      await _loadContractData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('เปลี่ยนสถานะสัญญาเป็นชำระครบแล้ว')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
      );
    }
  }

  Widget _buildCompletionButton() {
    if (_contract.status == 'active') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton.icon(
            onPressed: _markAsCompleted,
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('เสร็จสิ้น (จ่ายครบแล้ว)'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.green,
            ),
          ),
        ],
      );
    }
    return const SizedBox.shrink();
  }

  // ============================================================
  // หน้าหลัก
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final contract = _contract;

    final isLender = contract.lenderId == widget.user.userId;

    return Scaffold(
      appBar: AppTheme.buildSafaAppBar(context, title: 'รายละเอียดสัญญา'),

      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ResponsiveBody(
                child: RefreshIndicator(
                onRefresh: _loadContractData,

                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),

                  padding: EdgeInsets.symmetric(
                    horizontal: Responsive.horizontalPadding(context),
                    vertical: 20,
                  ),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,

                    children: [
                      // ==================================================
                      // เลขที่สัญญา
                      // ==================================================
                      Text(
                        contract.agreementId,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 6),

                      // ==================================================
                      // บทบาทของผู้ใช้
                      // ==================================================
                      Text(
                        isLender
                            ? 'บทบาทของคุณ: ผู้ให้กู้'
                            : 'บทบาทของคุณ: ผู้กู้',
                        style: TextStyle(color: Colors.grey.shade700),
                      ),

                      const SizedBox(height: 20),

                      // ==================================================
                      // สถานะสัญญา
                      // ==================================================
                      _buildStatusCard(),

                      const SizedBox(height: 20),

                      // ==================================================
                      // ข้อมูลสัญญา
                      // ==================================================
                      const Text(
                        'ข้อมูลสัญญา',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 12),

                      _buildInfoCard(
                        title: 'เลขที่สัญญา',
                        value: contract.agreementId,
                        icon: Icons.tag,
                      ),

                      _buildInfoCard(
                        title: 'จำนวนเงิน',
                        value:
                            '${contract.amount.toStringAsFixed(2)} '
                            '${contract.currency}',
                        icon: Icons.payments_outlined,
                      ),

                      _buildInfoCard(
                        title: 'อัตราดอกเบี้ย',
                        value: '${contract.interestRate.toStringAsFixed(2)}%',
                        icon: Icons.percent,
                      ),

                      _buildInfoCard(
                        title: 'ประเภทการชำระเงิน',
                        value: contract.repaymentType,
                        icon: Icons.calendar_month,
                      ),

                      _buildInfoCard(
                        title: 'วันให้กู้',
                        value: contract.loanDate,
                        icon: Icons.event,
                      ),

                      _buildInfoCard(
                        title: 'วันคืนเงิน',
                        value: contract.returnDate,
                        icon: Icons.event_available,
                      ),

                      if (contract.purpose != null &&
                          contract.purpose!.isNotEmpty)
                        _buildInfoCard(
                          title: 'วัตถุประสงค์',
                          value: contract.purpose!,
                          icon: Icons.description_outlined,
                        ),

                      if (contract.notes != null && contract.notes!.isNotEmpty)
                        _buildInfoCard(
                          title: 'หมายเหตุ',
                          value: contract.notes!,
                          icon: Icons.notes,
                        ),

                      const SizedBox(height: 10),

                      // ==================================================
                      // เช็คยอดชำระเงิน (งวด)
                      // ==================================================
                      _buildInstallmentTracker(),

                      // ==================================================
                      // ปุ่มการชำระเงิน (ตอนนี้เป็นแค่ปุ่มปิดสัญญา)
                      // ==================================================
                      _buildCompletionButton(),

                      const SizedBox(height: 10),

                      // ==================================================
                      // ปุ่ม PDF
                      // ==================================================
                      OutlinedButton.icon(
                        onPressed: _isPrinting ? null : _printPdf,

                        icon: _isPrinting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.picture_as_pdf),

                        label: Text(
                          _isPrinting ? 'กำลังสร้าง PDF...' : 'พิมพ์ / PDF',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              ),
      ),
    );
  }
}
