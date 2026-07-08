import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MentorLoginController extends ChangeNotifier {
  static const _lastPhoneKey = 'mentor_last_phone';

  String _phone = '';
  String _pin = '';
  int _phoneFieldVersion = 0;

  String get phone => _phone;
  String get pin => _pin;
  int get phoneFieldVersion => _phoneFieldVersion;

  bool get phoneIsValid =>
      _phone.length == 10 && _phone.startsWith('0') && _digitsOnly(_phone);

  bool get pinIsValid => _pin.length == 6 && _digitsOnly(_pin);

  bool get canSubmit => phoneIsValid && pinIsValid;

  Future<void> loadLastPhone() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPhone = prefs.getString(_lastPhoneKey);

    if (savedPhone == null || savedPhone == _phone) return;

    _phone = savedPhone;
    _phoneFieldVersion++;
    notifyListeners();
  }

  Future<void> saveLastPhone() async {
    if (!phoneIsValid) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastPhoneKey, _phone);
  }

  Future<void> clearPhone() async {
    _phone = '';
    _pin = '';
    _phoneFieldVersion++;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastPhoneKey);

    notifyListeners();
  }

  void setPhone(String value) {
    final normalized = _normalizeDigits(value, maxLength: 10);
    if (normalized == _phone) return;

    _phone = normalized;

    if (!phoneIsValid) {
      _pin = '';
    }

    notifyListeners();
  }

  void setPin(String value) {
    final normalized = _normalizeDigits(value, maxLength: 6);
    if (normalized == _pin) return;

    _pin = normalized;
    notifyListeners();
  }

  void resetPin() {
    if (_pin.isEmpty) return;

    _pin = '';
    notifyListeners();
  }

  static String _normalizeDigits(String value, {required int maxLength}) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    return digits.length <= maxLength ? digits : digits.substring(0, maxLength);
  }

  static bool _digitsOnly(String value) {
    return RegExp(r'^\d+$').hasMatch(value);
  }
}