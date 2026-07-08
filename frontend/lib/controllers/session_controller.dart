import 'package:flutter/foundation.dart';

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
  SessionStatus _status = SessionStatus.restoring;

  SessionStatus get status => _status;

  bool get isAdmin => _status == SessionStatus.adminArea;
  bool get isMentor => _status == SessionStatus.mentorArea;
  bool get isAuthenticated => isAdmin || isMentor;

  Future<void> restoreSession() async {
    _setStatus(SessionStatus.restoring);

    await Future<void>.delayed(const Duration(milliseconds: 300));

    _setStatus(SessionStatus.start);
  }

  void startAdminLogin() {
    _setStatus(SessionStatus.adminLogin);
  }

  void startMentorLogin() {
    _setStatus(SessionStatus.mentorLogin);
  }

  void cancelLogin() {
    _setStatus(SessionStatus.start);
  }

  void fakeAdminLogin({bool setupRequired = false}) {
    _setStatus(
      setupRequired
          ? SessionStatus.adminSetupPassword
          : SessionStatus.adminArea,
    );
  }

  void fakeMentorLogin({bool setupRequired = false}) {
    _setStatus(
      setupRequired
          ? SessionStatus.mentorSetupPin
          : SessionStatus.mentorArea,
    );
  }

  void completeAdminSetup() {
    _setStatus(SessionStatus.adminArea);
  }

  void completeMentorSetup() {
    _setStatus(SessionStatus.mentorArea);
  }

  void logout() {
    _setStatus(SessionStatus.start);
  }

  void handleUnauthorized() {
    logout();
  }

  void _setStatus(SessionStatus status) {
    if (_status == status) return;
    _status = status;
    notifyListeners();
  }
}