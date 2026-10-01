import 'package:flutter/material.dart';

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

  const CreateContractPage({super.key, required this.user, required this.role});

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

  // -------------------------------------------------------------------------
  // Lifecycle
  // -------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    // วันให้กู้/วันเริ่มสัญญาเป็นวันนี้เท่านั้น
    _loanDateController.text = ContractDateUtils.formatDate(ContractDateUtils.today());
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
    final seen = await OnboardingService.instance
        .hasSeenOnboarding(OnboardingService.keyCreateContract);
    if (!mounted || seen) return;
    await OnboardingService.instance.markAsSeen(OnboardingService.keyCreateContract);
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
          spotlightPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
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

<<<<<<< HEAD
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

  // ==========================================================
  // DATE
  // ==========================================================

  DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool get _canUseMonthlyRepayment {
    final loanDate = _parseDate(_loanDateController.text);
    final returnDate = _parseDate(_returnDateController.text);

    if (loanDate == null || returnDate == null) {
      return true;
    }

    return canUseMonthlyRepayment(loanDate: loanDate, returnDate: returnDate);
  }

  String _formatDate(DateTime date) {
    final value = _dateOnly(date);
    return '${value.year.toString().padLeft(4, '0')}-'
        '${value.month.toString().padLeft(2, '0')}-'
        '${value.day.toString().padLeft(2, '0')}';
  }

  DateTime? _parseDate(String value) {
    final text = value.trim();
    if (text.isEmpty) return null;

    try {
      return _dateOnly(DateTime.parse(text));
    } catch (_) {
      return null;
    }
  }

  String _displayDate(String value) {
    final date = _parseDate(value);
    return date == null ? '' : _displayDateFormat.format(date);
  }
=======
  // -------------------------------------------------------------------------
  // Date Picker (ใช้ ContractDateUtils → contract_date_utils.dart)
  // -------------------------------------------------------------------------
>>>>>>> 274f8123b4db71dacc04a21caab381247f7f7fb1

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
      helpText: 'เลือกวันคืนเงิน',
      cancelText: 'ยกเลิก',
      confirmText: 'ยืนยัน',
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

    if (_repaymentType == 'รายเดือน' &&
        loanDate != null &&
        !canUseMonthlyRepayment(loanDate: loanDate, returnDate: selected)) {
      setState(() {
        _repaymentType = 'ครั้งเดียว';
      });
      _showError(
        'ไม่สามารถเลือกชำระรายเดือนได้ เมื่อวันคืนเงินอยู่ในเดือนเดียวกับวันให้กู้',
      );
    }

    setState(() {
      _returnDateController.text = ContractDateUtils.formatDate(selected);
      
      // คำนวณรูปแบบการชำระเงินอัตโนมัติ
      final loanDateVal = loanDate ?? today;
      final diffDays = selected.difference(loanDateVal).inDays;
      if (diffDays >= 30) {
        _repaymentType = 'รายเดือน';
      } else {
        _repaymentType = 'ครั้งเดียว';
      }
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

    if (loanDate == null) { _showError('ไม่พบวันให้กู้'); return; }
    if (!ContractDateUtils.isSameDate(loanDate, today)) {
      _showError('วันให้กู้ต้องเป็นวันที่ปัจจุบันเท่านั้น');
      return;
    }
    if (returnDate == null) { _showError('กรุณาเลือกวันคืนเงิน'); return; }
    if (returnDate.isBefore(today)) {
      _showError('วันคืนเงินต้องไม่เป็นวันที่ย้อนหลัง');
      return;
    }
    if (returnDate.isBefore(loanDate)) {
      _showError('วันคืนเงินต้องไม่ก่อนวันให้กู้');
      return;
    }

<<<<<<< HEAD
    if (_repaymentType == 'รายเดือน' &&
        !canUseMonthlyRepayment(loanDate: loanDate, returnDate: returnDate)) {
      _showError(
        'ไม่สามารถเลือกชำระรายเดือนได้ เมื่อวันคืนเงินอยู่ในเดือนเดียวกับวันให้กู้',
      );
      return;
    }

    // --------------------------------------------------------
    // ตรวจจำนวนเงิน
    // --------------------------------------------------------
=======
>>>>>>> 274f8123b4db71dacc04a21caab381247f7f7fb1
    final amountText = _amountController.text.trim().replaceAll(',', '');
    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      _showError('กรุณาระบุจำนวนเงินให้ถูกต้อง');
      return;
    }

    final counterpartyEmail = _counterpartyEmailController.text.trim().toLowerCase();
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

<<<<<<< HEAD
  // ==========================================================
  // UI HELPERS
  // ==========================================================

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Color(0xff233044),
      ),
    );
  }

  InputDecoration _fieldDecoration(String hint, {String? label}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xff9aa2ad), fontSize: 13),
      labelStyle: const TextStyle(color: Color(0xff354052), fontSize: 12),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xffaeb6c2)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xffaeb6c2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
      ),
    );
  }

  Widget _buildProgressSteps() {
    final labels = ['ข้อมูลของคุณ', 'รายละเอียดเงินกู้', 'ตรวจสอบ'];

    return Row(
      key: _keySteps,
      children: List.generate(labels.length, (index) {
        final isActive = index == _currentStep;
        final isComplete = index < _currentStep;
        return Expanded(
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isActive || isComplete
                      ? AppColors.primary
                      : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isActive || isComplete
                        ? AppColors.primary
                        : const Color(0xffd7dee5),
                  ),
                ),
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isActive || isComplete
                        ? Colors.white
                        : const Color(0xff8c98a7),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  labels[index],
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    color: isActive || isComplete
                        ? AppColors.primary
                        : const Color(0xff778392),
                    fontWeight: isActive || isComplete
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),
              if (index < labels.length - 1)
                Expanded(
                  child: Container(
                    height: 1,
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    color: const Color(0xffd7dee5),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildCounterpartyDetails() {
    final isLender = _isLender;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xffe2e7eb)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 3, height: 18, color: const Color(0xfff3a43b)),
              const SizedBox(width: 7),
              Text(
                'ข้อมูลคู่สัญญา - $_counterpartyText',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          TextFormField(
            controller: _counterpartyNameController,
            enabled: !_isSaving,
            textInputAction: TextInputAction.next,
            decoration: _fieldDecoration(
              'ระบุชื่อ-นามสกุล',
              label: 'ชื่อ-นามสกุล',
            ),
          ),
          const SizedBox(height: 11),
          TextFormField(
            controller: _counterpartyPhoneController,
            enabled: !_isSaving,
            keyboardType: TextInputType.phone,
            maxLength: 10,
            textInputAction: TextInputAction.next,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            decoration: _fieldDecoration(
              'กรอก 10 หลัก เช่น 0812345678',
              label: 'เบอร์โทรศัพท์',
            ).copyWith(counterText: ''),
          ),
          const SizedBox(height: 11),
          TextFormField(
            controller: _counterpartyIdCardController,
            enabled: !_isSaving,
            keyboardType: TextInputType.number,
            maxLength: 13,
            textInputAction: TextInputAction.next,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(13),
            ],
            decoration: _fieldDecoration(
              'กรอก 13 หลัก',
              label: isLender ? 'เลขบัตรประชาชน (ผู้กู้)' : 'เลขบัตรประชาชน',
            ).copyWith(counterText: ''),
          ),
          if (isLender) ...[
            const SizedBox(height: 11),
            TextFormField(
              controller: _counterpartyAddressController,
              enabled: !_isSaving,
              maxLines: 2,
              decoration: _fieldDecoration(
                'บ้านเลขที่, หมู่, ซอย, ถนน, ตำบล/แขวง, อำเภอ/เขต, จังหวัด, รหัสไปรษณีย์',
                label: 'ที่อยู่ตามทะเบียนบ้าน',
              ),
            ),

          ] else ...[
            const SizedBox(height: 11),
            TextFormField(
              controller: _counterpartyAddressController,
              enabled: !_isSaving,
              maxLines: 2,
              decoration: _fieldDecoration(
                'บ้านเลขที่, หมู่, ซอย, ถนน, ตำบล/แขวง, อำเภอ/เขต, จังหวัด, รหัสไปรษณีย์',
                label: 'ที่อยู่ (ผู้ให้กู้)',
              ),
            ),
          ],
          const SizedBox(height: 11),
          TextFormField(
            key: _keyCounterparty,
            controller: _counterpartyEmailController,
            enabled: !_isSaving,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: _fieldDecoration(
              _counterpartyHint,
              label: '$_counterpartyLabel ',
            ),
            validator: _validateEmail,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.info_outline,
                size: 15,
                color: AppColors.primary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'หากคู่สัญญายังไม่ได้สมัครในระบบ ระบบจะสร้างบัญชีชั่วคราวให้อัตโนมัติ',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.primary,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateRuleCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xffcde9df)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'เงื่อนไขวันที่: วันให้กู้ถูกกำหนดเป็นวันนี้เท่านั้นและแก้ไขไม่ได้ ส่วนวันคืนเงินเลือกได้ตั้งแต่วันนี้เป็นต้นไป และไม่สามารถเลือกวันที่ย้อนหลังได้ หากวันคืนเงินอยู่ในเดือนเดียวกับวันให้กู้ จะไม่สามารถเลือก “ชำระรายเดือน” ได้',
              style: const TextStyle(
                color: Color(0xff176b5b),
                height: 1.5,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // BUILD
  // ==========================================================
=======
  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------
>>>>>>> 274f8123b4db71dacc04a21caab381247f7f7fb1

  @override
  Widget build(BuildContext context) {
    final today = ContractDateUtils.today();

    return Scaffold(
      backgroundColor: AppColors.page,
      appBar: AppTheme.buildSafaAppBar(context, title: 'สร้างสัญญา'),
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
                    ? 'กำลังดำเนินการ...'
                    : _currentStep == 0
                    ? 'ดำเนินการต่อ'
                    : 'สร้างสัญญา',
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
                Responsive.horizontalPadding(context), 8,
                Responsive.horizontalPadding(context), 28,
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
<<<<<<< HEAD

                  _buildSectionTitle('รูปแบบการชำระเงิน'),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _repaymentType,
                    decoration: const InputDecoration(
                      labelText: 'รูปแบบการชำระเงิน',
                      prefixIcon: Icon(Icons.payments_outlined),
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: 'ครั้งเดียว',
                        child: Text('ชำระครั้งเดียว'),
                      ),
                      DropdownMenuItem(
                        value: 'รายเดือน',
                        enabled: _canUseMonthlyRepayment,
                        child: const Text('ชำระรายเดือน'),
                      ),
                    ],
                    onChanged: _isSaving
                        ? null
                        : (value) {
                            if (value == null) return;
                            setState(() {
                              _repaymentType = value;
                            });
                          },
=======
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
>>>>>>> 274f8123b4db71dacc04a21caab381247f7f7fb1
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
