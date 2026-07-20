import "remembered_phone_controller.dart";

import '../validation/credential_validation.dart' show isValidPin;

class MentorLoginController extends RememberedPhoneController {
  MentorLoginController() : super("mentor_last_phone");
  String _pin = '';

  String get pin => _pin;

  bool get pinIsValid => isValidPin(_pin);

  bool get canSubmit => phoneIsValid && pinIsValid;

  void setPin(String value) {
    final normalized = normalizeDigits(value, maxLength: 6);
    if (normalized == _pin) return;

    _pin = normalized;
    notifyListeners();
  }

  void resetPin() {
    if (clearCredential()) notifyListeners();
  }

  @override
  bool clearCredential() {
    if (_pin.isEmpty) return false;
    _pin = "";
    return true;
  }
}
