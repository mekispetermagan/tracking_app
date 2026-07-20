import "../validation/credential_validation.dart" show isValidPin;
import "confirmed_credential_controller.dart";

class MentorSetupPinController extends ConfirmedCredentialController {
  MentorSetupPinController()
    : super(normalize: _normalizePin, validate: isValidPin);

  String get pin => credential;
  String get confirmPin => confirmation;
  bool get pinIsValid => credentialIsValid;
  bool get confirmPinIsValid => confirmationIsValid;
  bool get pinsMatch => credentialsMatch;

  void setPin(String value) => setCredential(value);
  void setConfirmPin(String value) => setConfirmation(value);
}

String _normalizePin(String value) {
  final digits = value.replaceAll(RegExp(r"\D"), "");
  return digits.length <= 6 ? digits : digits.substring(0, 6);
}
