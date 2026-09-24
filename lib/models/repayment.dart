class Repayment {
  final int? repaymentId;
  final int contractId;
  final double amount;
  final String dueDate;
  final String? paidDate;
  final String status;
  final String? notes;

  Repayment({
    this.repaymentId,
    required this.contractId,
    required this.amount,
    required this.dueDate,
    this.paidDate,
    this.status = 'pending',
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'repayment_id': repaymentId,
      'contract_id': contractId,
      'amount': amount,
      'due_date': dueDate,
      'paid_date': paidDate,
      'status': status,
      'notes': notes,
    };
  }

  factory Repayment.fromMap(
    Map<String, dynamic> map,
  ) {
    return Repayment(
      repaymentId:
          map['repayment_id'] as int?,
      contractId:
          map['contract_id'] as int,
      amount:
          (map['amount'] as num).toDouble(),
      dueDate:
          map['due_date'] as String,
      paidDate:
          map['paid_date'] as String?,
      status:
          map['status'] as String? ?? 'pending',
      notes:
          map['notes'] as String?,
    );
  }
}