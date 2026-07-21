import 'feature_controller.dart';

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

class SessionController extends FeatureController {
  final AuthApi _authApi;
  final SessionStorage _tokenStorage;

  SessionController({AuthApi? authApi, SessionStorage? tokenStorage})
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
    final operation = beginRequest();
    _setStatus(SessionStatus.restoring);

    StoredSession? storedSession;
    try {
      storedSession = await _tokenStorage.readAccessSession();
    } catch (_) {
      if (requestIsCurrent(operation)) _setStatus(SessionStatus.start);
      return;
    }
    if (!requestIsCurrent(operation)) return;

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
    if (!requestIsCurrent(operation)) return;

    if (result.failure != null) {
      try {
        await _tokenStorage.clear();
      } catch (_) {
        // Invalid stored credentials are still discarded in memory.
      }
      if (!requestIsCurrent(operation)) return;
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
    invalidateRequests();
    _adminLoginMessage = null;
    _setStatus(SessionStatus.adminLogin);
  }

  void startMentorLogin() {
    invalidateRequests();
    _mentorLoginMessage = null;
    _setStatus(SessionStatus.mentorLogin);
  }

  void cancelLogin() {
    invalidateRequests();
    _mentorLoginMessage = null;
    _adminLoginMessage = null;
    _setStatus(SessionStatus.start);
  }

  Future<void> submitMentorLogin({
    required String phone,
    required String pin,
  }) async {
    if (_mentorLoginIsSubmitting) return;

    final operation = beginRequest();
    _mentorLoginMessage = null;
    _mentorLoginIsSubmitting = true;
    notifyListeners();

    final result = await _authApi.mentorLogin(phone: phone, pin: pin);
    if (!requestIsCurrent(operation)) return;

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

    await _saveAccessSession(
      accessToken: result.token!,
      role: StoredAuthRole.mentor,
    );
    if (!requestIsCurrent(operation)) return;

    _setStatus(SessionStatus.mentorArea);
  }

  Future<void> submitAdminLogin({
    required String phone,
    required String password,
  }) async {
    if (_adminLoginIsSubmitting) return;

    final operation = beginRequest();
    _adminLoginMessage = null;
    _adminLoginIsSubmitting = true;
    notifyListeners();

    final result = await _authApi.adminLogin(phone: phone, password: password);
    if (!requestIsCurrent(operation)) return;

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

    await _saveAccessSession(
      accessToken: result.token!,
      role: StoredAuthRole.admin,
    );
    if (!requestIsCurrent(operation)) return;

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

    final operation = beginRequest();
    _mentorSetupMessage = null;
    _mentorSetupIsSubmitting = true;
    notifyListeners();

    final result = await _authApi.changeMentorPin(
      setupToken: token,
      newPin: newPin,
    );
    if (!requestIsCurrent(operation)) return;

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

    await _saveAccessSession(
      accessToken: result.token!,
      role: StoredAuthRole.mentor,
    );
    if (!requestIsCurrent(operation)) return;

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

    final operation = beginRequest();
    _adminSetupMessage = null;
    _adminSetupIsSubmitting = true;
    notifyListeners();

    final result = await _authApi.changeAdminPassword(
      setupToken: token,
      newPassword: newPassword,
    );
    if (!requestIsCurrent(operation)) return;

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

    await _saveAccessSession(
      accessToken: result.token!,
      role: StoredAuthRole.admin,
    );
    if (!requestIsCurrent(operation)) return;

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
    final operation = beginRequest();
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

    try {
      await _tokenStorage.clear();
    } catch (_) {
      // Logout must complete even if secure storage is unavailable.
    }

    if (requestIsCurrent(operation)) _setStatus(SessionStatus.start);
  }

  Future<void> _saveAccessSession({
    required String accessToken,
    required StoredAuthRole role,
  }) async {
    try {
      await _tokenStorage.saveAccessSession(
        accessToken: accessToken,
        role: role,
      );
    } catch (_) {
      // Keep the valid in-memory session; it simply cannot be restored later.
    }
  }

  Future<void> handleUnauthorized() async {
    await logout();
  }

  String _messageForMentorAuthFailure(AuthFailure failure) {
    return switch (failure) {
      AuthFailure.badCredentials => 'Bad phone or PIN.',
      AuthFailure.temporarySecretExpired => 'Temporary PIN expired.',
      AuthFailure.invalidData => 'Invalid server data.',
      AuthFailure.serverError => 'Server error.',
      AuthFailure.networkError => 'Cannot connect to server.',
    };
  }

  String _messageForAdminAuthFailure(AuthFailure failure) {
    return switch (failure) {
      AuthFailure.badCredentials => 'Bad phone or password.',
      AuthFailure.temporarySecretExpired => 'Temporary password expired.',
      AuthFailure.invalidData => 'Invalid server data.',
      AuthFailure.serverError => 'Server error.',
      AuthFailure.networkError => 'Cannot connect to server.',
    };
  }

  String _messageForMentorSetupFailure(AuthFailure failure) {
    return switch (failure) {
      AuthFailure.badCredentials =>
        'Setup session expired. Please log in again.',
      AuthFailure.temporarySecretExpired => 'Temporary PIN expired.',
      AuthFailure.invalidData => 'Invalid server data.',
      AuthFailure.serverError => 'Server error.',
      AuthFailure.networkError => 'Cannot connect to server.',
    };
  }

  String _messageForAdminSetupFailure(AuthFailure failure) {
    return switch (failure) {
      AuthFailure.badCredentials =>
        'Setup session expired. Please log in again.',
      AuthFailure.temporarySecretExpired => 'Temporary password expired.',
      AuthFailure.invalidData => 'Invalid server data.',
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
