import "remembered_phone_controller.dart";

import '../validation/credential_validation.dart' show isValidPassword;

class AdminLoginController extends RememberedPhoneController {
  AdminLoginController() : super("admin_last_phone");
  String _password = '';

  String get password => _password;

  bool get passwordIsValid => isValidPassword(_password);

  bool get canSubmit => phoneIsValid && passwordIsValid;

  void setPassword(String value) {
    if (value == _password) return;

    _password = value;
    notifyListeners();
  }

  void resetPassword() {
    if (clearCredential()) notifyListeners();
  }

  @override
  bool clearCredential() {
    if (_password.isEmpty) return false;
    _password = "";
    return true;
  }
}
