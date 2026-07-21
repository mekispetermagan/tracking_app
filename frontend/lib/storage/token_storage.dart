import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

enum StoredAuthRole { mentor, admin }

class StoredSession {
  final String accessToken;
  final StoredAuthRole role;

  const StoredSession({required this.accessToken, required this.role});
}

abstract interface class SessionStorage {
  Future<void> saveAccessSession({
    required String accessToken,
    required StoredAuthRole role,
  });

  Future<StoredSession?> readAccessSession();

  Future<void> clear();
}

class TokenStorage implements SessionStorage {
  static const _sessionKey = 'access_session';
  static const _legacyAccessTokenKey = 'access_token';
  static const _legacyRoleKey = 'auth_role';

  final FlutterSecureStorage _storage;

  const TokenStorage({
    FlutterSecureStorage storage = const FlutterSecureStorage(),
  }) : _storage = storage;

  @override
  Future<void> saveAccessSession({
    required String accessToken,
    required StoredAuthRole role,
  }) async {
    await _storage.write(
      key: _sessionKey,
      value: jsonEncode({'access_token': accessToken, 'role': role.name}),
    );
    await Future.wait([
      _storage.delete(key: _legacyAccessTokenKey),
      _storage.delete(key: _legacyRoleKey),
    ]);
  }

  @override
  Future<StoredSession?> readAccessSession() async {
    final storedValue = await _storage.read(key: _sessionKey);

    if (storedValue != null) {
      try {
        final data = jsonDecode(storedValue) as Map<String, dynamic>;
        return _sessionFromValues(
          data['access_token'] as String?,
          data['role'] as String?,
        );
      } on FormatException {
        return null;
      } on TypeError {
        return null;
      }
    }

    return _sessionFromValues(
      await _storage.read(key: _legacyAccessTokenKey),
      await _storage.read(key: _legacyRoleKey),
    );
  }

  @override
  Future<void> clear() async {
    await Future.wait([
      _storage.delete(key: _sessionKey),
      _storage.delete(key: _legacyAccessTokenKey),
      _storage.delete(key: _legacyRoleKey),
    ]);
  }

  StoredSession? _sessionFromValues(String? token, String? roleValue) {
    if (token == null || token.isEmpty || roleValue == null) return null;

    final role = switch (roleValue) {
      'mentor' => StoredAuthRole.mentor,
      'admin' => StoredAuthRole.admin,
      _ => null,
    };

    return role == null ? null : StoredSession(accessToken: token, role: role);
  }
}
