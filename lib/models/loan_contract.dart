class LoanContract {
  final int? contractId;
  final String agreementId;
  final int lenderId;
  final int borrowerId;
  final double amount;
  final String currency;
  final String loanDate;
  final String returnDate;
  final double interestRate;
  final String? purpose;
  final String? notes;
  final String repaymentType;
  final String status;
  final int paidInstallments;
  final String? createdAt;
  final String? updatedAt;

  LoanContract({
    this.contractId,
    required this.agreementId,
    required this.lenderId,
    required this.borrowerId,
    required this.amount,
    this.currency = 'THB',
    required this.loanDate,
    required this.returnDate,
    this.interestRate = 0,
    this.purpose,
    this.notes,
    required this.repaymentType,
    this.status = 'draft',
    this.paidInstallments = 0,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'contract_id': contractId,
      'agreement_id': agreementId,
      'lender_id': lenderId,
      'borrower_id': borrowerId,
      'amount': amount,
      'currency': currency,
      'loan_date': loanDate,
      'return_date': returnDate,
      'interest_rate': interestRate,
      'purpose': purpose,
      'notes': notes,
      'repayment_type': repaymentType,
      'status': status,
      'paid_installments': paidInstallments,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory LoanContract.fromMap(Map<String, dynamic> map) {
    return LoanContract(
      contractId: map['contract_id'] as int?,
      agreementId: map['agreement_id'] as String,
      lenderId: map['lender_id'] as int,
      borrowerId: map['borrower_id'] as int,
      amount: (map['amount'] as num).toDouble(),
      currency: map['currency'] as String? ?? 'THB',
      loanDate: map['loan_date'] as String,
      returnDate: map['return_date'] as String,
      interestRate:
          (map['interest_rate'] as num?)?.toDouble() ?? 0,
      purpose: map['purpose'] as String?,
      notes: map['notes'] as String?,
      repaymentType: map['repayment_type'] as String,
      status: map['status'] as String? ?? 'draft',
      paidInstallments: map['paid_installments'] as int? ?? 0,
      createdAt: map['created_at'] as String?,
      updatedAt: map['updated_at'] as String?,
    );
  }
}