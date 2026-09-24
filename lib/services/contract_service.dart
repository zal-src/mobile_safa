import '../database/database_helper.dart';
import '../models/loan_contract.dart';

class ContractService {
  final DatabaseHelper _database =
      DatabaseHelper.instance;

  Future<LoanContract> createContract({
    required int lenderId,
    required int borrowerId,
    required double amount,
    required String loanDate,
    required String returnDate,
    required String repaymentType,
    String? purpose,
    String? notes,
  }) async {
    if (lenderId == borrowerId) {
      throw Exception(
        'ผู้ให้กู้และผู้กู้ต้องเป็นคนละคนกัน',
      );
    }

    if (amount <= 0) {
      throw Exception(
        'จำนวนเงินต้องมากกว่า 0',
      );
    }

    // --------------------------------------------------
    // ตรวจสอบวันที่
    // --------------------------------------------------

    final today = _dateOnly(
      DateTime.now(),
    );

    final loanDateOnly =
        _parseDateOnly(loanDate);

    final returnDateOnly =
        _parseDateOnly(returnDate);

    // วันให้กู้ต้องเป็นวันนี้เท่านั้น
    if (!_isSameDate(
      loanDateOnly,
      today,
    )) {
      throw Exception(
        'วันให้กู้ต้องเป็นวันที่ปัจจุบันเท่านั้น',
      );
    }

    // วันคืนเงินห้ามย้อนหลัง
    if (returnDateOnly.isBefore(today)) {
      throw Exception(
        'วันคืนเงินต้องไม่เป็นวันที่ย้อนหลัง',
      );
    }

    // วันคืนเงินต้องไม่ก่อนวันให้กู้
    if (returnDateOnly.isBefore(
      loanDateOnly,
    )) {
      throw Exception(
        'วันคืนเงินต้องไม่ก่อนวันให้กู้',
      );
    }

    // --------------------------------------------------
    // สร้างสัญญา
    // --------------------------------------------------

    final temporaryAgreementId =
        'TEMP-${DateTime.now().millisecondsSinceEpoch}';

    final contract = LoanContract(
      agreementId: temporaryAgreementId,
      lenderId: lenderId,
      borrowerId: borrowerId,
      amount: amount,
      currency: 'THB',
      loanDate: _formatDate(
        loanDateOnly,
      ),
      returnDate: _formatDate(
        returnDateOnly,
      ),
      interestRate: 0,
      purpose: purpose,
      notes: notes,
      repaymentType: repaymentType,
      status: 'active',
    );

    final contractId =
        await _database.insertContract(
      contract.toMap(),
    );

    // --------------------------------------------------
    // สร้างเลขที่สัญญา
    // รูปแบบ QH-ปี-เลข 4 หลัก
    // --------------------------------------------------

    final year =
        loanDateOnly.year;

    final agreementId =
        'QH-$year-${contractId.toString().padLeft(4, '0')}';

    await _database.updateContractAgreementId(
      contractId,
      agreementId,
    );

    return LoanContract(
      contractId: contractId,
      agreementId: agreementId,
      lenderId: contract.lenderId,
      borrowerId: contract.borrowerId,
      amount: contract.amount,
      currency: contract.currency,
      loanDate: contract.loanDate,
      returnDate: contract.returnDate,
      interestRate: contract.interestRate,
      purpose: contract.purpose,
      notes: contract.notes,
      repaymentType: contract.repaymentType,
      status: contract.status,
    );
  }

  Future<LoanContract?> getContract(
    int contractId,
  ) async {
    final result =
        await _database.getContractById(
      contractId,
    );

    if (result == null) {
      return null;
    }

    return LoanContract.fromMap(
      result,
    );
  }

  Future<List<LoanContract>> getUserContracts(
    int userId,
  ) async {
    final result =
        await _database.getUserContracts(
      userId,
    );

    return result
        .map(
          (map) => LoanContract.fromMap(
            map,
          ),
        )
        .toList();
  }

  Future<LoanContract> createContractByEmail({
    required int lenderId,
    required String borrowerEmail,
    required double amount,
    required String loanDate,
    required String returnDate,
    required String repaymentType,
    String? purpose,
    String? notes,
    String? borrowerName,
    String? borrowerPhone,
    String? borrowerIdCard,
    String? borrowerAddress,
  }) async {
    final borrower = await _database.getUserByEmail(
      borrowerEmail,
    );

    int borrowerId;

    if (borrower == null) {
      final name = (borrowerName != null && borrowerName.trim().isNotEmpty)
          ? borrowerName.trim()
          : borrowerEmail.split('@').first;
      final phone = (borrowerPhone != null && borrowerPhone.trim().isNotEmpty)
          ? borrowerPhone.trim()
          : null;
      final idCard =
          (borrowerIdCard != null && borrowerIdCard.trim().isNotEmpty)
              ? borrowerIdCard.trim()
              : null;

      borrowerId = await _database.insertUser({
        'full_name': name,
        'email': borrowerEmail.trim().toLowerCase(),
        'password': '',
        'phone': phone,
        'id_card': idCard,
      });

      if (borrowerAddress != null && borrowerAddress.trim().isNotEmpty) {
        await _database.insertAddress({
          'user_id': borrowerId,
          'address_type': 'registered',
          'address': borrowerAddress.trim(),
        });
      }
    } else {
      borrowerId = borrower['user_id'] as int;

      final updates = <String, dynamic>{};
      if ((borrower['phone'] == null ||
              borrower['phone'].toString().trim().isEmpty) &&
          borrowerPhone != null &&
          borrowerPhone.trim().isNotEmpty) {
        updates['phone'] = borrowerPhone.trim();
      }
      if ((borrower['id_card'] == null ||
              borrower['id_card'].toString().trim().isEmpty) &&
          borrowerIdCard != null &&
          borrowerIdCard.trim().isNotEmpty) {
        updates['id_card'] = borrowerIdCard.trim();
      }
      if ((borrower['full_name'] == null ||
              borrower['full_name'].toString().trim().isEmpty) &&
          borrowerName != null &&
          borrowerName.trim().isNotEmpty) {
        updates['full_name'] = borrowerName.trim();
      }
      if (updates.isNotEmpty) {
        await _database.updateUser(borrowerId, updates);
      }
    }

    if (lenderId == borrowerId) {
      throw Exception(
        'ไม่สามารถสร้างสัญญากับตัวเองได้',
      );
    }

    return createContract(
      lenderId: lenderId,
      borrowerId: borrowerId,
      amount: amount,
      loanDate: loanDate,
      returnDate: returnDate,
      repaymentType: repaymentType,
      purpose: purpose,
      notes: notes,
    );
  }

  Future<LoanContract> createContractByRole({
    required int currentUserId,
    required String role,
    required String counterpartyEmail,
    required double amount,
    required String loanDate,
    required String returnDate,
    required String repaymentType,
    String? purpose,
    String? notes,
    String? counterpartyName,
    String? counterpartyPhone,
    String? counterpartyIdCard,
    String? counterpartyAddress,
  }) async {
    final counterparty = await _database.getUserByEmail(
      counterpartyEmail,
    );

    int counterpartyId;

    if (counterparty == null) {
      final name =
          (counterpartyName != null && counterpartyName.trim().isNotEmpty)
              ? counterpartyName.trim()
              : counterpartyEmail.split('@').first;
      final phone =
          (counterpartyPhone != null && counterpartyPhone.trim().isNotEmpty)
              ? counterpartyPhone.trim()
              : null;
      final idCard =
          (counterpartyIdCard != null && counterpartyIdCard.trim().isNotEmpty)
              ? counterpartyIdCard.trim()
              : null;

      counterpartyId = await _database.insertUser({
        'full_name': name,
        'email': counterpartyEmail.trim().toLowerCase(),
        'password': '',
        'phone': phone,
        'id_card': idCard,
      });

      if (counterpartyAddress != null &&
          counterpartyAddress.trim().isNotEmpty) {
        await _database.insertAddress({
          'user_id': counterpartyId,
          'address_type': 'registered',
          'address': counterpartyAddress.trim(),
        });
      }
    } else {
      counterpartyId = counterparty['user_id'] as int;

      final updates = <String, dynamic>{};
      if ((counterparty['phone'] == null ||
              counterparty['phone'].toString().trim().isEmpty) &&
          counterpartyPhone != null &&
          counterpartyPhone.trim().isNotEmpty) {
        updates['phone'] = counterpartyPhone.trim();
      }
      if ((counterparty['id_card'] == null ||
              counterparty['id_card'].toString().trim().isEmpty) &&
          counterpartyIdCard != null &&
          counterpartyIdCard.trim().isNotEmpty) {
        updates['id_card'] = counterpartyIdCard.trim();
      }
      if ((counterparty['full_name'] == null ||
              counterparty['full_name'].toString().trim().isEmpty) &&
          counterpartyName != null &&
          counterpartyName.trim().isNotEmpty) {
        updates['full_name'] = counterpartyName.trim();
      }
      if (updates.isNotEmpty) {
        await _database.updateUser(counterpartyId, updates);
      }

      if (counterpartyAddress != null &&
          counterpartyAddress.trim().isNotEmpty) {
        final existingAddress = await _database.getUserAddress(counterpartyId);
        if (existingAddress == null) {
          await _database.insertAddress({
            'user_id': counterpartyId,
            'address_type': 'registered',
            'address': counterpartyAddress.trim(),
          });
        }
      }
    }

    if (counterpartyId == currentUserId) {
      throw Exception(
        'ไม่สามารถสร้างสัญญากับตัวเองได้',
      );
    }

    if (role == 'lender') {
      return createContract(
        lenderId: currentUserId,
        borrowerId: counterpartyId,
        amount: amount,
        loanDate: loanDate,
        returnDate: returnDate,
        repaymentType: repaymentType,
        purpose: purpose,
        notes: notes,
      );
    }

    if (role == 'borrower') {
      return createContract(
        lenderId: counterpartyId,
        borrowerId: currentUserId,
        amount: amount,
        loanDate: loanDate,
        returnDate: returnDate,
        repaymentType: repaymentType,
        purpose: purpose,
        notes: notes,
      );
    }

    throw Exception(
      'ไม่พบประเภทผู้ใช้ที่ถูกต้อง',
    );
  }

  Future<void> migrateOldAgreementIds() async {
    final contracts =
        await _database.getAllContracts();

    for (final contract in contracts) {
      final contractId =
          contract['contract_id'] as int;

      final currentAgreementId =
          contract['agreement_id'] as String;

      final isNewFormat =
          RegExp(
        r'^QH-\d{4}-\d{4}$',
      ).hasMatch(
        currentAgreementId,
      );

      if (isNewFormat) {
        continue;
      }

      final loanDate =
          contract['loan_date'] as String;

      final year =
          DateTime.parse(
        loanDate,
      ).year;

      final newAgreementId =
          'QH-$year-${contractId.toString().padLeft(4, '0')}';

      await _database.updateContractAgreementId(
        contractId,
        newAgreementId,
      );
    }
  }

  // ==================================================
  // Helper สำหรับจัดการวันที่
  // ==================================================

  DateTime _parseDateOnly(
    String value,
  ) {
    final date =
        DateTime.parse(value);

    return _dateOnly(date);
  }

  DateTime _dateOnly(
    DateTime date,
  ) {
    return DateTime(
      date.year,
      date.month,
      date.day,
    );
  }

  bool _isSameDate(
    DateTime first,
    DateTime second,
  ) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  String _formatDate(
    DateTime date,
  ) {
    final year =
        date.year.toString().padLeft(
              4,
              '0',
            );

    final month =
        date.month.toString().padLeft(
              2,
              '0',
            );

    final day =
        date.day.toString().padLeft(
              2,
              '0',
            );

    return '$year-$month-$day';
  }
}