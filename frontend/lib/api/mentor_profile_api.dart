import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/models.dart';

enum MentorProfileFailure {
  badRequest,
  unauthorized,
  forbidden,
  conflict,
  serverError,
  networkError,
}

class MentorProfileResult {
  final Mentor? mentor;
  final MentorProfileFailure? failure;
  final String? message;

  const MentorProfileResult.success({required this.mentor})
    : failure = null,
      message = null;

  const MentorProfileResult.failure({required this.failure, this.message})
    : mentor = null;
}

class MentorPinChangeResult {
  final bool success;
  final MentorProfileFailure? failure;
  final String? message;

  const MentorPinChangeResult.success()
    : success = true,
      failure = null,
      message = null;

  const MentorPinChangeResult.failure({required this.failure, this.message})
    : success = false;
}

class MentorProfileApi {
  Future<MentorProfileResult> fetchMyProfile({
    required String accessToken,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/mentor/me');

    try {
      final response = await http.get(uri, headers: _headers(accessToken));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return MentorProfileResult.success(
          mentor: Mentor.fromJson(data as Map<String, dynamic>),
        );
      }

      return MentorProfileResult.failure(
        failure: _failureFromStatusCode(response.statusCode),
        message: _detailFromJson(data),
      );
    } catch (_) {
      return const MentorProfileResult.failure(
        failure: MentorProfileFailure.networkError,
      );
    }
  }

  Future<MentorProfileResult> updateMyProfile({
    required String accessToken,
    required MentorSelfUpdateRequest request,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/mentor/me');

    try {
      final response = await http.put(
        uri,
        headers: _headers(accessToken),
        body: jsonEncode(request.toJson()),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return MentorProfileResult.success(
          mentor: Mentor.fromJson(data as Map<String, dynamic>),
        );
      }

      return MentorProfileResult.failure(
        failure: _failureFromStatusCode(response.statusCode),
        message: _detailFromJson(data),
      );
    } catch (_) {
      return const MentorProfileResult.failure(
        failure: MentorProfileFailure.networkError,
      );
    }
  }

  Future<MentorPinChangeResult> changePin({
    required String accessToken,
    required MentorChangePinRequest request,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/mentor/me/pin');

    try {
      final response = await http.put(
        uri,
        headers: _headers(accessToken),
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 204) {
        return const MentorPinChangeResult.success();
      }

      final data = response.body.isEmpty ? null : jsonDecode(response.body);

      return MentorPinChangeResult.failure(
        failure: _failureFromStatusCode(response.statusCode),
        message: _detailFromJson(data),
      );
    } catch (_) {
      return const MentorPinChangeResult.failure(
        failure: MentorProfileFailure.networkError,
      );
    }
  }

  Map<String, String> _headers(String accessToken) {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $accessToken',
    };
  }

  MentorProfileFailure _failureFromStatusCode(int statusCode) {
    return switch (statusCode) {
      400 || 422 => MentorProfileFailure.badRequest,
      401 => MentorProfileFailure.unauthorized,
      403 => MentorProfileFailure.forbidden,
      409 => MentorProfileFailure.conflict,
      _ => MentorProfileFailure.serverError,
    };
  }

  String? _detailFromJson(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data['detail']?.toString();
    }

    return null;
  }
}
