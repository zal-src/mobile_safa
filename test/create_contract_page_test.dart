import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safa_qard/screens/create_contract_page.dart';
import 'package:safa_qard/widgets/create_contract/counterparty_details_form.dart';

void main() {
  testWidgets('lender form only shows the registered address', (tester) async {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final idCardController = TextEditingController();
    final addressController = TextEditingController();
    final emailController = TextEditingController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: CounterpartyDetailsForm(
              isLender: true,
              isSaving: false,
              counterpartyText: 'ผู้กู้',
              counterpartyLabel: 'อีเมลผู้กู้',
              counterpartyHint: 'กรอกอีเมลของผู้กู้',
              nameController: nameController,
              phoneController: phoneController,
              idCardController: idCardController,
              addressController: addressController,
              emailController: emailController,
              validateEmail: (_) => null,
              validatePhone: (_) => null,
              validateIdCard: (_) => null,
            ),
          ),
        ),
      ),
    );

    expect(find.text('ที่อยู่ตามทะเบียนบ้าน'), findsOneWidget);
    expect(find.text('ที่อยู่สำหรับสัญญา'), findsNothing);
  });

  group('canUseMonthlyRepayment', () {
    test('disallows monthly repayment in the same month', () {
      expect(
        canUseMonthlyRepayment(
          loanDate: DateTime(2026, 10, 4),
          returnDate: DateTime(2026, 10, 31),
        ),
        isFalse,
      );
    });

    test('allows monthly repayment in a different month', () {
      expect(
        canUseMonthlyRepayment(
          loanDate: DateTime(2026, 10, 4),
          returnDate: DateTime(2026, 11, 1),
        ),
        isTrue,
      );
    });

    test('allows monthly repayment across years', () {
      expect(
        canUseMonthlyRepayment(
          loanDate: DateTime(2026, 12, 31),
          returnDate: DateTime(2027, 1, 1),
        ),
        isTrue,
      );
    });
  });
}
