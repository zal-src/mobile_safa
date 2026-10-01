import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper instance =
      DatabaseHelper._internal();

  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initDatabase();

    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasePath =
        await getDatabasesPath();

    final path = join(
      databasePath,
      'safa_qard.db',
    );

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDatabase,
      onUpgrade: _upgradeDatabase,
    );
  }

  Future<void> _upgradeDatabase(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE loan_contracts ADD COLUMN paid_installments INTEGER DEFAULT 0');
    }
  }

  Future<void> _createDatabase(
    Database db,
    int version,
  ) async {
    // =========================
    // USERS
    // =========================

    await db.execute('''
      CREATE TABLE users (
        user_id INTEGER PRIMARY KEY AUTOINCREMENT,
        full_name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        phone TEXT,
        id_card TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // =========================
    // LOAN CONTRACTS
    // =========================

    await db.execute('''
      CREATE TABLE loan_contracts (
        contract_id INTEGER PRIMARY KEY AUTOINCREMENT,
        agreement_id TEXT NOT NULL UNIQUE,
        lender_id INTEGER NOT NULL,
        borrower_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        currency TEXT DEFAULT 'THB',
        loan_date TEXT NOT NULL,
        return_date TEXT NOT NULL,
        interest_rate REAL DEFAULT 0,
        purpose TEXT,
        notes TEXT,
        repayment_type TEXT NOT NULL,
        status TEXT DEFAULT 'draft',
        paid_installments INTEGER DEFAULT 0,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP,

        FOREIGN KEY (lender_id)
          REFERENCES users(user_id),

        FOREIGN KEY (borrower_id)
          REFERENCES users(user_id)
      )
    ''');

    // =========================
    // SIGNATURES
    // =========================

    await db.execute('''
      CREATE TABLE signatures (
        signature_id INTEGER PRIMARY KEY AUTOINCREMENT,
        contract_id INTEGER NOT NULL,
        user_id INTEGER NOT NULL,
        signature_data TEXT,
        signed_at TEXT DEFAULT CURRENT_TIMESTAMP,

        FOREIGN KEY (contract_id)
          REFERENCES loan_contracts(contract_id),

        FOREIGN KEY (user_id)
          REFERENCES users(user_id)
      )
    ''');

    // =========================
    // ADDRESSES
    // =========================

    await db.execute('''
      CREATE TABLE addresses (
        address_id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        address_type TEXT NOT NULL,
        address TEXT NOT NULL,
        province TEXT,
        district TEXT,
        subdistrict TEXT,
        postal_code TEXT,

        FOREIGN KEY (user_id)
          REFERENCES users(user_id)
      )
    ''');
  }

  // ==================================================
  // USER
  // ==================================================

  Future<int> insertUser(
    Map<String, dynamic> user,
  ) async {
    final db = await database;

    return await db.insert(
      'users',
      user,
    );
  }

  Future<Map<String, dynamic>?> getUserByEmail(
    String email,
  ) async {
    final db = await database;

    final result = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [
        email.trim().toLowerCase(),
      ],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return result.first;
  }

  Future<Map<String, dynamic>?> getUserById(
    int userId,
  ) async {
    final db = await database;

    final result = await db.query(
      'users',
      where: 'user_id = ?',
      whereArgs: [userId],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return result.first;
  }

  Future<int> updateUser(
    int userId,
    Map<String, dynamic> user,
  ) async {
    final db = await database;

    return await db.update(
      'users',
      user,
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  // ==================================================
  // LOGIN
  // ==================================================

  Future<Map<String, dynamic>?> loginUser(
    String email,
    String password,
  ) async {
    final db = await database;

    final result = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [
        email.trim().toLowerCase(),
        password,
      ],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return result.first;
  }

  // ==================================================
  // ADDRESS
  // ==================================================

  Future<int> insertAddress(
    Map<String, dynamic> address,
  ) async {
    final db = await database;

    return await db.insert(
      'addresses',
      address,
    );
  }

  Future<Map<String, dynamic>?> getUserAddress(
    int userId, {
    String addressType = 'registered',
  }) async {
    final db = await database;

    final result = await db.query(
      'addresses',
      where: 'user_id = ? AND address_type = ?',
      whereArgs: [
        userId,
        addressType,
      ],
      orderBy: 'address_id DESC',
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return result.first;
  }

  Future<List<Map<String, dynamic>>> getUserAddresses(
    int userId,
  ) async {
    final db = await database;

    return await db.query(
      'addresses',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'address_id DESC',
    );
  }

  Future<int> updateUserAddress(
    int userId,
    Map<String, dynamic> address,
  ) async {
    final db = await database;

    return await db.update(
      'addresses',
      address,
      where: 'user_id = ? AND address_type = ?',
      whereArgs: [
        userId,
        address['address_type'] ?? 'registered',
      ],
    );
  }

  // ==================================================
  // CONTRACT
  // ==================================================

  Future<int> insertContract(
    Map<String, dynamic> contract,
  ) async {
    final db = await database;

    return await db.insert(
      'loan_contracts',
      contract,
    );
  }

  Future<Map<String, dynamic>?> getContractById(
    int contractId,
  ) async {
    final db = await database;

    final result = await db.query(
      'loan_contracts',
      where: 'contract_id = ?',
      whereArgs: [contractId],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return result.first;
  }

  Future<int> updateContractStatus(
    int contractId,
    String status,
  ) async {
    final db = await database;

    return await db.update(
      'loan_contracts',
      {
        'status': status,
        'updated_at':
            DateTime.now().toIso8601String(),
      },
      where: 'contract_id = ?',
      whereArgs: [contractId],
    );
  }

  Future<int> updateContractPaidInstallments(
    int contractId,
    int paidInstallments,
  ) async {
    final db = await database;

    return await db.update(
      'loan_contracts',
      {
        'paid_installments': paidInstallments,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'contract_id = ?',
      whereArgs: [contractId],
    );
  }

  Future<List<Map<String, dynamic>>> getUserContracts(
    int userId,
  ) async {
    final db = await database;

    return await db.query(
      'loan_contracts',
      where:
          'lender_id = ? OR borrower_id = ?',
      whereArgs: [
        userId,
        userId,
      ],
      orderBy: 'created_at DESC',
    );
  }

  Future<int> updateContractAgreementId(
    int contractId,
    String agreementId,
  ) async {
    final db = await database;

    return await db.update(
      'loan_contracts',
      {
        'agreement_id': agreementId,
        'updated_at':
            DateTime.now().toIso8601String(),
      },
      where: 'contract_id = ?',
      whereArgs: [contractId],
    );
  }

  Future<List<Map<String, dynamic>>>
      getAllContracts() async {
    final db = await database;

    return await db.query(
      'loan_contracts',
      orderBy: 'contract_id ASC',
    );
  }

  // ==================================================
  // SIGNATURE
  // ==================================================

  Future<int> insertSignature(
    Map<String, dynamic> signature,
  ) async {
    final db = await database;

    final existing = await db.query(
      'signatures',
      where:
          'contract_id = ? AND user_id = ?',
      whereArgs: [
        signature['contract_id'],
        signature['user_id'],
      ],
      limit: 1,
    );

    if (existing.isNotEmpty) {
      throw Exception(
        'คุณได้ลงลายมือชื่อในสัญญานี้แล้ว',
      );
    }

    return await db.insert(
      'signatures',
      signature,
    );
  }

  Future<Map<String, dynamic>?> getSignature(
    int contractId,
    int userId,
  ) async {
    final db = await database;

    final result = await db.query(
      'signatures',
      where:
          'contract_id = ? AND user_id = ?',
      whereArgs: [
        contractId,
        userId,
      ],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return result.first;
  }

  Future<List<Map<String, dynamic>>>
      getContractSignatures(
    int contractId,
  ) async {
    final db = await database;

    return await db.query(
      'signatures',
      where: 'contract_id = ?',
      whereArgs: [contractId],
      orderBy: 'signed_at ASC',
    );
  }

  Future<bool> hasSignature(
    int contractId,
    int userId,
  ) async {
    final db = await database;

    final result = await db.query(
      'signatures',
      where:
          'contract_id = ? AND user_id = ?',
      whereArgs: [
        contractId,
        userId,
      ],
      limit: 1,
    );

    return result.isNotEmpty;
  }

  // ==================================================
  // REPAYMENT
  // ==================================================

  Future<int> insertRepayment(
    Map<String, dynamic> repayment,
  ) async {
    final db = await database;

    return await db.insert(
      'repayments',
      repayment,
    );
  }

  Future<List<Map<String, dynamic>>>
      getContractRepayments(
    int contractId,
  ) async {
    final db = await database;

    return await db.query(
      'repayments',
      where: 'contract_id = ?',
      whereArgs: [contractId],
      orderBy: 'due_date ASC',
    );
  }

  Future<Map<String, dynamic>?>
      getRepaymentById(
    int repaymentId,
  ) async {
    final db = await database;

    final result = await db.query(
      'repayments',
      where: 'repayment_id = ?',
      whereArgs: [repaymentId],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return result.first;
  }

  Future<int> updateRepaymentStatus(
    int repaymentId, {
    required String status,
    String? paidDate,
    String? notes,
  }) async {
    final db = await database;

    final data =
        <String, dynamic>{
      'status': status,
      'paid_date': paidDate,
      'notes': notes,
    };

    return await db.update(
      'repayments',
      data,
      where: 'repayment_id = ?',
      whereArgs: [repaymentId],
    );
  }

  Future<bool> hasRepayments(
    int contractId,
  ) async {
    final db = await database;

    final result = await db.query(
      'repayments',
      where: 'contract_id = ?',
      whereArgs: [contractId],
      limit: 1,
    );

    return result.isNotEmpty;
  }
}