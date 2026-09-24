import '../database/database_helper.dart';
import '../models/loan_contract.dart';
import '../models/repayment.dart';

class RepaymentService {
  final DatabaseHelper _database = DatabaseHelper.instance;

  // ============================================================
  // ดึงรายการชำระเงินของสัญญา
  // ============================================================

  Future<List<Repayment>> getRepayments(int contractId) async {
    final result = await _database.getContractRepayments(contractId);

    return result
        .map((map) => Repayment.fromMap(map))
        .toList();
  }

  // ============================================================
  // สร้างรายการชำระเงิน 1 งวด
  // ============================================================

  Future<void> createRepayment({
    required int contractId,
    required double amount,
    required String dueDate,
    String? notes,
  }) async {
    if (amount <= 0) {
      throw Exception('จำนวนเงินต้องมากกว่า 0');
    }

    await _database.insertRepayment({
      'contract_id': contractId,
      'amount': double.parse(amount.toStringAsFixed(2)),
      'due_date': dueDate,
      'paid_date': null,
      'status': 'pending',
      'notes': notes,
    });
  }

  // ============================================================
  // สร้างแผนชำระเงิน
  // เฉพาะผู้ให้กู้เท่านั้น
  // ============================================================

  Future<void> createRepaymentPlan(
    LoanContract contract, {
    required int userId,
    int installmentCount = 1,
  }) async {
    if (contract.contractId == null) {
      throw Exception('ไม่พบรหัสสัญญา');
    }

    if (userId != contract.lenderId) {
      throw Exception(
        'เฉพาะผู้ให้กู้เท่านั้นที่สามารถสร้างแผนชำระเงินได้',
      );
    }

    if (contract.status != 'active') {
      throw Exception(
        'สัญญายังไม่มีผล หรือสัญญาสิ้นสุดแล้ว',
      );
    }

    if (installmentCount <= 0) {
      throw Exception('จำนวนงวดต้องมากกว่า 0');
    }

    final existing =
        await getRepayments(contract.contractId!);

    if (existing.isNotEmpty) {
      throw Exception(
        'สัญญานี้มีแผนชำระเงินอยู่แล้ว',
      );
    }

    final loanDate = DateTime.parse(contract.loanDate);
    final returnDate = DateTime.parse(contract.returnDate);

    final totalDays =
        returnDate.difference(loanDate).inDays;

    if (totalDays <= 0) {
      throw Exception(
        'วันคืนเงินต้องหลังวันให้กู้',
      );
    }

    // ----------------------------------------------------------
    // คำนวณยอดเป็น "สตางค์" เพื่อป้องกันปัญหา floating point
    // ----------------------------------------------------------

    final totalCents =
        (contract.amount * 100).round();

    if (totalCents <= 0) {
      throw Exception(
        'จำนวนเงินในสัญญาไม่ถูกต้อง',
      );
    }

    final baseCents =
        totalCents ~/ installmentCount;

    final remainderCents =
        totalCents % installmentCount;

    int accumulatedCents = 0;

    for (int i = 1; i <= installmentCount; i++) {
      final dueDate = _calculateDueDate(
        loanDate: loanDate,
        returnDate: returnDate,
        installmentNumber: i,
        installmentCount: installmentCount,
      );

      // งวดสุดท้ายรับเศษทั้งหมด
      final installmentCents = i == installmentCount
          ? totalCents - accumulatedCents
          : baseCents + (i <= remainderCents ? 1 : 0);

      accumulatedCents += installmentCents;

      final amount =
          installmentCents / 100.0;

      await createRepayment(
        contractId: contract.contractId!,
        amount: amount,
        dueDate: _formatDate(dueDate),
        notes:
            'งวดที่ $i/$installmentCount ของสัญญา ${contract.agreementId}',
      );
    }
  }

  // ============================================================
  // บันทึกการชำระเงิน
  // เฉพาะผู้กู้เท่านั้น
  // ============================================================

  Future<void> markAsPaid({
    required int repaymentId,
    required int userId,
    String? notes,
  }) async {
    final repayment =
        await _database.getRepaymentById(repaymentId);

    if (repayment == null) {
      throw Exception('ไม่พบรายการชำระเงิน');
    }

    final contractId =
        repayment['contract_id'] as int;

    final contract =
        await _database.getContractById(contractId);

    if (contract == null) {
      throw Exception('ไม่พบสัญญา');
    }

    final borrowerId =
        contract['borrower_id'] as int;

    if (userId != borrowerId) {
      throw Exception(
        'เฉพาะผู้กู้เท่านั้นที่สามารถบันทึกการชำระเงินได้',
      );
    }

    final currentStatus =
        repayment['status'] as String? ?? 'pending';

    if (currentStatus == 'paid') {
      throw Exception(
        'รายการนี้ถูกบันทึกว่าชำระแล้ว',
      );
    }

    await _database.updateRepaymentStatus(
      repaymentId,
      status: 'paid',
      paidDate: DateTime.now().toIso8601String(),
      notes: notes ?? repayment['notes'] as String?,
    );

    // ตรวจว่าชำระครบทุกงวดแล้วหรือไม่
    await _updateContractCompletionStatus(
      contractId,
    );
  }

  // ============================================================
  // เปลี่ยนสถานะกลับเป็นยังไม่ชำระ
  // เฉพาะผู้กู้เท่านั้น
  // ============================================================

  Future<void> markAsPending({
    required int repaymentId,
    required int userId,
  }) async {
    final repayment =
        await _database.getRepaymentById(repaymentId);

    if (repayment == null) {
      throw Exception('ไม่พบรายการชำระเงิน');
    }

    final contractId =
        repayment['contract_id'] as int;

    final contract =
        await _database.getContractById(contractId);

    if (contract == null) {
      throw Exception('ไม่พบสัญญา');
    }

    final borrowerId =
        contract['borrower_id'] as int;

    if (userId != borrowerId) {
      throw Exception(
        'เฉพาะผู้กู้เท่านั้นที่สามารถเปลี่ยนสถานะการชำระเงินได้',
      );
    }

    await _database.updateRepaymentStatus(
      repaymentId,
      status: 'pending',
      paidDate: null,
      notes: repayment['notes'] as String?,
    );

    // ถ้าสัญญาเคย completed แล้ว
    // การเปลี่ยนกลับเป็น pending ทำให้สัญญากลับเป็น active
    if (contract['status'] == 'completed') {
      await _database.updateContractStatus(
        contractId,
        'active',
      );
    }
  }

  // ============================================================
  // ตรวจสอบและสร้างแผนชำระเงินถ้ายังไม่มี
  // ============================================================

  Future<void> ensureRepaymentPlan(
    LoanContract contract, {
    required int userId,
    int installmentCount = 1,
  }) async {
    if (contract.contractId == null) {
      throw Exception('ไม่พบรหัสสัญญา');
    }

    if (contract.status != 'active') {
      return;
    }

    final hasRepayment =
        await _database.hasRepayments(
      contract.contractId!,
    );

    if (hasRepayment) {
      return;
    }

    await createRepaymentPlan(
      contract,
      userId: userId,
      installmentCount: installmentCount,
    );
  }

  // ============================================================
  // ตรวจสอบว่าชำระครบทุกงวดหรือยัง
  // ============================================================

  Future<void> _updateContractCompletionStatus(
    int contractId,
  ) async {
    final repayments =
        await _database.getContractRepayments(
      contractId,
    );

    if (repayments.isEmpty) {
      return;
    }

    final allPaid = repayments.every(
      (repayment) =>
          (repayment['status'] as String? ?? 'pending') ==
          'paid',
    );

    if (allPaid) {
      await _database.updateContractStatus(
        contractId,
        'completed',
      );
    } else {
      await _database.updateContractStatus(
        contractId,
        'active',
      );
    }
  }

  // ============================================================
  // คำนวณวันครบกำหนดของแต่ละงวด
  // ============================================================

  DateTime _calculateDueDate({
    required DateTime loanDate,
    required DateTime returnDate,
    required int installmentNumber,
    required int installmentCount,
  }) {
    final totalDays =
        returnDate.difference(loanDate).inDays;

    final daysPerInstallment =
        totalDays / installmentCount;

    final days =
        (daysPerInstallment * installmentNumber)
            .round();

    final calculatedDate =
        loanDate.add(
      Duration(days: days),
    );

    if (calculatedDate.isAfter(returnDate)) {
      return returnDate;
    }

    return calculatedDate;
  }

  // ============================================================
  // แปลง DateTime เป็น yyyy-MM-dd
  // ============================================================

  String _formatDate(DateTime date) {
    final year =
        date.year.toString().padLeft(4, '0');

    final month =
        date.month.toString().padLeft(2, '0');

    final day =
        date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }
}