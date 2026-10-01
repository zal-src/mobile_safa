import 'package:flutter/material.dart';

import '../utils/responsive.dart';
import '../widgets/responsive_container.dart';
import '../theme/app_theme.dart';
import '../widgets/financial_health_check/health_check_inputs.dart';
import '../widgets/financial_health_check/health_check_result.dart';

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
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: const Color(0xFFE4E7EC), height: 1.0),
        ),
        automaticallyImplyLeading: false,
        leading: IconButton(
          tooltip: 'ย้อนกลับ',
          icon: const Icon(Icons.arrow_back_ios_new,
              color: AppColors.ink, size: 20),
          onPressed: _prevStep,
        ),
        leadingWidth: 48,
        title: const Text(
          'เช็กสุขภาพการเงิน',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
      ),
      body: ResponsiveBody(
        maxWidth: Responsive.formMaxWidth(context),
        child: _showResult ? _buildResultView() : _buildStepsView(),
      ),
    );
  }

  Widget _buildStepsView() {
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
                if (_currentStep == 0) 
                  HealthCheckNumberInput(
                    title: 'รายรับต่อเดือน', 
                    controller: _incomeController, 
                    hint: 'เช่น 15000', 
                    icon: Icons.account_balance_wallet_outlined
                  ),
                if (_currentStep == 1) 
                  HealthCheckNumberInput(
                    title: 'รายจ่ายจำเป็นต่อเดือน', 
                    controller: _expenseController, 
                    hint: 'เช่น 8000', 
                    icon: Icons.shopping_cart_outlined
                  ),
                if (_currentStep == 2) 
                  HealthCheckNumberInput(
                    title: 'ภาระหนี้ที่ต้องจ่ายต่อเดือน', 
                    controller: _debtController, 
                    hint: 'เช่น 2000', 
                    icon: Icons.credit_score_outlined
                  ),
                if (_currentStep == 3) 
                  HealthCheckNumberInput(
                    title: 'เงินสำรองที่มีอยู่', 
                    controller: _savingsController, 
                    hint: 'เช่น 5000', 
                    icon: Icons.savings_outlined
                  ),
                if (_currentStep == 4) 
                  HealthCheckRadioSelection(
                    hasUpcomingDebt: _hasUpcomingDebt, 
                    onChanged: (value) => setState(() => _hasUpcomingDebt = value),
                  ),
                
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

  Widget _buildResultView() {
    return HealthCheckResult(
      income: double.tryParse(_incomeController.text) ?? 0,
      expense: double.tryParse(_expenseController.text) ?? 0,
      debt: double.tryParse(_debtController.text) ?? 0,
      hasUpcomingDebt: _hasUpcomingDebt,
      onBackButtonPressed: () => Navigator.pop(context),
    );
  }
}
