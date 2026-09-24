import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../models/user.dart';
import '../services/contract_service.dart';
import '../theme/app_theme.dart';

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

  final DateFormat _displayDateFormat = DateFormat('dd/MM/yyyy');

  bool _isSaving = false;
  int _currentStep = 0;
  String _repaymentType = 'ครั้งเดียว';

  bool get _isLender => widget.role == 'lender';
  bool get _isBorrower => widget.role == 'borrower';

  String get _counterpartyText => _isLender ? 'ผู้กู้' : 'ผู้ให้กู้';

  String get _counterpartyLabel => _isLender ? 'อีเมลผู้กู้' : 'อีเมลผู้ให้กู้';

  String get _counterpartyHint =>
      _isLender ? 'กรอกอีเมลของผู้กู้' : 'กรอกอีเมลของผู้ให้กู้';

  @override
  void initState() {
    super.initState();

    // วันให้กู้/วันเริ่มสัญญาเป็นวันนี้เท่านั้น
    _loanDateController.text = _formatDate(_today());
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

  Future<void> _selectReturnDate() async {
    if (_isSaving) return;

    final today = _today();
    final current = _parseDate(_returnDateController.text);

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

    final selected = _dateOnly(selectedDate);
    final loanDate = _parseDate(_loanDateController.text);

    // ตรวจซ้ำทั้งฝั่ง UI และ logic ก่อนเก็บข้อมูล
    if (selected.isBefore(today)) {
      _showError('วันคืนเงินต้องไม่เป็นวันที่ย้อนหลัง');
      return;
    }

    if (loanDate != null && selected.isBefore(loanDate)) {
      _showError('วันคืนเงินต้องไม่ก่อนวันให้กู้');
      return;
    }

    setState(() {
      _returnDateController.text = _formatDate(selected);
    });
  }

  // ==========================================================
  // VALIDATION
  // ==========================================================

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';

    if (email.isEmpty) return 'กรุณาระบุอีเมล$_counterpartyText';

    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(email)) {
      return 'รูปแบบอีเมลไม่ถูกต้อง';
    }

    if (widget.user.email.trim().toLowerCase() == email.toLowerCase()) {
      return 'ไม่สามารถสร้างสัญญากับตัวเองได้';
    }

    return null;
  }

  String? _validateAmount(String? value) {
    final text = value?.trim().replaceAll(',', '') ?? '';

    if (text.isEmpty) return 'กรุณาระบุจำนวนเงิน';

    final amount = double.tryParse(text);
    if (amount == null) return 'กรุณาระบุจำนวนเงินเป็นตัวเลข';
    if (amount <= 0) return 'จำนวนเงินต้องมากกว่า 0';

    return null;
  }

  String? _validateReturnDate(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'กรุณาเลือกวันคืนเงิน';

    final selected = _parseDate(text);
    if (selected == null) return 'รูปแบบวันที่ไม่ถูกต้อง';

    final today = _today();
    if (selected.isBefore(today)) {
      return 'วันคืนเงินต้องไม่เป็นวันที่ย้อนหลัง';
    }

    final loanDate = _parseDate(_loanDateController.text);
    if (loanDate != null && selected.isBefore(loanDate)) {
      return 'วันคืนเงินต้องไม่ก่อนวันให้กู้';
    }

    return null;
  }

  // ==========================================================
  // SUBMIT
  // ==========================================================

  Future<void> _submit() async {
    if (_isSaving) return;

    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    // role ต้องเป็นค่าที่ระบบรองรับเท่านั้น
    if (!_isLender && !_isBorrower) {
      _showError('ไม่พบบทบาทที่ถูกต้อง กรุณากลับไปเลือกบทบาทใหม่');
      return;
    }

    // --------------------------------------------------------
    // ตรวจวันที่อีกครั้งก่อนบันทึกจริง
    // --------------------------------------------------------
    final today = _today();
    final loanDate = _parseDate(_loanDateController.text);
    final returnDate = _parseDate(_returnDateController.text);

    if (loanDate == null) {
      _showError('ไม่พบวันให้กู้');
      return;
    }

    if (!_isSameDate(loanDate, today)) {
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

    // --------------------------------------------------------
    // ตรวจจำนวนเงิน
    // --------------------------------------------------------
    final amountText = _amountController.text.trim().replaceAll(',', '');
    final amount = double.tryParse(amountText);

    if (amount == null || amount <= 0) {
      _showError('กรุณาระบุจำนวนเงินให้ถูกต้อง');
      return;
    }

    // --------------------------------------------------------
    // ตรวจอีเมลคู่สัญญา
    // --------------------------------------------------------
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

    setState(() {
      _isSaving = true;
    });

    try {
      final contract = await _contractService.createContractByRole(
        currentUserId: widget.user.userId!,
        role: widget.role,
        counterpartyEmail: counterpartyEmail,
        amount: amount,
        loanDate: _formatDate(loanDate),
        returnDate: _formatDate(returnDate),
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

      // ส่ง true กลับไปให้หน้าก่อนหน้ารู้ว่ามีการสร้างสัญญาสำเร็จ
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      _showError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
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

  String _buildCounterpartyNotes() {
    final details = <String, String>{
      'ชื่อ-นามสกุล': _counterpartyNameController.text.trim(),
      'เบอร์โทรศัพท์': _counterpartyPhoneController.text.trim(),
      'เลขบัตรประชาชน': _counterpartyIdCardController.text.trim(),
      'ที่อยู่': _counterpartyAddressController.text.trim(),
    };
    final filled = details.entries
        .where((entry) => entry.value.isNotEmpty)
        .map((entry) => '${entry.key}: ${entry.value}')
        .join('\n');
    return filled.isEmpty ? '' : 'ข้อมูลคู่สัญญาจากแบบฟอร์ม:\n$filled';
  }

  String? _buildNotesForContract() {
    final notes = _notesController.text.trim();
    final counterpartyNotes = _buildCounterpartyNotes();
    if (notes.isEmpty) {
      return counterpartyNotes.isEmpty ? null : counterpartyNotes;
    }
    if (counterpartyNotes.isEmpty) return notes;
    return '$notes\n\n$counterpartyNotes';
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
            Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 16,
                  color: AppColors.muted,
                ),
                const SizedBox(width: 7),
                const Expanded(
                  child: Text(
                    'กรอกที่อยู่ที่ต้องการแสดงในสัญญา',
                    style: TextStyle(fontSize: 11, color: AppColors.muted),
                  ),
                ),
              ],
            ),
            TextFormField(
              enabled: !_isSaving,
              maxLines: 2,
              decoration: _fieldDecoration(
                'ระบุที่อยู่ที่ต้องการแสดงในสัญญา',
                label: 'ที่อยู่สำหรับสัญญา',
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
            controller: _counterpartyEmailController,
            enabled: !_isSaving,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: _fieldDecoration(
              _counterpartyHint,
              label: '$_counterpartyLabel (ไม่ต้องมีในระบบก็ได้)',
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
              'เงื่อนไขวันที่: วันให้กู้ถูกกำหนดเป็นวันนี้เท่านั้นและแก้ไขไม่ได้ ส่วนวันคืนเงินเลือกได้ตั้งแต่วันนี้เป็นต้นไป และไม่สามารถเลือกวันที่ย้อนหลังได้',
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

  @override
  Widget build(BuildContext context) {
    final today = _today();

    return Scaffold(
      backgroundColor: AppColors.page,
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'ย้อนกลับ',
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text('สร้างสัญญา'),
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
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
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
                _buildProgressSteps(),
                const SizedBox(height: 22),
                _buildCounterpartyDetails(),

                if (_currentStep == 1) ...[
                  const SizedBox(height: 22),

                  // ------------------------------------------------------
                  // ข้อมูลสัญญา: เหมือนกันทั้ง 2 role
                  // ------------------------------------------------------
                  _buildSectionTitle('ข้อมูลสัญญา'),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    textInputAction: TextInputAction.next,
                    enabled: !_isSaving,
                    decoration: const InputDecoration(
                      labelText: 'จำนวนเงิน',
                      hintText: 'เช่น 10000',
                      prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                      suffixText: 'บาท',
                      border: OutlineInputBorder(),
                    ),
                    validator: _validateAmount,
                  ),

                  const SizedBox(height: 16),

                  // วันให้กู้ = วันนี้เท่านั้น และปิดการกดทั้งหมด
                  TextFormField(
                    controller: _loanDateController,
                    readOnly: true,
                    enabled: false,
                    decoration: InputDecoration(
                      labelText: 'วันให้กู้',
                      helperText:
                          'กำหนดเป็นวันที่ปัจจุบันเท่านั้น และแก้ไขไม่ได้',
                      helperMaxLines: 2,
                      prefixIcon: const Icon(Icons.calendar_today_outlined),
                      border: const OutlineInputBorder(),
                      disabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey.shade400),
                      ),
                    ),
                  ),

                  const SizedBox(height: 7),
                  Text(
                    'วันนี้คือ ${_displayDate(_formatDate(today))}',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),

                  const SizedBox(height: 16),

                  // วันคืนเงิน: เปิดปฏิทิน แต่ปฏิทินล็อกวันที่ย้อนหลัง
                  TextFormField(
                    controller: _returnDateController,
                    readOnly: true,
                    enabled: !_isSaving,
                    onTap: _isSaving ? null : _selectReturnDate,
                    decoration: const InputDecoration(
                      labelText: 'วันคืนเงิน',
                      hintText: 'เลือกวันคืนเงิน',
                      helperText: 'เลือกได้ตั้งแต่วันนี้เป็นต้นไป',
                      prefixIcon: Icon(Icons.event_available_outlined),
                      suffixIcon: Icon(Icons.calendar_month_outlined),
                      border: OutlineInputBorder(),
                    ),
                    validator: _validateReturnDate,
                  ),

                  const SizedBox(height: 22),

                  _buildSectionTitle('รูปแบบการชำระเงิน'),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _repaymentType,
                    decoration: const InputDecoration(
                      labelText: 'รูปแบบการชำระเงิน',
                      prefixIcon: Icon(Icons.payments_outlined),
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'ครั้งเดียว',
                        child: Text('ชำระครั้งเดียว'),
                      ),
                      DropdownMenuItem(
                        value: 'รายเดือน',
                        child: Text('ชำระรายเดือน'),
                      ),
                      DropdownMenuItem(
                        value: 'รายสัปดาห์',
                        child: Text('ชำระรายสัปดาห์'),
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
                  ),

                  const SizedBox(height: 22),

                  _buildSectionTitle('รายละเอียดเพิ่มเติม'),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _purposeController,
                    enabled: !_isSaving,
                    maxLines: 2,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'วัตถุประสงค์การกู้',
                      hintText: 'ระบุวัตถุประสงค์ เช่น ค่าใช้จ่ายส่วนตัว',
                      prefixIcon: Icon(Icons.assignment_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _notesController,
                    enabled: !_isSaving,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'หมายเหตุ',
                      hintText: 'รายละเอียดเพิ่มเติม',
                      prefixIcon: Icon(Icons.notes_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 24),
                  _buildDateRuleCard(),
                  const SizedBox(height: 24),
                ],

                const SizedBox(height: 90),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
