import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(const Locale('th', 'TH'));
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  bool get isThai => locale.languageCode == 'th';

  static final Map<String, Map<String, String>> _localizedValues = {
    'th': {
      // General & Common
      'appName': 'Safa',
      'appSubtitle': 'แพลตฟอร์มสัญญาเงินกู้ปลอดดอกเบี้ย (กอรฎุลฮะซัน)',
      'ok': 'ตกลง',
      'cancel': 'ยกเลิก',
      'confirm': 'ยืนยัน',
      'save': 'บันทึก',
      'delete': 'ลบ',
      'edit': 'แก้ไข',
      'back': 'ย้อนกลับ',
      'close': 'ปิด',
      'search': 'ค้นหา',
      'loading': 'กำลังโหลด...',
      'success': 'สำเร็จ',
      'error': 'ข้อผิดพลาด',
      'retry': 'ลองใหม่อีกครั้ง',
      'viewDetails': 'ดูรายละเอียด',
      'copy': 'คัดลอก',
      'copied': 'คัดลอกเรียบร้อยแล้ว',
      'continue': 'ดำเนินการต่อ',

      // Language Switcher
      'changeLanguage': 'เปลี่ยนภาษา',
      'language': 'ภาษา',
      'thai': 'ภาษาไทย',
      'english': 'English',

      // Auth
      'login': 'เข้าสู่ระบบ',
      'register': 'สมัครสมาชิก',
      'email': 'อีเมล',
      'enterEmail': 'กรุณากรอกอีเมล',
      'password': 'รหัสผ่าน',
      'enterPassword': 'กรุณากรอกรหัสผ่าน',
      'confirmPassword': 'ยืนยันรหัสผ่าน',
      'fullName': 'ชื่อ-นามสกุล',
      'phone': 'เบอร์โทรศัพท์',
      'idCard': 'เลขประจำตัวประชาชน',
      'address': 'ที่อยู่',
      'noAccount': 'ยังไม่มีบัญชีใช่หรือไม่?',
      'alreadyHaveAccount': 'มีบัญชีอยู่แล้ว?',
      'loginSuccess': 'เข้าสู่ระบบสำเร็จ',
      'loginFailed': 'อีเมลหรือรหัสผ่านไม่ถูกต้อง',
      'logout': 'ออกจากระบบ',
      'logoutConfirm': 'คุณต้องการออกจากระบบใช่หรือไม่?',

      // Navigation
      'navHome': 'หน้าหลัก',
      'navContracts': 'สัญญา',
      'navKnowledge': 'คลังความรู้',
      'navAiChat': 'ถาม AI',
      'navProfile': 'โปรไฟล์',

      // Home & Dashboard
      'welcome': 'ยินดีต้อนรับ',
      'overview': 'สรุปภาพรวม',
      'totalLent': 'ให้กู้ยืมรวม',
      'totalBorrowed': 'ขอกู้ยืมรวม',
      'totalContracts': 'สัญญาทั้งหมด',
      'recentContracts': 'สัญญาล่าสุด',
      'viewAll': 'ดูทั้งหมด',
      'noContractsYet': 'ยังไม่มีรายการสัญญาในระบบ',
      'createContract': 'สร้างสัญญาใหม่',
      'createContractDesc': 'ทำสัญญาเงินกู้ปลอดดอกเบี้ยตามหลักชะรีอะฮ์',
      'financialHealthCheck': 'ตรวจสุขภาพการเงิน',
      'financialHealthCheckDesc': 'ประเมินความพร้อมและภาระหนี้ก่อนกู้ยืม',
      'aiAdvisor': 'ที่ปรึกษาการเงิน AI',
      'aiAdvisorDesc': 'ตอบคำถามการเงินและสัญญาตามหลักการอิสลาม',

      // Role Selection
      'selectRoleTitle': 'เลือกบทบาทของคุณ',
      'selectRoleSubtitle': 'คุณมีบทบาทอะไรในสัญญานี้?',
      'roleLenderTitle': 'ฉันเป็นผู้ให้กู้',
      'roleLenderSubtitle': 'ผู้ให้กู้ (Lender)',
      'roleLenderDesc': 'สร้างสัญญาในฐานะผู้ให้กู้ และระบุอีเมลของผู้กู้',
      'roleBorrowerTitle': 'ฉันเป็นผู้กู้',
      'roleBorrowerSubtitle': 'ผู้กู้ (Borrower)',
      'roleBorrowerDesc': 'สร้างสัญญาในฐานะผู้กู้ และระบุอีเมลของผู้ให้กู้',
      'roleAutoFillNotice': 'ข้อมูลของบัญชีที่เข้าสู่ระบบจะถูกใช้เป็นข้อมูลของคุณอัตโนมัติ โดยไม่ต้องกรอกข้อมูลส่วนตัวของคุณซ้ำ',

      // Contract
      'contractInfo': 'ข้อมูลสัญญา',
      'agreementId': 'เลขที่สัญญา',
      'loanAmount': 'จำนวนเงินกู้',
      'loanDate': 'วันที่ทำสัญญา',
      'returnDate': 'กำหนดชำระคืน',
      'repaymentType': 'รูปแบบการคืนเงิน',
      'lumpSum': 'ชำระครั้งเดียวเต็มจำนวน',
      'installments': 'แบ่งชำระเป็นงวด',
      'interestFree': 'ดอกเบี้ย 0% (กอรฎุลฮะซัน)',
      'purpose': 'วัตถุประสงค์การกู้',
      'notes': 'เงื่อนไขหรือหมายเหตุเพิ่มเติม',
      'printPdf': 'พิมพ์ / บันทึก PDF',
      'signContract': 'ลงนามในสัญญา',
      'contractStatus': 'สถานะสัญญา',
      'statusDraft': 'แบบร่าง',
      'statusPendingSign': 'รอลงนาม',
      'statusActive': 'มีผลบังคับ',
      'statusCompleted': 'ปิดสัญญาแล้ว',
      'statusOverdue': 'เกินกำหนด',
      'statusCancelled': 'ยกเลิกแล้ว',
      'selectReturnDate': 'เลือกวันคืนเงิน',
    },
    'en': {
      // General & Common
      'appName': 'Safa',
      'appSubtitle': 'Interest-Free Loan Agreement Platform (Qard Hasan)',
      'ok': 'OK',
      'cancel': 'Cancel',
      'confirm': 'Confirm',
      'save': 'Save',
      'delete': 'Delete',
      'edit': 'Edit',
      'back': 'Back',
      'close': 'Close',
      'search': 'Search',
      'loading': 'Loading...',
      'success': 'Success',
      'error': 'Error',
      'retry': 'Retry',
      'viewDetails': 'View Details',
      'copy': 'Copy',
      'copied': 'Copied to clipboard',
      'continue': 'Continue',

      // Language Switcher
      'changeLanguage': 'Change Language',
      'language': 'Language',
      'thai': 'ภาษาไทย (Thai)',
      'english': 'English',

      // Auth
      'login': 'Log In',
      'register': 'Register',
      'email': 'Email',
      'enterEmail': 'Please enter your email',
      'password': 'Password',
      'enterPassword': 'Please enter your password',
      'confirmPassword': 'Confirm Password',
      'fullName': 'Full Name',
      'phone': 'Phone Number',
      'idCard': 'National ID Card',
      'address': 'Address',
      'noAccount': "Don't have an account?",
      'alreadyHaveAccount': 'Already have an account?',
      'loginSuccess': 'Logged in successfully',
      'loginFailed': 'Invalid email or password',
      'logout': 'Log Out',
      'logoutConfirm': 'Are you sure you want to log out?',

      // Navigation
      'navHome': 'Home',
      'navContracts': 'Contracts',
      'navKnowledge': 'Knowledge',
      'navAiChat': 'Ask AI',
      'navProfile': 'Profile',

      // Home & Dashboard
      'welcome': 'Welcome',
      'overview': 'Overview',
      'totalLent': 'Total Lent',
      'totalBorrowed': 'Total Borrowed',
      'totalContracts': 'Total Contracts',
      'recentContracts': 'Recent Contracts',
      'viewAll': 'View All',
      'noContractsYet': 'No contracts found',
      'createContract': 'Create Contract',
      'createContractDesc': 'Draft an interest-free Shariah-compliant loan agreement',
      'financialHealthCheck': 'Financial Health Check',
      'financialHealthCheckDesc': 'Assess debt capacity and readiness before borrowing',
      'aiAdvisor': 'AI Financial Advisor',
      'aiAdvisorDesc': 'Consult halal financing and loan contract queries',

      // Role Selection
      'selectRoleTitle': 'Select Your Role',
      'selectRoleSubtitle': 'What is your role in this agreement?',
      'roleLenderTitle': 'I am the Lender',
      'roleLenderSubtitle': 'Lender',
      'roleLenderDesc': 'Draft contract as lender and specify borrower details',
      'roleBorrowerTitle': 'I am the Borrower',
      'roleBorrowerSubtitle': 'Borrower',
      'roleBorrowerDesc': 'Draft contract as borrower and specify lender details',
      'roleAutoFillNotice': 'Your logged-in account details will be used automatically as your party information.',

      // Contract
      'contractInfo': 'Contract Information',
      'agreementId': 'Agreement ID',
      'loanAmount': 'Loan Amount',
      'loanDate': 'Contract Date',
      'returnDate': 'Repayment Due Date',
      'repaymentType': 'Repayment Method',
      'lumpSum': 'Lump Sum Payment',
      'installments': 'Installment Payments',
      'interestFree': '0% Interest (Qard Hasan)',
      'purpose': 'Purpose of Loan',
      'notes': 'Additional Terms / Notes',
      'printPdf': 'Print / Export PDF',
      'signContract': 'Sign Agreement',
      'contractStatus': 'Contract Status',
      'statusDraft': 'Draft',
      'statusPendingSign': 'Pending Signature',
      'statusActive': 'Active',
      'statusCompleted': 'Completed',
      'statusOverdue': 'Overdue',
      'statusCancelled': 'Cancelled',
      'selectReturnDate': 'Select Due Date',
    },
  };

  /// ค้นหาข้อความตาม key ถ้าไม่พบจะคืนค่า key หรือ defaultText
  String translate(String key, {String? defaultText}) {
    final langCode = locale.languageCode;
    final dict = _localizedValues[langCode] ?? _localizedValues['th']!;
    return dict[key] ?? defaultText ?? key;
  }

  // Shorthand getters for common words
  String get appName => translate('appName');
  String get appSubtitle => translate('appSubtitle');
  String get ok => translate('ok');
  String get cancel => translate('cancel');
  String get confirm => translate('confirm');
  String get save => translate('save');
  String get delete => translate('delete');
  String get edit => translate('edit');
  String get back => translate('back');
  String get close => translate('close');
  String get search => translate('search');
  String get loading => translate('loading');
  String get success => translate('success');
  String get error => translate('error');
  String get viewDetails => translate('viewDetails');
  String get continueBtn => translate('continue');

  String get changeLanguage => translate('changeLanguage');
  String get language => translate('language');
  String get thai => translate('thai');
  String get english => translate('english');

  String get login => translate('login');
  String get register => translate('register');
  String get email => translate('email');
  String get password => translate('password');
  String get logout => translate('logout');

  String get navHome => translate('navHome');
  String get navContracts => translate('navContracts');
  String get navKnowledge => translate('navKnowledge');
  String get navAiChat => translate('navAiChat');
  String get navProfile => translate('navProfile');

  String get welcome => translate('welcome');
  String get totalLent => translate('totalLent');
  String get totalBorrowed => translate('totalBorrowed');
  String get totalContracts => translate('totalContracts');
  String get recentContracts => translate('recentContracts');
  String get createContract => translate('createContract');
  String get financialHealthCheck => translate('financialHealthCheck');
  String get aiAdvisor => translate('aiAdvisor');

  String get selectRoleTitle => translate('selectRoleTitle');
  String get selectRoleSubtitle => translate('selectRoleSubtitle');
  String get roleLenderTitle => translate('roleLenderTitle');
  String get roleBorrowerTitle => translate('roleBorrowerTitle');
  String get roleAutoFillNotice => translate('roleAutoFillNotice');

  String get contractInfo => translate('contractInfo');
  String get agreementId => translate('agreementId');
  String get loanAmount => translate('loanAmount');
  String get loanDate => translate('loanDate');
  String get returnDate => translate('returnDate');
  String get printPdf => translate('printPdf');
  String get signContract => translate('signContract');
  String get contractStatus => translate('contractStatus');
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['th', 'en'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
