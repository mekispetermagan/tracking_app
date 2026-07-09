import 'package:flutter/foundation.dart';

class AdminSetupPasswordController extends ChangeNotifier {
  String _password = '';
  String _confirmPassword = '';

  String get password => _password;
  String get confirmPassword => _confirmPassword;

  bool get passwordIsValid => _password.length >= 6;
  bool get confirmPasswordIsValid => _confirmPassword.length >= 6;
  bool get passwordsMatch => _password == _confirmPassword;

  bool get canSubmit =>
      passwordIsValid && confirmPasswordIsValid && passwordsMatch;

  void setPassword(String value) {
    if (value == _password) return;

    _password = value;
    notifyListeners();
  }

  void setConfirmPassword(String value) {
    if (value == _confirmPassword) return;

    _confirmPassword = value;
    notifyListeners();
  }

  void reset() {
    if (_password.isEmpty && _confirmPassword.isEmpty) return;

    _password = '';
    _confirmPassword = '';
    notifyListeners();
  }
}