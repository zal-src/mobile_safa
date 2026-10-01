import 'package:flutter_test/flutter_test.dart';
import 'package:safa_qard/screens/create_contract_page.dart';
import 'package:safa_qard/services/repayment_service.dart';

void main() {
  test('monthly repayment is blocked when return date is in the same month as the loan date', () {
    final loanDate = DateTime(2026, 10, 1);
    final sameMonthReturnDate = DateTime(2026, 10, 20);
    final nextMonthReturnDate = DateTime(2026, 11, 5);

    expect(canUseMonthlyRepayment(loanDate: loanDate, returnDate: sameMonthReturnDate), isFalse);
    expect(canUseMonthlyRepayment(loanDate: loanDate, returnDate: nextMonthReturnDate), isTrue);
  });

  test('installment count follows the month span between loan and return dates', () {
    expect(
      RepaymentService.calculateInstallmentCount(
        loanDate: DateTime(2026, 10, 10),
        returnDate: DateTime(2026, 10, 20),
      ),
      1,
    );

    expect(
      RepaymentService.calculateInstallmentCount(
        loanDate: DateTime(2026, 10, 10),
        returnDate: DateTime(2026, 12, 5),
      ),
      3,
    );

    expect(
      RepaymentService.calculateInstallmentCount(
        loanDate: DateTime(2026, 10, 10),
        returnDate: DateTime(2027, 1, 15),
      ),
      4,
    );
  });
}
