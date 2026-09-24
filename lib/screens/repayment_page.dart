import 'package:flutter/material.dart';

import '../models/user.dart';
import '../models/loan_contract.dart';
import '../models/repayment.dart';
import '../services/repayment_service.dart';
import '../theme/app_theme.dart';

class RepaymentPage extends StatefulWidget {
  final User user;
  final LoanContract contract;

  const RepaymentPage({super.key, required this.user, required this.contract});

  @override
  State<RepaymentPage> createState() => _RepaymentPageState();
}

class _RepaymentPageState extends State<RepaymentPage> {
  final RepaymentService _repaymentService = RepaymentService();

  List<Repayment> _repayments = [];

  bool _isLoading = true;
  bool _isCreatingPlan = false;
  int _installmentCount = 1;

  bool get _isLender => widget.user.userId == widget.contract.lenderId;

  bool get _isBorrower => widget.user.userId == widget.contract.borrowerId;

  double get _totalAmount {
    return _repayments.fold(0, (sum, item) => sum + item.amount);
  }

  double get _paidAmount {
    return _repayments
        .where((item) => item.status == 'paid')
        .fold(0, (sum, item) => sum + item.amount);
  }

  double get _remainingAmount {
    return _totalAmount - _paidAmount;
  }

  int get _paidCount {
    return _repayments.where((item) => item.status == 'paid').length;
  }

  int get _remainingCount {
    return _repayments.where((item) => item.status != 'paid').length;
  }

  bool get _allPaid =>
      _repayments.isNotEmpty &&
      _repayments.every((item) => item.status == 'paid');

  @override
  void initState() {
    super.initState();
    _loadRepayments();
  }

  Future<void> _loadRepayments() async {
    if (widget.contract.contractId == null) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      return;
    }

    try {
      final result = await _repaymentService.getRepayments(
        widget.contract.contractId!,
      );

      if (!mounted) return;

      setState(() {
        _repayments = result;
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
            'โหลดข้อมูลการชำระเงินไม่สำเร็จ: '
            '${e.toString().replaceFirst('Exception: ', '')}',
          ),
        ),
      );
    }
  }

  Future<void> _refresh() async {
    try {
      final result = await _repaymentService.getRepayments(
        widget.contract.contractId!,
      );

      if (!mounted) return;

      setState(() {
        _repayments = result;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  // ============================================================
  // สร้างแผนชำระเงิน
  // ============================================================

  Future<void> _createPlan() async {
    if (!_isLender) {
      _showMessage('เฉพาะผู้ให้กู้เท่านั้นที่สามารถสร้างแผนชำระเงินได้');
      return;
    }

    if (widget.contract.contractId == null) {
      _showMessage('ไม่พบรหัสสัญญา');
      return;
    }

    if (widget.contract.status != 'active') {
      _showMessage('สัญญาต้องมีสถานะ active ก่อนสร้างแผนชำระเงิน');
      return;
    }

    if (_repayments.isNotEmpty) {
      _showMessage('สัญญานี้มีแผนชำระเงินอยู่แล้ว');
      return;
    }

    final userId = widget.user.userId;

    if (userId == null) {
      _showMessage('ไม่พบข้อมูลผู้ใช้');
      return;
    }

    setState(() {
      _isCreatingPlan = true;
    });

    try {
      await _repaymentService.createRepaymentPlan(
        widget.contract,
        userId: userId,
        installmentCount: _installmentCount,
      );

      await _loadRepayments();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('สร้างแผนชำระเงิน $_installmentCount งวดสำเร็จ'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() {
          _isCreatingPlan = false;
        });
      }
    }
  }

  // ============================================================
  // ผู้กู้กดจ่ายแล้ว
  // ============================================================

  Future<void> _markAsPaid(Repayment repayment) async {
    if (!_isBorrower) {
      _showMessage('เฉพาะผู้กู้เท่านั้นที่สามารถบันทึกการชำระเงินได้');
      return;
    }

    if (repayment.repaymentId == null) {
      _showMessage('ไม่พบรหัสรายการชำระเงิน');
      return;
    }

    final userId = widget.user.userId;

    if (userId == null) {
      _showMessage('ไม่พบข้อมูลผู้ใช้');
      return;
    }

    final confirmed = await _showConfirmDialog(
      title: 'ยืนยันการชำระเงิน',
      content:
          'คุณยืนยันว่าชำระเงินจำนวน '
          '${_formatMoney(repayment.amount)} บาท '
          'สำหรับงวดนี้แล้วใช่หรือไม่?',
      confirmText: 'ยืนยันการจ่าย',
    );

    if (!confirmed) {
      return;
    }

    try {
      await _repaymentService.markAsPaid(
        repaymentId: repayment.repaymentId!,
        userId: userId,
      );

      await _loadRepayments();

      if (!mounted) return;

      if (_allPaid) {
        await _showCompletedDialog();
      } else {
        _showMessage(
          'ชำระงวดนี้สำเร็จ '
          'เหลืออีก $_remainingCount งวด',
        );
      }
    } catch (e) {
      if (!mounted) return;

      _showMessage(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  // ============================================================
  // เปลี่ยนกลับเป็นยังไม่ชำระ
  // ============================================================

  Future<void> _markAsPending(Repayment repayment) async {
    if (!_isBorrower) {
      _showMessage('เฉพาะผู้กู้เท่านั้นที่สามารถเปลี่ยนสถานะได้');
      return;
    }

    if (repayment.repaymentId == null) {
      _showMessage('ไม่พบรหัสรายการชำระเงิน');
      return;
    }

    final userId = widget.user.userId;

    if (userId == null) {
      _showMessage('ไม่พบข้อมูลผู้ใช้');
      return;
    }

    final confirmed = await _showConfirmDialog(
      title: 'เปลี่ยนสถานะการชำระเงิน',
      content:
          'ต้องการเปลี่ยนรายการนี้กลับเป็น '
          '"ยังไม่ชำระ" หรือไม่?',
      confirmText: 'ยืนยัน',
    );

    if (!confirmed) {
      return;
    }

    try {
      await _repaymentService.markAsPending(
        repaymentId: repayment.repaymentId!,
        userId: userId,
      );

      await _loadRepayments();

      if (!mounted) return;

      _showMessage('เปลี่ยนสถานะกลับเป็นยังไม่ชำระแล้ว');
    } catch (e) {
      if (!mounted) return;

      _showMessage(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  // ============================================================
  // Dialog ยืนยัน
  // ============================================================

  Future<bool> _showConfirmDialog({
    required String title,
    required String content,
    required String confirmText,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('ยกเลิก'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: Text(confirmText),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  // ============================================================
  // Dialog เมื่อชำระครบ
  // ============================================================

  Future<void> _showCompletedDialog() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.verified, color: Colors.green),
              SizedBox(width: 10),
              Expanded(child: Text('ชำระครบแล้ว')),
            ],
          ),
          content: const Text(
            'คุณชำระเงินครบทุกงวดแล้ว\n\n'
            'สัญญานี้เสร็จสิ้นเรียบร้อยแล้ว',
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('ตกลง'),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // แสดงข้อความ
  // ============================================================

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  // ============================================================
  // Format เงิน
  // ============================================================

  String _formatMoney(double amount) {
    return amount.toStringAsFixed(2);
  }

  // ============================================================
  // สถานะ
  // ============================================================

  String _statusText(String status) {
    switch (status) {
      case 'paid':
        return 'ชำระแล้ว';

      case 'pending':
        return 'ยังไม่ชำระ';

      default:
        return status;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'paid':
        return Colors.green;

      case 'pending':
        return Colors.orange;

      default:
        return Colors.grey;
    }
  }

  // ============================================================
  // Header
  // ============================================================

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AppColors.primarySoft,
        border: Border.all(color: AppColors.primaryBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'การชำระเงิน',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'สัญญา ${widget.contract.agreementId}',
            style: TextStyle(color: Colors.grey.shade700),
          ),
          const SizedBox(height: 12),
          Text(
            'ยอดเงินกู้ ${_formatMoney(widget.contract.amount)} '
            '${widget.contract.currency}',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // Role
  // ============================================================

  Widget _buildRoleCard() {
    String roleText;

    if (_isLender) {
      roleText =
          'บทบาทของคุณ: ผู้ให้กู้\n'
          'คุณสามารถสร้างแผนชำระเงินได้';
    } else if (_isBorrower) {
      roleText =
          'บทบาทของคุณ: ผู้กู้\n'
          'คุณสามารถบันทึกการชำระเงินได้';
    } else {
      roleText = 'คุณไม่มีสิทธิ์จัดการการชำระเงินของสัญญานี้';
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey.shade100,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.person_outline),
          const SizedBox(width: 10),
          Expanded(child: Text(roleText, style: const TextStyle(height: 1.5))),
        ],
      ),
    );
  }

  // ============================================================
  // Summary
  // ============================================================

  Widget _buildSummary() {
    if (_repayments.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'สรุปการชำระเงิน',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                title: 'ยอดทั้งหมด',
                value: '${_formatMoney(_totalAmount)} บาท',
                icon: Icons.account_balance_wallet,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SummaryCard(
                title: 'ชำระแล้ว',
                value: '${_formatMoney(_paidAmount)} บาท',
                icon: Icons.check_circle,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                title: 'คงเหลือ',
                value: '${_formatMoney(_remainingAmount)} บาท',
                icon: Icons.pending,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SummaryCard(
                title: 'งวดที่ชำระ',
                value: '$_paidCount / ${_repayments.length}',
                icon: Icons.list_alt,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ============================================================
  // สร้างแผน
  // ============================================================

  Widget _buildCreatePlanSection() {
    if (!_isLender) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: Colors.grey.shade100,
        ),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.hourglass_empty, color: Colors.orange),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'รอผู้ให้กู้สร้างแผนชำระเงินสำหรับสัญญานี้',
                style: TextStyle(height: 1.5),
              ),
            ),
          ],
        ),
      );
    }

    if (widget.contract.status != 'active') {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: Colors.orange.shade50,
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline, color: Colors.orange),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'สัญญาต้องมีสถานะ active '
                'ก่อนจึงจะสร้างแผนชำระเงินได้',
                style: TextStyle(height: 1.5),
              ),
            ),
          ],
        ),
      );
    }

    if (_repayments.isNotEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primaryBorder),
        color: AppColors.primarySoft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'สร้างแผนชำระเงิน',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text('เลือกจำนวนงวดที่ผู้กู้ต้องชำระ'),
          const SizedBox(height: 14),
          DropdownButtonFormField<int>(
            initialValue: _installmentCount,
            decoration: const InputDecoration(
              labelText: 'จำนวนงวด',
              border: OutlineInputBorder(),
            ),
            items: List.generate(12, (index) => index + 1).map((value) {
              return DropdownMenuItem<int>(
                value: value,
                child: Text('$value งวด'),
              );
            }).toList(),
            onChanged: _isCreatingPlan
                ? null
                : (value) {
                    if (value == null) return;

                    setState(() {
                      _installmentCount = value;
                    });
                  },
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: _isCreatingPlan ? null : _createPlan,
            icon: _isCreatingPlan
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.add),
            label: Text(_isCreatingPlan ? 'กำลังสร้าง...' : 'สร้างแผนชำระเงิน'),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // Repayment Card
  // ============================================================

  Widget _buildRepaymentCard(Repayment repayment, int index) {
    final isPaid = repayment.status == 'paid';
    final color = _statusColor(repayment.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isPaid ? Colors.green.shade200 : Colors.grey.shade300,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: color.withValues(alpha: 0.12),
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(color: color, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'งวดที่ ${index + 1}',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: color.withValues(alpha: 0.10),
                  ),
                  child: Text(
                    _statusText(repayment.status),
                    style: TextStyle(color: color, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),

            const Divider(height: 24),

            _InfoRow(
              icon: Icons.payments_outlined,
              title: 'จำนวนเงิน',
              value: '${_formatMoney(repayment.amount)} บาท',
            ),

            const SizedBox(height: 8),

            _InfoRow(
              icon: Icons.event,
              title: 'กำหนดชำระ',
              value: repayment.dueDate,
            ),

            if (repayment.paidDate != null) ...[
              const SizedBox(height: 8),
              _InfoRow(
                icon: Icons.check_circle_outline,
                title: 'วันที่ชำระ',
                value: _formatDateTime(repayment.paidDate!),
              ),
            ],

            if (repayment.notes != null && repayment.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              _InfoRow(
                icon: Icons.notes,
                title: 'หมายเหตุ',
                value: repayment.notes!,
              ),
            ],

            const SizedBox(height: 14),

            if (_isBorrower && !isPaid)
              FilledButton.icon(
                onPressed: () {
                  _markAsPaid(repayment);
                },
                icon: const Icon(Icons.check_circle),
                label: const Text('จ่ายแล้ว'),
              ),

            if (_isBorrower && isPaid)
              OutlinedButton.icon(
                onPressed: () {
                  _markAsPending(repayment);
                },
                icon: const Icon(Icons.undo),
                label: const Text('เปลี่ยนกลับเป็นยังไม่ชำระ'),
              ),

            if (_isLender)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.grey.shade100,
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, size: 18, color: Colors.grey),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'ผู้ให้กู้สามารถดูสถานะได้ '
                        'แต่ผู้กู้เป็นผู้บันทึกการชำระเงิน',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(String value) {
    try {
      final date = DateTime.parse(value);

      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      final year = date.year.toString();

      final hour = date.hour.toString().padLeft(2, '0');
      final minute = date.minute.toString().padLeft(2, '0');

      return '$day/$month/$year $hour:$minute น.';
    } catch (_) {
      return value;
    }
  }

  // ============================================================
  // Build
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('การชำระเงิน')),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _refresh,
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    _buildHeader(),

                    const SizedBox(height: 14),

                    _buildRoleCard(),

                    const SizedBox(height: 20),

                    if (_allPaid)
                      Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: Colors.green.shade50,
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.verified, color: Colors.green, size: 30),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'ชำระเงินครบทุกงวดแล้ว\n'
                                'สัญญานี้เสร็จสิ้นเรียบร้อยแล้ว',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    if (_repayments.isNotEmpty) ...[
                      _buildSummary(),
                      const SizedBox(height: 20),
                    ],

                    if (_repayments.isEmpty) ...[
                      _buildCreatePlanSection(),
                      const SizedBox(height: 20),
                      if (!_isLender)
                        const Text(
                          'ยังไม่มีรายการชำระเงิน',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                    ],

                    if (_repayments.isNotEmpty) ...[
                      const Text(
                        'รายการชำระเงิน',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),

                      ...List.generate(
                        _repayments.length,
                        (index) =>
                            _buildRepaymentCard(_repayments[index], index),
                      ),
                    ],
                  ],
                ),
              ),
      ),
    );
  }
}

// ============================================================
// Summary Card
// ============================================================

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Info Row
// ============================================================

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 10),
        Text('$title: ', style: TextStyle(color: Colors.grey.shade600)),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
