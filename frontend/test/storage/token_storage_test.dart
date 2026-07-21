import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/storage/storage.dart';

void main() {
  const secureStorage = FlutterSecureStorage();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  test('stores token and role together and reads them back', () async {
    final storage = TokenStorage(storage: secureStorage);

    await storage.saveAccessSession(
      accessToken: 'access-token',
      role: StoredAuthRole.admin,
    );

    final encoded = await secureStorage.read(key: 'access_session');
    expect(jsonDecode(encoded!), {
      'access_token': 'access-token',
      'role': 'admin',
    });
    expect(await secureStorage.read(key: 'access_token'), isNull);
    expect(await secureStorage.read(key: 'auth_role'), isNull);

    final restored = await storage.readAccessSession();
    expect(restored?.accessToken, 'access-token');
    expect(restored?.role, StoredAuthRole.admin);
  });

  test('reads the legacy two-key session during migration', () async {
    FlutterSecureStorage.setMockInitialValues({
      'access_token': 'legacy-token',
      'auth_role': 'mentor',
    });

    final restored = await const TokenStorage().readAccessSession();

    expect(restored?.accessToken, 'legacy-token');
    expect(restored?.role, StoredAuthRole.mentor);
  });

  test('treats malformed combined session data as absent', () async {
    FlutterSecureStorage.setMockInitialValues({'access_session': '{broken'});

    final restored = await const TokenStorage().readAccessSession();

    expect(restored, isNull);
  });
}
