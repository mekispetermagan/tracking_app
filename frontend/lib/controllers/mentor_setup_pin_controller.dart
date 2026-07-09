import 'package:flutter/foundation.dart';

class MentorSetupPinController extends ChangeNotifier {
  String _pin = '';
  String _confirmPin = '';

  String get pin => _pin;
  String get confirmPin => _confirmPin;

  bool get pinIsValid => _isSixDigits(_pin);
  bool get confirmPinIsValid => _isSixDigits(_confirmPin);
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

  static bool _isSixDigits(String value) {
    return RegExp(r'^\d{6}$').hasMatch(value);
  }
}