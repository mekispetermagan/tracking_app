import 'package:flutter/foundation.dart';

import '../api/api.dart';
import '../storage/storage.dart';

enum SessionStatus {
  restoring,
  start,
  adminLogin,
  mentorLogin,
  adminSetupPassword,
  mentorSetupPin,
  adminArea,
  mentorArea,
}

class SessionController extends ChangeNotifier {
  final AuthApi _authApi;
  final TokenStorage _tokenStorage;

  SessionController({AuthApi? authApi, TokenStorage? tokenStorage})
    : _authApi = authApi ?? AuthApi(),
      _tokenStorage = tokenStorage ?? const TokenStorage();

  SessionStatus _status = SessionStatus.restoring;

  String? _accessToken;
  String? _setupToken;

  String? _mentorLoginMessage;
  bool _mentorLoginIsSubmitting = false;

  String? _adminLoginMessage;
  bool _adminLoginIsSubmitting = false;

  String? _mentorSetupMessage;
  bool _mentorSetupIsSubmitting = false;

  String? _adminSetupMessage;
  bool _adminSetupIsSubmitting = false;

  SessionStatus get status => _status;

  String? get accessToken => _accessToken;
  String? get setupToken => _setupToken;

  String? get mentorLoginMessage => _mentorLoginMessage;
  bool get mentorLoginIsSubmitting => _mentorLoginIsSubmitting;

  String? get adminLoginMessage => _adminLoginMessage;
  bool get adminLoginIsSubmitting => _adminLoginIsSubmitting;

  String? get mentorSetupMessage => _mentorSetupMessage;
  bool get mentorSetupIsSubmitting => _mentorSetupIsSubmitting;

  String? get adminSetupMessage => _adminSetupMessage;
  bool get adminSetupIsSubmitting => _adminSetupIsSubmitting;

  bool get isAdmin => _status == SessionStatus.adminArea;
  bool get isMentor => _status == SessionStatus.mentorArea;
  bool get isAuthenticated => isAdmin || isMentor;

  Future<void> restoreSession() async {
    _setStatus(SessionStatus.restoring);

    final storedSession = await _tokenStorage.readAccessSession();

    if (storedSession == null) {
      _setStatus(SessionStatus.start);
      return;
    }

    final result = switch (storedSession.role) {
      StoredAuthRole.mentor => await _authApi.mentorMe(
        accessToken: storedSession.accessToken,
      ),
      StoredAuthRole.admin => await _authApi.adminMe(
        accessToken: storedSession.accessToken,
      ),
    };

    if (result.failure != null) {
      await _tokenStorage.clear();
      _accessToken = null;
      _setupToken = null;
      _setStatus(SessionStatus.start);
      return;
    }

    _accessToken = storedSession.accessToken;
    _setupToken = null;

    _setStatus(
      storedSession.role == StoredAuthRole.mentor
          ? SessionStatus.mentorArea
          : SessionStatus.adminArea,
    );
  }

  void startAdminLogin() {
    _adminLoginMessage = null;
    _setStatus(SessionStatus.adminLogin);
  }

  void startMentorLogin() {
    _mentorLoginMessage = null;
    _setStatus(SessionStatus.mentorLogin);
  }

  void cancelLogin() {
    _mentorLoginMessage = null;
    _adminLoginMessage = null;
    _setStatus(SessionStatus.start);
  }

  Future<void> submitMentorLogin({
    required String phone,
    required String pin,
  }) async {
    if (_mentorLoginIsSubmitting) return;

    _mentorLoginMessage = null;
    _mentorLoginIsSubmitting = true;
    notifyListeners();

    final result = await _authApi.mentorLogin(phone: phone, pin: pin);

    _mentorLoginIsSubmitting = false;

    if (result.failure != null) {
      _mentorLoginMessage = _messageForMentorAuthFailure(result.failure!);
      _setStatus(SessionStatus.mentorLogin);
      return;
    }

    if (result.mode != AuthMode.mentor || result.token == null) {
      _mentorLoginMessage = 'Unexpected server response.';
      _setStatus(SessionStatus.mentorLogin);
      return;
    }

    if (result.tokenPurpose == AuthTokenPurpose.setup) {
      _setupToken = result.token;
      _setStatus(SessionStatus.mentorSetupPin);
      return;
    }

    _accessToken = result.token;
    _setupToken = null;

    await _tokenStorage.saveAccessSession(
      accessToken: result.token!,
      role: StoredAuthRole.mentor,
    );

    _setStatus(SessionStatus.mentorArea);
  }

  Future<void> submitAdminLogin({
    required String phone,
    required String password,
  }) async {
    if (_adminLoginIsSubmitting) return;

    _adminLoginMessage = null;
    _adminLoginIsSubmitting = true;
    notifyListeners();

    final result = await _authApi.adminLogin(phone: phone, password: password);

    _adminLoginIsSubmitting = false;

    if (result.failure != null) {
      _adminLoginMessage = _messageForAdminAuthFailure(result.failure!);
      _setStatus(SessionStatus.adminLogin);
      return;
    }

    if (result.mode != AuthMode.admin || result.token == null) {
      _adminLoginMessage = 'Unexpected server response.';
      _setStatus(SessionStatus.adminLogin);
      return;
    }

    if (result.tokenPurpose == AuthTokenPurpose.setup) {
      _setupToken = result.token;
      _setStatus(SessionStatus.adminSetupPassword);
      return;
    }

    _accessToken = result.token;
    _setupToken = null;

    await _tokenStorage.saveAccessSession(
      accessToken: result.token!,
      role: StoredAuthRole.admin,
    );

    _setStatus(SessionStatus.adminArea);
  }

  Future<void> submitMentorPinChange({required String newPin}) async {
    if (_mentorSetupIsSubmitting) return;

    final token = _setupToken;

    if (token == null) {
      _mentorLoginMessage = 'Setup session expired. Please log in again.';
      _setStatus(SessionStatus.mentorLogin);
      return;
    }

    _mentorSetupMessage = null;
    _mentorSetupIsSubmitting = true;
    notifyListeners();

    final result = await _authApi.changeMentorPin(
      setupToken: token,
      newPin: newPin,
    );

    _mentorSetupIsSubmitting = false;

    if (result.failure != null) {
      _mentorSetupMessage = _messageForMentorSetupFailure(result.failure!);
      _setStatus(SessionStatus.mentorSetupPin);
      return;
    }

    if (result.mode != AuthMode.mentor ||
        result.tokenPurpose != AuthTokenPurpose.access ||
        result.token == null) {
      _mentorSetupMessage = 'Unexpected server response.';
      _setStatus(SessionStatus.mentorSetupPin);
      return;
    }

    _accessToken = result.token;
    _setupToken = null;
    _mentorSetupMessage = null;

    await _tokenStorage.saveAccessSession(
      accessToken: result.token!,
      role: StoredAuthRole.mentor,
    );

    _setStatus(SessionStatus.mentorArea);
  }

  Future<void> submitAdminPasswordChange({required String newPassword}) async {
    if (_adminSetupIsSubmitting) return;

    final token = _setupToken;

    if (token == null) {
      _adminLoginMessage = 'Setup session expired. Please log in again.';
      _setStatus(SessionStatus.adminLogin);
      return;
    }

    _adminSetupMessage = null;
    _adminSetupIsSubmitting = true;
    notifyListeners();

    final result = await _authApi.changeAdminPassword(
      setupToken: token,
      newPassword: newPassword,
    );

    _adminSetupIsSubmitting = false;

    if (result.failure != null) {
      _adminSetupMessage = _messageForAdminSetupFailure(result.failure!);
      _setStatus(SessionStatus.adminSetupPassword);
      return;
    }

    if (result.mode != AuthMode.admin ||
        result.tokenPurpose != AuthTokenPurpose.access ||
        result.token == null) {
      _adminSetupMessage = 'Unexpected server response.';
      _setStatus(SessionStatus.adminSetupPassword);
      return;
    }

    _accessToken = result.token;
    _setupToken = null;
    _adminSetupMessage = null;

    await _tokenStorage.saveAccessSession(
      accessToken: result.token!,
      role: StoredAuthRole.admin,
    );

    _setStatus(SessionStatus.adminArea);
  }

  void clearMentorLoginMessage() {
    if (_mentorLoginMessage == null) return;

    _mentorLoginMessage = null;
    notifyListeners();
  }

  void clearAdminLoginMessage() {
    if (_adminLoginMessage == null) return;

    _adminLoginMessage = null;
    notifyListeners();
  }

  void clearMentorSetupMessage() {
    if (_mentorSetupMessage == null) return;

    _mentorSetupMessage = null;
    notifyListeners();
  }

  void clearAdminSetupMessage() {
    if (_adminSetupMessage == null) return;

    _adminSetupMessage = null;
    notifyListeners();
  }

  Future<void> logout() async {
    _accessToken = null;
    _setupToken = null;

    _mentorLoginMessage = null;
    _mentorLoginIsSubmitting = false;

    _adminLoginMessage = null;
    _adminLoginIsSubmitting = false;

    _mentorSetupMessage = null;
    _mentorSetupIsSubmitting = false;

    _adminSetupMessage = null;
    _adminSetupIsSubmitting = false;

    await _tokenStorage.clear();

    _setStatus(SessionStatus.start);
  }

  Future<void> handleUnauthorized() async {
    await logout();
  }

  String _messageForMentorAuthFailure(AuthFailure failure) {
    return switch (failure) {
      AuthFailure.badCredentials => 'Bad phone or PIN.',
      AuthFailure.temporarySecretExpired => 'Temporary PIN expired.',
      AuthFailure.serverError => 'Server error.',
      AuthFailure.networkError => 'Cannot connect to server.',
    };
  }

  String _messageForAdminAuthFailure(AuthFailure failure) {
    return switch (failure) {
      AuthFailure.badCredentials => 'Bad phone or password.',
      AuthFailure.temporarySecretExpired => 'Temporary password expired.',
      AuthFailure.serverError => 'Server error.',
      AuthFailure.networkError => 'Cannot connect to server.',
    };
  }

  String _messageForMentorSetupFailure(AuthFailure failure) {
    return switch (failure) {
      AuthFailure.badCredentials =>
        'Setup session expired. Please log in again.',
      AuthFailure.temporarySecretExpired => 'Temporary PIN expired.',
      AuthFailure.serverError => 'Server error.',
      AuthFailure.networkError => 'Cannot connect to server.',
    };
  }

  String _messageForAdminSetupFailure(AuthFailure failure) {
    return switch (failure) {
      AuthFailure.badCredentials =>
        'Setup session expired. Please log in again.',
      AuthFailure.temporarySecretExpired => 'Temporary password expired.',
      AuthFailure.serverError => 'Server error.',
      AuthFailure.networkError => 'Cannot connect to server.',
    };
  }

  void _setStatus(SessionStatus status) {
    if (_status == status) {
      notifyListeners();
      return;
    }

    _status = status;
    notifyListeners();
  }
}
