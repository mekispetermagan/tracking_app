import 'package:flutter_secure_storage/flutter_secure_storage.dart';

enum StoredAuthRole {
  mentor,
  admin,
}

class StoredSession {
  final String accessToken;
  final StoredAuthRole role;

  const StoredSession({
    required this.accessToken,
    required this.role,
  });
}

class TokenStorage {
  static const _accessTokenKey = 'access_token';
  static const _roleKey = 'auth_role';

  final FlutterSecureStorage _storage;

  const TokenStorage({
    FlutterSecureStorage storage = const FlutterSecureStorage(),
  }) : _storage = storage;

  Future<void> saveAccessSession({
    required String accessToken,
    required StoredAuthRole role,
  }) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _roleKey, value: role.name);
  }

  Future<StoredSession?> readAccessSession() async {
    final token = await _storage.read(key: _accessTokenKey);
    final roleValue = await _storage.read(key: _roleKey);

    if (token == null || token.isEmpty || roleValue == null) {
      return null;
    }

    final role = switch (roleValue) {
      'mentor' => StoredAuthRole.mentor,
      'admin' => StoredAuthRole.admin,
      _ => null,
    };

    if (role == null) return null;

    return StoredSession(
      accessToken: token,
      role: role,
    );
  }

  Future<void> clear() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _roleKey);
  }
}