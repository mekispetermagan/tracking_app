import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:agu_frontend/api/api.dart';
import 'package:agu_frontend/controllers/controllers.dart';
import 'package:agu_frontend/storage/storage.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('storage read failure exits restoration', () async {
    final controller = SessionController(
      authApi: AuthApi(client: MockClient(_unexpectedRequest)),
      tokenStorage: _FakeSessionStorage(readError: StateError('unavailable')),
    );

    await controller.restoreSession();

    expect(controller.status, SessionStatus.start);
    expect(controller.accessToken, isNull);
  });

  test('login remains usable when session persistence fails', () async {
    final storage = _FakeSessionStorage(saveError: StateError('unavailable'));
    final controller = SessionController(
      authApi: AuthApi(client: MockClient((_) async => _mentorLoginResponse())),
      tokenStorage: storage,
    );

    await controller.submitMentorLogin(phone: '0700000000', pin: '123456');

    expect(controller.status, SessionStatus.mentorArea);
    expect(controller.accessToken, 'access-token');
    expect(controller.mentorLoginIsSubmitting, isFalse);
  });

  test('logout completes in memory when secure deletion fails', () async {
    final storage = _FakeSessionStorage(
      storedSession: const StoredSession(
        accessToken: 'stored-token',
        role: StoredAuthRole.mentor,
      ),
      clearError: StateError('unavailable'),
    );
    final controller = SessionController(
      authApi: AuthApi(client: MockClient((_) async => _mentorMeResponse())),
      tokenStorage: storage,
    );
    await controller.restoreSession();
    expect(controller.status, SessionStatus.mentorArea);

    await controller.handleUnauthorized();

    expect(controller.status, SessionStatus.start);
    expect(controller.accessToken, isNull);
    expect(storage.clearCalls, 1);
  });
}

Future<http.Response> _unexpectedRequest(http.Request request) {
  throw StateError('Unexpected request to ${request.url}');
}

http.Response _mentorLoginResponse() => http.Response(
  jsonEncode({
    'token_purpose': 'access',
    'mode': 'mentor',
    'access_token': 'access-token',
    'first_name': 'Test',
    'last_name': 'Mentor',
    'preferred_language': 'eng',
  }),
  200,
);

http.Response _mentorMeResponse() => http.Response(
  jsonEncode({
    'mode': 'mentor',
    'first_name': 'Test',
    'last_name': 'Mentor',
    'preferred_language': 'eng',
  }),
  200,
);

class _FakeSessionStorage implements SessionStorage {
  _FakeSessionStorage({
    this.storedSession,
    this.readError,
    this.saveError,
    this.clearError,
  });

  StoredSession? storedSession;
  final Object? readError;
  final Object? saveError;
  final Object? clearError;
  int clearCalls = 0;

  @override
  Future<StoredSession?> readAccessSession() async {
    if (readError != null) throw readError!;
    return storedSession;
  }

  @override
  Future<void> saveAccessSession({
    required String accessToken,
    required StoredAuthRole role,
  }) async {
    if (saveError != null) throw saveError!;
    storedSession = StoredSession(accessToken: accessToken, role: role);
  }

  @override
  Future<void> clear() async {
    clearCalls++;
    if (clearError != null) throw clearError!;
    storedSession = null;
  }
}
