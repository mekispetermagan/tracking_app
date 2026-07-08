import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdminLoginController extends ChangeNotifier {
  static const _lastPhoneKey = 'admin_last_phone';

  String _phone = '';
  String _password = '';
  int _phoneFieldVersion = 0;

  String get phone => _phone;
  String get password => _password;
  int get phoneFieldVersion => _phoneFieldVersion;

  bool get phoneIsValid =>
      _phone.length == 10 && _phone.startsWith('0') && _digitsOnly(_phone);

  bool get passwordIsValid => _password.isNotEmpty;

  bool get canSubmit => phoneIsValid && passwordIsValid;

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
    _password = '';
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
      _password = '';
    }

    notifyListeners();
  }

  void setPassword(String value) {
    if (value == _password) return;

    _password = value;
    notifyListeners();
  }

  void resetPassword() {
    if (_password.isEmpty) return;

    _password = '';
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