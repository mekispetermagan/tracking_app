import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '_api_support.dart';
import 'api_result.dart';

enum AuthTokenPurpose { access, setup }

enum AuthMode { mentor, admin }

enum AuthFailure {
  badCredentials,
  temporarySecretExpired,
  serverError,
  invalidData,
  networkError,
}

class AuthResult extends ApiResult<AuthResult, AuthFailure> {
  final AuthTokenPurpose? tokenPurpose;
  final AuthMode? mode;
  final String? token;
  final String? firstName;
  final String? lastName;
  final String? preferredLanguage;
  @override
  final AuthFailure? failure;
  @override
  final String? message;

  const AuthResult.success({
    required AuthTokenPurpose this.tokenPurpose,
    required AuthMode this.mode,
    required String this.token,
    required String this.firstName,
    required String this.lastName,
    required String this.preferredLanguage,
  }) : failure = null,
       message = null;

  const AuthResult.failure({required AuthFailure this.failure, this.message})
    : tokenPurpose = null,
      mode = null,
      token = null,
      firstName = null,
      lastName = null,
      preferredLanguage = null;
} // AuthResult

class AuthApi {
  final http.Client _client;

  AuthApi({http.Client? client}) : _client = client ?? http.Client();

  Future<AuthResult> mentorLogin({required String phone, required String pin}) {
    return _postAuth(
      path: '/api/auth/mentor/login',
      body: {'phone': phone, 'pin': pin},
    );
  }

  Future<AuthResult> adminLogin({
    required String phone,
    required String password,
  }) {
    return _postAuth(
      path: '/api/auth/admin/login',
      body: {'phone': phone, 'password': password},
    );
  }

  Future<AuthResult> changeMentorPin({
    required String setupToken,
    required String newPin,
  }) {
    return _postAuth(
      path: '/api/auth/mentor/change-pin',
      body: {'new_pin': newPin},
      bearerToken: setupToken,
    );
  }

  Future<AuthResult> changeAdminPassword({
    required String setupToken,
    required String newPassword,
  }) {
    return _postAuth(
      path: '/api/auth/admin/change-password',
      body: {'new_password': newPassword},
      bearerToken: setupToken,
    );
  }

  Future<MeResult> mentorMe({required String accessToken}) {
    return _getMe(path: '/api/auth/mentor/me', accessToken: accessToken);
  }

  Future<MeResult> adminMe({required String accessToken}) {
    return _getMe(path: '/api/auth/admin/me', accessToken: accessToken);
  }

  Future<MeResult> _getMe({
    required String path,
    required String accessToken,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');

    try {
      final response = await _client.get(
        uri,
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      final data = decodeJsonBody(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        return MeResult.success(
          mode: _modeFromJson(data['mode'] as String),
          firstName: data['first_name'] as String,
          lastName: data['last_name'] as String,
          preferredLanguage: data['preferred_language'] as String,
        );
      }

      if (response.statusCode == 401 || response.statusCode == 403) {
        return MeResult.failure(
          failure: AuthFailure.badCredentials,
          message: data['detail']?.toString(),
        );
      }

      return MeResult.failure(
        failure: AuthFailure.serverError,
        message: data['detail']?.toString(),
      );
    } catch (error) {
      if (isInvalidApiData(error)) {
        return const MeResult.failure(failure: AuthFailure.invalidData);
      }
      return const MeResult.failure(failure: AuthFailure.networkError);
    }
  }

  Future<AuthResult> _postAuth({
    required String path,
    required Map<String, String> body,
    String? bearerToken,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    final headers = {
      'Content-Type': 'application/json',
      if (bearerToken != null) 'Authorization': 'Bearer $bearerToken',
    };

    try {
      final response = await _client.post(
        uri,
        headers: headers,
        body: jsonEncode(body),
      );

      final data = decodeJsonBody(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        return AuthResult.success(
          tokenPurpose: _tokenPurposeFromJson(data['token_purpose'] as String),
          mode: _modeFromJson(data['mode'] as String),
          token: data['access_token'] as String,
          firstName: data['first_name'] as String,
          lastName: data['last_name'] as String,
          preferredLanguage: data['preferred_language'] as String,
        );
      }

      if (response.statusCode == 401) {
        return AuthResult.failure(
          failure: AuthFailure.badCredentials,
          message: data['detail']?.toString(),
        );
      }

      if (response.statusCode == 403) {
        return AuthResult.failure(
          failure: AuthFailure.temporarySecretExpired,
          message: data['detail']?.toString(),
        );
      }

      return AuthResult.failure(
        failure: AuthFailure.serverError,
        message: data['detail']?.toString(),
      );
    } catch (error) {
      if (isInvalidApiData(error)) {
        return const AuthResult.failure(failure: AuthFailure.invalidData);
      }
      return const AuthResult.failure(failure: AuthFailure.networkError);
    }
  }

  AuthTokenPurpose _tokenPurposeFromJson(String value) {
    return switch (value) {
      'access' => AuthTokenPurpose.access,
      'setup' => AuthTokenPurpose.setup,
      _ => throw FormatException('Unknown token purpose: $value'),
    };
  }

  AuthMode _modeFromJson(String value) {
    return switch (value) {
      'mentor' => AuthMode.mentor,
      'admin' => AuthMode.admin,
      _ => throw FormatException('Unknown auth mode: $value'),
    };
  }
} // AuthApi

class MeResult extends ApiResult<MeResult, AuthFailure> {
  final AuthMode? mode;
  final String? firstName;
  final String? lastName;
  final String? preferredLanguage;
  @override
  final AuthFailure? failure;
  @override
  final String? message;

  const MeResult.success({
    required this.mode,
    required this.firstName,
    required this.lastName,
    required this.preferredLanguage,
  }) : failure = null,
       message = null;

  const MeResult.failure({required this.failure, this.message})
    : mode = null,
      firstName = null,
      lastName = null,
      preferredLanguage = null;
} // MeResult
