import 'package:flutter/material.dart';

class HealthCheckResult extends StatelessWidget {
  final double income;
  final double expense;
  final double debt;
  final bool hasUpcomingDebt;
  final VoidCallback onBackButtonPressed;

  const HealthCheckResult({
    super.key,
    required this.income,
    required this.expense,
    required this.debt,
    required this.hasUpcomingDebt,
    required this.onBackButtonPressed,
  });

  @override
  Widget build(BuildContext context) {
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
              onPressed: onBackButtonPressed,
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
