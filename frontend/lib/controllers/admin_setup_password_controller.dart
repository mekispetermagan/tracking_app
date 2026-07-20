import "../validation/credential_validation.dart" show isValidPassword;
import "confirmed_credential_controller.dart";

class AdminSetupPasswordController extends ConfirmedCredentialController {
  AdminSetupPasswordController()
    : super(normalize: _identity, validate: isValidPassword);

  String get password => credential;
  String get confirmPassword => confirmation;
  bool get passwordIsValid => credentialIsValid;
  bool get confirmPasswordIsValid => confirmationIsValid;
  bool get passwordsMatch => credentialsMatch;

  void setPassword(String value) => setCredential(value);
  void setConfirmPassword(String value) => setConfirmation(value);
}

String _identity(String value) => value;
