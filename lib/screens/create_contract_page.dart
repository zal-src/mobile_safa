import 'package:flutter/material.dart';

import '../localization/app_localizations.dart';
import '../models/user.dart';
import '../services/contract_service.dart';
import '../services/onboarding_service.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';
import '../widgets/responsive_container.dart';
import '../widgets/onboarding_bottom_sheet.dart';
import '../widgets/create_contract/contract_progress_steps.dart';
import '../widgets/create_contract/counterparty_details_form.dart';
import '../widgets/create_contract/contract_details_form.dart';
import '../widgets/create_contract/contract_date_utils.dart';
import '../widgets/create_contract/contract_validators.dart';

// =============================================================================
// CreateContractPage
// - หน้าสร้างสัญญาเงินกู้ (Qard Hasan)
// - แบ่งเป็น 2 ขั้นตอน: (0) ข้อมูลคู่สัญญา → (1) รายละเอียดสัญญา
//
// Widget ย่อยที่เกี่ยวข้อง (ดูใน lib/widgets/create_contract/):
//   - contract_progress_steps.dart   → แถบขั้นตอน 1/2/3
//   - counterparty_details_form.dart → ฟอร์มข้อมูลคู่สัญญา (Step 0)
//   - contract_details_form.dart     → ฟอร์มรายละเอียดสัญญา (Step 1)
//   - contract_form_styles.dart      → style/decoration ของ field ต่างๆ
//   - contract_date_utils.dart       → helper วันที่ (format, parse, today)
//   - contract_validators.dart       → validation email/amount/returnDate
// =============================================================================

bool canUseMonthlyRepayment({
  required DateTime loanDate,
  required DateTime returnDate,
}) {
  return loanDate.year != returnDate.year || loanDate.month != returnDate.month;
}

class CreateContractPage extends StatefulWidget {
  final User user;
  final String role;
  final double? initialAmount;
  final String? initialPurpose;
  final String? initialReturnDate;
  final String? initialCounterpartyName;
  final String? initialCounterpartyEmail;
  final String? initialCounterpartyPhone;

  const CreateContractPage({
    super.key,
    required this.user,
    required this.role,
    this.initialAmount,
    this.initialPurpose,
    this.initialReturnDate,
    this.initialCounterpartyName,
    this.initialCounterpartyEmail,
    this.initialCounterpartyPhone,
  });

  @override
  State<CreateContractPage> createState() => _CreateContractPageState();
}

class _CreateContractPageState extends State<CreateContractPage> {
  final ContractService _contractService = ContractService();
  final _formKey = GlobalKey<FormState>();

  // GlobalKeys สำหรับ spotlight tutorial
  final _keySteps = GlobalKey();
  final _keyCounterparty = GlobalKey();
  final _keyActionBtn = GlobalKey();

  // Controllers
  final _counterpartyEmailController = TextEditingController();
  final _counterpartyNameController = TextEditingController();
  final _counterpartyPhoneController = TextEditingController();
  final _counterpartyIdCardController = TextEditingController();
  final _counterpartyAddressController = TextEditingController();
  final _amountController = TextEditingController();
  final _loanDateController = TextEditingController();
  final _returnDateController = TextEditingController();
  final _purposeController = TextEditingController();
  final _notesController = TextEditingController();

  // State
  bool _isSaving = false;
  int _currentStep = 0;
  String _repaymentType = 'ครั้งเดียว';

  // Getters
  bool get _isLender => widget.role == 'lender';
  bool get _isBorrower => widget.role == 'borrower';
  String get _counterpartyText => _isLender ? 'ผู้กู้' : 'ผู้ให้กู้';
  String get _counterpartyLabel => _isLender ? 'อีเมลผู้กู้' : 'อีเมลผู้ให้กู้';
  String get _counterpartyHint =>
      _isLender ? 'กรอกอีเมลของผู้กู้' : 'กรอกอีเมลของผู้ให้กู้';
  bool get _monthlyRepaymentAvailable {
    final loanDate = ContractDateUtils.parseDate(_loanDateController.text);
    final returnDate = ContractDateUtils.parseDate(_returnDateController.text);
    return loanDate != null &&
        returnDate != null &&
        canUseMonthlyRepayment(loanDate: loanDate, returnDate: returnDate);
  }

  // -------------------------------------------------------------------------
  // Lifecycle
  // -------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    // วันให้กู้/วันเริ่มสัญญาเป็นวันนี้เท่านั้น
    _loanDateController.text = ContractDateUtils.formatDate(
      ContractDateUtils.today(),
    );

    // กรอกข้อมูลเริ่มต้นที่ส่งมาจาก AI หรือการเรียกใช้แบบระบุค่า
    if (widget.initialAmount != null && widget.initialAmount! > 0) {
      _amountController.text = widget.initialAmount! % 1 == 0
          ? widget.initialAmount!.toInt().toString()
          : widget.initialAmount!.toString();
    }
    if (widget.initialPurpose != null && widget.initialPurpose!.isNotEmpty) {
      _purposeController.text = widget.initialPurpose!;
    }
    if (widget.initialReturnDate != null && widget.initialReturnDate!.isNotEmpty) {
      _returnDateController.text = widget.initialReturnDate!;
    }
    if (widget.initialCounterpartyName != null && widget.initialCounterpartyName!.isNotEmpty) {
      _counterpartyNameController.text = widget.initialCounterpartyName!;
    }
    if (widget.initialCounterpartyEmail != null && widget.initialCounterpartyEmail!.isNotEmpty) {
      _counterpartyEmailController.text = widget.initialCounterpartyEmail!;
    }
    if (widget.initialCounterpartyPhone != null && widget.initialCounterpartyPhone!.isNotEmpty) {
      _counterpartyPhoneController.text = widget.initialCounterpartyPhone!;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowOnboarding());
  }

  @override
  void dispose() {
    _counterpartyEmailController.dispose();
    _counterpartyNameController.dispose();
    _counterpartyPhoneController.dispose();
    _counterpartyIdCardController.dispose();
    _counterpartyAddressController.dispose();
    _amountController.dispose();
    _loanDateController.dispose();
    _returnDateController.dispose();
    _purposeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // -------------------------------------------------------------------------
  // Onboarding Tutorial
  // -------------------------------------------------------------------------

  Future<void> _maybeShowOnboarding() async {
    final seen = await OnboardingService.instance.hasSeenOnboarding(
      OnboardingService.keyCreateContract,
    );
    if (!mounted || seen) return;
    await OnboardingService.instance.markAsSeen(
      OnboardingService.keyCreateContract,
    );
    if (!mounted) return;

    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;

    await SpotlightTutorial.show(
      context,
      steps: [
        TutorialStep(
          title: 'ขั้นตอนการสร้างสัญญา',
          description:
              'มีทั้งหมด 3 ขั้น: ข้อมูลคู่สัญญา → รายละเอียดเงินกู้ → บันทึก\nทำทีละขั้น ระบบจะตรวจสอบให้อัตโนมัติ',
          targetKey: _keySteps,
          spotlightPadding: const EdgeInsets.symmetric(
            horizontal: 6,
            vertical: 10,
          ),
        ),
        TutorialStep(
          title: 'กรอกข้อมูลคู่สัญญา',
          description:
              'ใส่อีเมลของคนที่คุณจะทำสัญญาด้วย\nถ้าเขายังไม่มีบัญชี ระบบจะสร้างให้อัตโนมัติ',
          targetKey: _keyCounterparty,
          spotlightPadding: const EdgeInsets.all(8),
        ),
        TutorialStep(
          title: 'กดเพื่อไปขั้นต่อไป',
          description:
              'เมื่อกรอกครบแล้ว กดปุ่มนี้เพื่อไปขั้นถัดไป\nขั้นสุดท้ายจะสรุปข้อมูลก่อนบันทึกจริง',
          targetKey: _keyActionBtn,
          spotlightPadding: const EdgeInsets.all(6),
          spotlightRadius: 10,
        ),
      ],
    );
  }

  // -------------------------------------------------------------------------
  // Date Picker (ใช้ ContractDateUtils → contract_date_utils.dart)
  // -------------------------------------------------------------------------

  Future<void> _selectReturnDate() async {
    if (_isSaving) return;

    final today = ContractDateUtils.today();
    final current = ContractDateUtils.parseDate(_returnDateController.text);

    DateTime initialDate = today;
    if (current != null && !current.isBefore(today)) {
      initialDate = current;
    }

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: today,
      lastDate: DateTime(today.year + 20, today.month, today.day),
      helpText: context.l10n.translate(
        'selectReturnDate',
        defaultText: 'เลือกวันคืนเงิน',
      ),
      cancelText: context.l10n.cancel,
      confirmText: context.l10n.confirm,
    );

    if (selectedDate == null || !mounted) return;

    final selected = ContractDateUtils.dateOnly(selectedDate);
    final loanDate = ContractDateUtils.parseDate(_loanDateController.text);

    if (selected.isBefore(today)) {
      _showError('วันคืนเงินต้องไม่เป็นวันที่ย้อนหลัง');
      return;
    }
    if (loanDate != null && selected.isBefore(loanDate)) {
      _showError('วันคืนเงินต้องไม่ก่อนวันให้กู้');
      return;
    }

    final canUseMonthlyRepaymentForSelectedDate =
        loanDate != null &&
        canUseMonthlyRepayment(loanDate: loanDate, returnDate: selected);
    if (_repaymentType == 'รายเดือน' &&
        !canUseMonthlyRepaymentForSelectedDate) {
      setState(() {
        _repaymentType = 'ครั้งเดียว';
      });
      _showError(
        'ไม่สามารถเลือกชำระรายเดือนได้ เมื่อวันคืนเงินอยู่ในเดือนเดียวกับวันให้กู้',
      );
    }

    setState(() {
      _returnDateController.text = ContractDateUtils.formatDate(selected);
    });
  }

  // -------------------------------------------------------------------------
  // Validators (ใช้ ContractValidators → contract_validators.dart)
  // -------------------------------------------------------------------------

  String? _validateEmail(String? value) => ContractValidators.validateEmail(
    value,
    counterpartyText: _counterpartyText,
    currentUserEmail: widget.user.email,
  );

  String? _validateAmount(String? value) =>
      ContractValidators.validateAmount(value);

  String? _validateReturnDate(String? value) =>
      ContractValidators.validateReturnDate(
        value,
        loanDateText: _loanDateController.text,
      );

  // -------------------------------------------------------------------------
  // Submit
  // -------------------------------------------------------------------------

  Future<void> _submit() async {
    if (_isSaving) return;

    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    if (!_isLender && !_isBorrower) {
      _showError('ไม่พบบทบาทที่ถูกต้อง กรุณากลับไปเลือกบทบาทใหม่');
      return;
    }

    final today = ContractDateUtils.today();
    final loanDate = ContractDateUtils.parseDate(_loanDateController.text);
    final returnDate = ContractDateUtils.parseDate(_returnDateController.text);

    if (loanDate == null) {
      _showError('ไม่พบวันให้กู้');
      return;
    }
    if (!ContractDateUtils.isSameDate(loanDate, today)) {
      _showError('วันให้กู้ต้องเป็นวันที่ปัจจุบันเท่านั้น');
      return;
    }
    if (returnDate == null) {
      _showError('กรุณาเลือกวันคืนเงิน');
      return;
    }
    if (returnDate.isBefore(today)) {
      _showError('วันคืนเงินต้องไม่เป็นวันที่ย้อนหลัง');
      return;
    }
    if (returnDate.isBefore(loanDate)) {
      _showError('วันคืนเงินต้องไม่ก่อนวันให้กู้');
      return;
    }

    if (_repaymentType == 'รายเดือน' &&
        !canUseMonthlyRepayment(loanDate: loanDate, returnDate: returnDate)) {
      _showError(
        'ไม่สามารถเลือกชำระรายเดือนได้ เมื่อวันคืนเงินอยู่ในเดือนเดียวกับวันให้กู้',
      );
      return;
    }
    final amountText = _amountController.text.trim().replaceAll(',', '');
    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      _showError('กรุณาระบุจำนวนเงินให้ถูกต้อง');
      return;
    }

    final counterpartyEmail = _counterpartyEmailController.text
        .trim()
        .toLowerCase();
    if (counterpartyEmail.isEmpty) {
      _showError('กรุณาระบุอีเมล$_counterpartyText');
      return;
    }

    if (widget.user.userId == null) {
      _showError('ไม่พบรหัสผู้ใช้ กรุณาเข้าสู่ระบบใหม่');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final contract = await _contractService.createContractByRole(
        currentUserId: widget.user.userId!,
        role: widget.role,
        counterpartyEmail: counterpartyEmail,
        amount: amount,
        loanDate: ContractDateUtils.formatDate(loanDate),
        returnDate: ContractDateUtils.formatDate(returnDate),
        repaymentType: _repaymentType,
        purpose: _emptyToNull(_purposeController.text),
        notes: _buildNotesForContract(),
        counterpartyName: _emptyToNull(_counterpartyNameController.text),
        counterpartyPhone: _emptyToNull(_counterpartyPhoneController.text),
        counterpartyIdCard: _emptyToNull(_counterpartyIdCardController.text),
        counterpartyAddress: _emptyToNull(_counterpartyAddressController.text),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('สร้างสัญญา ${contract.agreementId} สำเร็จ')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      _showError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _handlePrimaryAction() {
    if (_currentStep == 0) {
      if (!_formKey.currentState!.validate()) return;
      setState(() => _currentStep = 1);
      return;
    }
    _submit();
  }

  // -------------------------------------------------------------------------
  // Helpers
  // -------------------------------------------------------------------------

  String _buildCounterpartyNotes() {
    final details = <String, String>{
      'ชื่อ-นามสกุล': _counterpartyNameController.text.trim(),
      'เบอร์โทรศัพท์': _counterpartyPhoneController.text.trim(),
      'เลขบัตรประชาชน': _counterpartyIdCardController.text.trim(),
      'ที่อยู่': _counterpartyAddressController.text.trim(),
    };
    final filled = details.entries
        .where((e) => e.value.isNotEmpty)
        .map((e) => '${e.key}: ${e.value}')
        .join('\n');
    return filled.isEmpty ? '' : 'ข้อมูลคู่สัญญาจากแบบฟอร์ม:\n$filled';
  }

  String? _buildNotesForContract() {
    final notes = _notesController.text.trim();
    final cpNotes = _buildCounterpartyNotes();
    if (notes.isEmpty) return cpNotes.isEmpty ? null : cpNotes;
    if (cpNotes.isEmpty) return notes;
    return '$notes\n\n$cpNotes';
  }

  String? _emptyToNull(String value) {
    final text = value.trim();
    return text.isEmpty ? null : text;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final today = ContractDateUtils.today();

    return Scaffold(
      backgroundColor: AppColors.page,
      appBar: AppTheme.buildSafaAppBar(
        context,
        title: context.l10n.createContract,
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: SizedBox(
            key: _keyActionBtn,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _handlePrimaryAction,
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      _currentStep == 0
                          ? Icons.arrow_forward_rounded
                          : Icons.check_rounded,
                    ),
              label: Text(
                _isSaving
                    ? context.l10n.loading
                    : _currentStep == 0
                    ? context.l10n.continueBtn
                    : context.l10n.createContract,
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: ResponsiveBody(
          maxWidth: Responsive.formMaxWidth(context),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                Responsive.horizontalPadding(context),
                8,
                Responsive.horizontalPadding(context),
                28,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 4),
                  const Text(
                    'Safa',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'สร้างสัญญาเงินกู้',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'กรอกข้อมูลคู่สัญญาและรายละเอียดเงินกู้',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: AppColors.muted),
                  ),
                  const SizedBox(height: 22),
                  ContractProgressSteps(
                    currentStep: _currentStep,
                    stepsKey: _keySteps,
                  ),
                  const SizedBox(height: 22),
                  CounterpartyDetailsForm(
                    isLender: _isLender,
                    isSaving: _isSaving,
                    counterpartyText: _counterpartyText,
                    counterpartyLabel: _counterpartyLabel,
                    counterpartyHint: _counterpartyHint,
                    nameController: _counterpartyNameController,
                    phoneController: _counterpartyPhoneController,
                    idCardController: _counterpartyIdCardController,
                    addressController: _counterpartyAddressController,
                    emailController: _counterpartyEmailController,
                    counterpartyKey: _keyCounterparty,
                    validateEmail: _validateEmail,
                    validatePhone: ContractValidators.validateOptionalPhone,
                    validateIdCard: ContractValidators.validateOptionalIdCard,
                  ),

                  if (_currentStep == 1) ...[
                    const SizedBox(height: 22),
                    ContractDetailsForm(
                      isSaving: _isSaving,
                      amountController: _amountController,
                      loanDateController: _loanDateController,
                      returnDateController: _returnDateController,
                      purposeController: _purposeController,
                      notesController: _notesController,
                      repaymentType: _repaymentType,
                      canUseMonthlyRepayment: _monthlyRepaymentAvailable,
                      onRepaymentTypeChanged: (value) {
                        setState(() => _repaymentType = value);
                      },
                      todayFormatted: ContractDateUtils.displayDate(
                        ContractDateUtils.formatDate(today),
                      ),
                      validateAmount: _validateAmount,
                      validateReturnDate: _validateReturnDate,
                      onReturnDateTap: _selectReturnDate,
                    ),
                  ],

                  const SizedBox(height: 90),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
