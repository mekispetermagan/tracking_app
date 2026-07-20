import 'package:flutter/foundation.dart';

abstract class ConfirmedCredentialController extends ChangeNotifier {
  ConfirmedCredentialController({
    required String Function(String value) normalize,
    required bool Function(String value) validate,
  }) : _normalize = normalize,
       _validate = validate;

  final String Function(String value) _normalize;
  final bool Function(String value) _validate;

  String _credential = '';
  String _confirmation = '';

  @protected
  String get credential => _credential;

  @protected
  String get confirmation => _confirmation;

  bool get credentialIsValid => _validate(_credential);
  bool get confirmationIsValid => _validate(_confirmation);
  bool get credentialsMatch => _credential == _confirmation;
  bool get canSubmit =>
      credentialIsValid && confirmationIsValid && credentialsMatch;

  @protected
  void setCredential(String value) {
    final normalized = _normalize(value);
    if (normalized == _credential) return;
    _credential = normalized;
    notifyListeners();
  }

  @protected
  void setConfirmation(String value) {
    final normalized = _normalize(value);
    if (normalized == _confirmation) return;
    _confirmation = normalized;
    notifyListeners();
  }

  void reset() {
    if (_credential.isEmpty && _confirmation.isEmpty) return;
    _credential = '';
    _confirmation = '';
    notifyListeners();
  }
}
