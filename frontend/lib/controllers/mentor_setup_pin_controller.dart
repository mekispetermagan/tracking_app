import 'package:flutter/foundation.dart';

import '../validation/credential_validation.dart' show isValidPin;

class MentorSetupPinController extends ChangeNotifier {
  String _pin = '';
  String _confirmPin = '';

  String get pin => _pin;
  String get confirmPin => _confirmPin;

  bool get pinIsValid => isValidPin(_pin);
  bool get confirmPinIsValid => isValidPin(_confirmPin);
  bool get pinsMatch => _pin == _confirmPin;

  bool get canSubmit => pinIsValid && confirmPinIsValid && pinsMatch;

  void setPin(String value) {
    final normalized = _normalizePin(value);
    if (normalized == _pin) return;

    _pin = normalized;
    notifyListeners();
  }

  void setConfirmPin(String value) {
    final normalized = _normalizePin(value);
    if (normalized == _confirmPin) return;

    _confirmPin = normalized;
    notifyListeners();
  }

  void reset() {
    if (_pin.isEmpty && _confirmPin.isEmpty) return;

    _pin = '';
    _confirmPin = '';
    notifyListeners();
  }

  static String _normalizePin(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    return digits.length <= 6 ? digits : digits.substring(0, 6);
  }
}
