import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/api/api.dart';
import 'package:frontend/controllers/controllers.dart';
import 'package:frontend/storage/storage.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('restoration without a stored session opens the start screen', () async {
    final controller = _controller(
      (_) async => _unexpected(),
      _MemoryStorage(),
    );
    await controller.restoreSession();
    expect(controller.status, SessionStatus.start);
    expect(controller.isAuthenticated, isFalse);
  });

  test('valid stored admin session restores the admin area', () async {
    final storage = _MemoryStorage(
      const StoredSession(accessToken: 'saved', role: StoredAuthRole.admin),
    );
    final controller = _controller((request) async {
      expect(request.url.path, '/api/auth/admin/me');
      expect(request.headers['authorization'], 'Bearer saved');
      return _me('admin');
    }, storage);
    await controller.restoreSession();
    expect(controller.status, SessionStatus.adminArea);
    expect(controller.isAdmin, isTrue);
    expect(controller.accessToken, 'saved');
  });

  test('invalid restored session is deleted and returns to start', () async {
    final storage = _MemoryStorage(
      const StoredSession(accessToken: 'expired', role: StoredAuthRole.mentor),
    );
    final controller = _controller(
      (_) async => http.Response(jsonEncode({'detail': 'Expired'}), 401),
      storage,
    );
    await controller.restoreSession();
    expect(controller.status, SessionStatus.start);
    expect(storage.session, isNull);
    expect(storage.clearCalls, 1);
  });

  test(
    'mentor access login saves the session and enters mentor area',
    () async {
      final storage = _MemoryStorage();
      final controller = _controller(
        (_) async =>
            _auth(mode: 'mentor', purpose: 'access', token: 'mentor-token'),
        storage,
      );
      controller.startMentorLogin();
      await controller.submitMentorLogin(phone: '0700123456', pin: '123456');
      expect(controller.status, SessionStatus.mentorArea);
      expect(controller.accessToken, 'mentor-token');
      expect(storage.session?.role, StoredAuthRole.mentor);
    },
  );

  test('mentor setup login changes PIN before saving access session', () async {
    final storage = _MemoryStorage();
    var calls = 0;
    final controller = _controller((request) async {
      calls++;
      if (request.url.path.endsWith('/login')) {
        return _auth(mode: 'mentor', purpose: 'setup', token: 'setup-token');
      }
      expect(request.url.path, '/api/auth/mentor/change-pin');
      expect(request.headers['authorization'], 'Bearer setup-token');
      return _auth(mode: 'mentor', purpose: 'access', token: 'access-token');
    }, storage);
    await controller.submitMentorLogin(phone: '0700123456', pin: '123456');
    expect(controller.status, SessionStatus.mentorSetupPin);
    expect(controller.setupToken, 'setup-token');
    await controller.submitMentorPinChange(newPin: '654321');
    expect(controller.status, SessionStatus.mentorArea);
    expect(controller.setupToken, isNull);
    expect(storage.session?.accessToken, 'access-token');
    expect(calls, 2);
  });

  test(
    'admin setup login changes password before entering admin area',
    () async {
      final storage = _MemoryStorage();
      final controller = _controller((request) async {
        if (request.url.path.endsWith('/login')) {
          return _auth(mode: 'admin', purpose: 'setup', token: 'setup-token');
        }
        expect(request.url.path, '/api/auth/admin/change-password');
        return _auth(mode: 'admin', purpose: 'access', token: 'access-token');
      }, storage);
      await controller.submitAdminLogin(
        phone: '0700123456',
        password: 'secret',
      );
      expect(controller.status, SessionStatus.adminSetupPassword);
      await controller.submitAdminPasswordChange(newPassword: 'new-secret');
      expect(controller.status, SessionStatus.adminArea);
      expect(storage.session?.role, StoredAuthRole.admin);
    },
  );

  test('authentication failure stays on login', () async {
    final controller = _controller(
      (_) async => http.Response(jsonEncode({'detail': 'No access'}), 401),
      _MemoryStorage(),
    );
    controller.startAdminLogin();
    await controller.submitAdminLogin(phone: '0700123456', password: 'wrong');
    expect(controller.status, SessionStatus.adminLogin);
    expect(controller.adminLoginMessage, 'Bad phone or password.');
    expect(controller.adminLoginIsSubmitting, isFalse);
    controller.clearAdminLoginMessage();
    expect(controller.adminLoginMessage, isNull);
  });

  test('cancel invalidates an in-flight login response', () async {
    final response = Future<http.Response>.delayed(
      const Duration(milliseconds: 10),
      () => _auth(mode: 'mentor', purpose: 'access', token: 'late-token'),
    );
    final controller = _controller((_) => response, _MemoryStorage());
    controller.startMentorLogin();
    final login = controller.submitMentorLogin(
      phone: '0700123456',
      pin: '123456',
    );
    controller.cancelLogin();
    await login;
    expect(controller.status, SessionStatus.start);
    expect(controller.accessToken, isNull);
  });
}

SessionController _controller(
  Future<http.Response> Function(http.Request) handler,
  SessionStorage storage,
) => SessionController(
  authApi: AuthApi(client: MockClient(handler)),
  tokenStorage: storage,
);

http.Response _auth({
  required String mode,
  required String purpose,
  required String token,
}) => http.Response(
  jsonEncode({
    'token_purpose': purpose,
    'mode': mode,
    'access_token': token,
    'first_name': 'Test',
    'last_name': 'User',
    'preferred_language': 'eng',
  }),
  200,
);

http.Response _me(String mode) => http.Response(
  jsonEncode({
    'mode': mode,
    'first_name': 'Test',
    'last_name': 'User',
    'preferred_language': 'eng',
  }),
  200,
);

http.Response _unexpected() => throw StateError('Unexpected request');

class _MemoryStorage implements SessionStorage {
  _MemoryStorage([this.session]);
  StoredSession? session;
  int clearCalls = 0;

  @override
  Future<StoredSession?> readAccessSession() async => session;

  @override
  Future<void> saveAccessSession({
    required String accessToken,
    required StoredAuthRole role,
  }) async {
    session = StoredSession(accessToken: accessToken, role: role);
  }

  @override
  Future<void> clear() async {
    clearCalls++;
    session = null;
  }
}
