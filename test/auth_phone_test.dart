import 'package:flutter_test/flutter_test.dart';
import 'package:pocho_new/utils/phone_number_utils.dart';
import 'package:pocho_new/models/auth/send_code_request.dart';
import 'package:pocho_new/models/auth/check_registration_request.dart';

void main() {
  group('PhoneNumberUtils', () {
    test('normalizes digits-only local number', () {
      expect(PhoneNumberUtils.normalizeUzbek('901234567'), '+998901234567');
    });

    test('normalizes with spaces and dashes', () {
      expect(
        PhoneNumberUtils.normalizeUzbek('90 123-45-67'),
        '+998901234567',
      );
    });

    test('accepts full E.164', () {
      expect(
        PhoneNumberUtils.normalizeUzbek('+998901234567'),
        '+998901234567',
      );
    });

    test('accepts 998 without plus', () {
      expect(
        PhoneNumberUtils.normalizeUzbek('998901234567'),
        '+998901234567',
      );
    });

    test('rejects short numbers', () {
      expect(PhoneNumberUtils.normalizeUzbek('90123'), isNull);
      expect(PhoneNumberUtils.isValidUzbek('90123'), isFalse);
    });

    test('rejects empty', () {
      expect(PhoneNumberUtils.normalizeUzbek(''), isNull);
      expect(PhoneNumberUtils.normalizeUzbek(null), isNull);
    });
  });

  group('Auth request bodies', () {
    test('SendCodeRequest uses phone_number field', () {
      final json = SendCodeRequest(phone: '+998901234567').toJson();
      expect(json, {'phone_number': '+998901234567'});
    });

    test('CheckRegistrationRequest uses phone_number field', () {
      final json = CheckRegistrationRequest(phone: '+998901234567').toJson();
      expect(json, {'phone_number': '+998901234567'});
    });
  });
}
