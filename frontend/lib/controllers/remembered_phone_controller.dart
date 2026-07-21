import 'package:flutter/foundation.dart';

import 'feature_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../validation/credential_validation.dart' show isValidPhone;

abstract class RememberedPhoneController extends FeatureController {
  RememberedPhoneController(this._lastPhoneKey);

  final String _lastPhoneKey;
  String _phone = '';
  int _phoneFieldVersion = 0;

  String get phone => _phone;
  int get phoneFieldVersion => _phoneFieldVersion;
  bool get phoneIsValid => isValidPhone(_phone);

  Future<void> loadLastPhone() async {
    final request = beginRequest();
    final version = _phoneFieldVersion;
    final prefs = await SharedPreferences.getInstance();
    final savedPhone = prefs.getString(_lastPhoneKey);
    if (!requestIsCurrent(request)) return;

    if (version != _phoneFieldVersion ||
        savedPhone == null ||
        savedPhone == _phone) {
      return;
    }

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
    final request = beginRequest();
    final phoneChanged = _phone.isNotEmpty;
    final credentialChanged = clearCredential();
    final changed = phoneChanged || credentialChanged;
    _phone = '';
    _phoneFieldVersion++;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastPhoneKey);
    if (!requestIsCurrent(request)) return;
    if (changed) notifyListeners();
  }

  void setPhone(String value) {
    invalidateRequests();
    final normalized = normalizeDigits(value, maxLength: 10);
    if (normalized == _phone) return;

    _phone = normalized;
    if (!phoneIsValid) clearCredential();
    notifyListeners();
  }

  @protected
  bool clearCredential();

  @protected
  String normalizeDigits(String value, {required int maxLength}) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    return digits.length <= maxLength ? digits : digits.substring(0, maxLength);
  }
}
