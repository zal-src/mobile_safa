import 'package:flutter/material.dart';

import '../models/user.dart';
import '../models/loan_contract.dart';
import '../services/contract_service.dart';
import '../services/pdf_service_printable.dart';
import '../utils/responsive.dart';
import '../widgets/responsive_container.dart';
import 'repayment_page.dart';
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
  // เปิดหน้าการชำระเงิน
  // ============================================================

  Future<void> _openRepaymentPage() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            RepaymentPage(user: widget.user, contract: _contract),
      ),
    );

    // เมื่อกลับจากหน้าชำระเงิน
    // ให้โหลดสถานะสัญญาใหม่ทันที

    if (result == true) {
      await _loadContractData();

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('อัปเดตสถานะสัญญาแล้ว')));
    } else {
      // แม้หน้าชำระเงินไม่ได้ส่ง true กลับมา
      // ก็โหลดข้อมูลใหม่เพื่อให้แน่ใจว่า
      // แสดงสถานะล่าสุดจากฐานข้อมูล

      await _loadContractData();
    }
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
  // ปุ่มการชำระเงิน
  // ============================================================

  Widget _buildRepaymentButton() {
    // ถ้าชำระครบแล้ว
    // ยังสามารถเข้าไปดูประวัติการชำระเงินได้

    if (_contract.status == 'completed') {
      return OutlinedButton.icon(
        onPressed: _openRepaymentPage,
        icon: const Icon(Icons.receipt_long),
        label: const Text('ดูประวัติการชำระเงิน'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          onPressed: _openRepaymentPage,
          icon: const Icon(Icons.payments),
          label: const Text('ดูการชำระเงิน'),
        )
      ],
    );
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
                      // ปุ่มการชำระเงิน
                      // ==================================================
                      _buildRepaymentButton(),

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
