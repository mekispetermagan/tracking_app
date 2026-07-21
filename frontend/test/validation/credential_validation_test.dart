import 'package:flutter_test/flutter_test.dart';
import 'package:agu_frontend/validation/credential_validation.dart';

void main() {
  test('phone validation requires ten digits starting with zero', () {
    expect(isValidPhone('0700123456'), isTrue);
    expect(isValidPhone('1700123456'), isFalse);
    expect(isValidPhone('070012345'), isFalse);
    expect(isValidPhone('07001a3456'), isFalse);
  });

  test('PIN validation requires exactly six digits', () {
    expect(isValidPin('123456'), isTrue);
    expect(isValidPin('12345'), isFalse);
    expect(isValidPin('12345a'), isFalse);
  });

  test('password validation enforces only the documented minimum length', () {
    expect(isValidPassword('123456'), isTrue);
    expect(isValidPassword('12345'), isFalse);
    expect(isValidPassword('      '), isTrue);
  });
}
