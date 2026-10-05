import 'package:flutter_test/flutter_test.dart';
import 'package:safa_qard/widgets/create_contract/contract_validators.dart';

void main() {
  group('optional phone validation', () {
    test('allows an empty value', () {
      expect(ContractValidators.validateOptionalPhone(''), isNull);
      expect(ContractValidators.validateOptionalPhone('   '), isNull);
    });

    test('requires exactly 10 digits when provided', () {
      expect(ContractValidators.validateOptionalPhone('0812345678'), isNull);
      expect(
        ContractValidators.validateOptionalPhone('081234567'),
        'กรุณากรอกข้อมูลให้ถูกต้อง',
      );
    });
  });

  group('optional ID card validation', () {
    test('allows an empty value', () {
      expect(ContractValidators.validateOptionalIdCard(''), isNull);
      expect(ContractValidators.validateOptionalIdCard('   '), isNull);
    });

    test('requires exactly 13 digits when provided', () {
      expect(ContractValidators.validateOptionalIdCard('1234567890123'), isNull);
      expect(
        ContractValidators.validateOptionalIdCard('123456789012'),
        'กรุณากรอกข้อมูลให้ถูกต้อง',
      );
    });
  });
}