import 'package:flutter/material.dart';

import '../utils/responsive.dart';
import '../widgets/responsive_container.dart';

class FinancialHealthCheckPage extends StatefulWidget {
  const FinancialHealthCheckPage({super.key});

  @override
  State<FinancialHealthCheckPage> createState() => _FinancialHealthCheckPageState();
}

class _FinancialHealthCheckPageState extends State<FinancialHealthCheckPage> {
  int _currentStep = 0;
  
  final _incomeController = TextEditingController();
  final _expenseController = TextEditingController();
  final _debtController = TextEditingController();
  final _savingsController = TextEditingController();
  bool _hasUpcomingDebt = false;
  
  bool _showResult = false;

  void _nextStep() {
    if (_currentStep < 4) {
      setState(() => _currentStep++);
    } else {
      setState(() => _showResult = true);
    }
  }

  void _prevStep() {
    if (_showResult) {
      setState(() => _showResult = false);
    } else if (_currentStep > 0) {
      setState(() => _currentStep--);
    } else {
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _incomeController.dispose();
    _expenseController.dispose();
    _debtController.dispose();
    _savingsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF101828), size: 20),
          onPressed: _prevStep,
        ),
        title: const Text(
          'เช็กสุขภาพการเงิน',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF101828),
          ),
        ),
      ),
      body: ResponsiveBody(
        maxWidth: Responsive.formMaxWidth(context),
        child: _showResult ? _buildResult() : _buildSteps(),
      ),
    );
  }

  Widget _buildSteps() {
    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            children: List.generate(5, (index) {
              final isActive = index <= _currentStep;
              return Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.only(right: index < 4 ? 8 : 0),
                  decoration: BoxDecoration(
                    color: isActive ? const Color(0xFF087443) : const Color(0xFFEAECF0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_currentStep == 0) _buildNumberInput('รายรับต่อเดือน', _incomeController, 'เช่น 15000', Icons.account_balance_wallet_outlined),
                if (_currentStep == 1) _buildNumberInput('รายจ่ายจำเป็นต่อเดือน', _expenseController, 'เช่น 8000', Icons.shopping_cart_outlined),
                if (_currentStep == 2) _buildNumberInput('ภาระหนี้ที่ต้องจ่ายต่อเดือน', _debtController, 'เช่น 2000', Icons.credit_score_outlined),
                if (_currentStep == 3) _buildNumberInput('เงินสำรองที่มีอยู่', _savingsController, 'เช่น 5000', Icons.savings_outlined),
                if (_currentStep == 4) _buildRadioSelection(),
                
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _nextStep,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF101828),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      _currentStep == 4 ? 'ดูผลการประเมิน' : 'ถัดไป',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNumberInput(String title, TextEditingController controller, String hint, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F7F1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: const Color(0xFF087443), size: 32),
        ),
        const SizedBox(height: 24),
        Text(
          title,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: Color(0xFF101828),
          ),
        ),
        const SizedBox(height: 32),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.w500),
            suffixText: 'บาท',
            suffixStyle: const TextStyle(fontSize: 18, color: Color(0xFF667085)),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFF087443), width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRadioSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFEE4E2),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.event_busy_outlined, color: Color(0xFFD92D20), size: 32),
        ),
        const SizedBox(height: 24),
        const Text(
          'คุณมีหนี้ที่กำลังจะครบกำหนดหรือไม่?',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: Color(0xFF101828),
          ),
        ),
        const SizedBox(height: 32),
        _buildRadioOption('ไม่มี', false),
        const SizedBox(height: 16),
        _buildRadioOption('มี', true),
      ],
    );
  }

  Widget _buildRadioOption(String title, bool value) {
    final isSelected = _hasUpcomingDebt == value;
    return InkWell(
      onTap: () => setState(() => _hasUpcomingDebt = value),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE8F7F1) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF087443) : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? const Color(0xFF087443) : Colors.grey.shade400,
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: const Color(0xFF101828),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResult() {
    final income = double.tryParse(_incomeController.text) ?? 0;
    final expense = double.tryParse(_expenseController.text) ?? 0;
    final debt = double.tryParse(_debtController.text) ?? 0;
    
    final remaining = income - expense - debt;
    final minEmergency = (expense + debt) * 3;
    final maxEmergency = (expense + debt) * 6;

    final isNegative = remaining < 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: Icon(Icons.bar_chart_rounded, color: Color(0xFF101828), size: 64),
          ),
          const SizedBox(height: 16),
          const Center(
            child: Text(
              'สรุปสถานะของฉัน',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Color(0xFF101828),
              ),
            ),
          ),
          const SizedBox(height: 32),
          
          // Section 1: สรุปสถานะของฉัน
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFEAECF0)),
            ),
            child: Column(
              children: [
                _buildResultRow('รายรับ', income, const Color(0xFF101828)),
                const Divider(height: 32),
                _buildResultRow('รายจ่ายจำเป็น', expense, const Color(0xFF475467)),
                const SizedBox(height: 12),
                _buildResultRow('ภาระหนี้', debt, const Color(0xFF475467)),
                const Divider(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '💰 เงินเหลือ',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF101828),
                      ),
                    ),
                    Text(
                      '${remaining < 0 ? "-" : ""}฿${remaining.abs().toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: isNegative ? const Color(0xFFD92D20) : const Color(0xFF087443),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  isNegative 
                      ? 'รายจ่ายและภาระหนี้สูงกว่ารายรับ'
                      : 'การเงินของคุณอยู่ในเกณฑ์ที่ดี',
                  style: TextStyle(
                    fontSize: 13,
                    color: isNegative ? const Color(0xFFD92D20) : const Color(0xFF087443),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Section 2: สิ่งที่ควรทำตอนนี้
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isNegative ? const Color(0xFFFFF4F3) : const Color(0xFFF6FEF9),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: isNegative ? const Color(0xFFFEE4E2) : const Color(0xFFD1FADF)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.lightbulb_outline, color: isNegative ? const Color(0xFFD92D20) : const Color(0xFF087443), size: 24),
                    const SizedBox(width: 12),
                    Text(
                      'แนะนำสำหรับคุณ',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: isNegative ? const Color(0xFFB42318) : const Color(0xFF05603A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  isNegative 
                      ? 'ตอนนี้ควรหลีกเลี่ยงการก่อหนี้เพิ่ม และลองทบทวนรายจ่ายที่ไม่จำเป็น'
                      : 'คุณบริหารจัดการเงินได้ดี นำเงินส่วนที่เหลือไปออมเป็นเงินสำรองฉุกเฉิน หรือลงทุนเพื่ออนาคต',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF344054),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'เริ่มจาก',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF101828),
                  ),
                ),
                const SizedBox(height: 8),
                _buildActionItem(isNegative ? 'ลดรายจ่ายที่ไม่จำเป็น' : 'สะสมเงินสำรองฉุกเฉิน'),
                _buildActionItem(isNegative ? 'วางแผนชำระหนี้' : 'รักษาพฤติกรรมการใช้จ่าย'),
                _buildActionItem(isNegative ? 'พยายามสร้างเงินสำรองทีละน้อย' : 'วางแผนเป้าหมายการเงินต่อไป'),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Section 3: เงินสำรองฉุกเฉิน
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF101828),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Text(
                      '🐷',
                      style: TextStyle(fontSize: 24),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'เงินสำรองฉุกเฉิน',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'เงินสำรองที่แนะนำสำหรับคุณ',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFFD0D5DD),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '฿${minEmergency.toStringAsFixed(0)} – ฿${maxEmergency.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF32D583),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'คำนวณจากประมาณ 3–6 เท่า\nของค่าใช้จ่ายจำเป็นและภาระผ่อนหนี้ต่อเดือน',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF98A2B3),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'เริ่มออมทีละน้อยก็ได้',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF101828),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Color(0xFFEAECF0)),
                ),
                elevation: 0,
              ),
              child: const Text(
                'กลับหน้าความรู้',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check, size: 18, color: Color(0xFF087443)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF344054),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultRow(String label, double amount, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF475467),
          ),
        ),
        Text(
          '฿${amount.toStringAsFixed(0)}',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
