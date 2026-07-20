import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '_api_support.dart';
import 'api_result.dart';
import '../models/models.dart';

enum MentorProfileFailure {
  badRequest,
  unauthorized,
  forbidden,
  conflict,
  serverError,
  invalidData,
  networkError,
}

class MentorProfileResult extends ApiResult<Mentor, MentorProfileFailure> {
  final Mentor? mentor;

  @override
  final MentorProfileFailure? failure;
  @override
  final String? message;

  const MentorProfileResult.success({required this.mentor})
    : failure = null,
      message = null;

  const MentorProfileResult.failure({required this.failure, this.message})
    : mentor = null;
}

class MentorPinChangeResult extends ApiResult<bool, MentorProfileFailure> {
  final bool success;
  @override
  final MentorProfileFailure? failure;
  @override
  final String? message;

  const MentorPinChangeResult.success()
    : success = true,
      failure = null,
      message = null;

  const MentorPinChangeResult.failure({required this.failure, this.message})
    : success = false;
}

class MentorProfileApi {
  final http.Client _client;

  MentorProfileApi({http.Client? client}) : _client = client ?? http.Client();

  Future<MentorProfileResult> fetchMyProfile({
    required String accessToken,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/mentor/me');

    try {
      final response = await _client.get(
        uri,
        headers: authenticatedHeaders(accessToken, json: true),
      );

      final data = decodeJsonBody(response.body);

      if (response.statusCode == 200) {
        return MentorProfileResult.success(
          mentor: Mentor.fromJson(data as Map<String, dynamic>),
        );
      }

      return MentorProfileResult.failure(
        failure: _failureFromStatusCode(response.statusCode),
        message: apiDetail(data),
      );
    } catch (error) {
      if (isInvalidApiData(error)) {
        return const MentorProfileResult.failure(
          failure: MentorProfileFailure.invalidData,
        );
      }
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
      final response = await _client.put(
        uri,
        headers: authenticatedHeaders(accessToken, json: true),
        body: jsonEncode(request.toJson()),
      );

      final data = decodeJsonBody(response.body);

      if (response.statusCode == 200) {
        return MentorProfileResult.success(
          mentor: Mentor.fromJson(data as Map<String, dynamic>),
        );
      }

      return MentorProfileResult.failure(
        failure: _failureFromStatusCode(response.statusCode),
        message: apiDetail(data),
      );
    } catch (error) {
      if (isInvalidApiData(error)) {
        return const MentorProfileResult.failure(
          failure: MentorProfileFailure.invalidData,
        );
      }
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
      final response = await _client.put(
        uri,
        headers: authenticatedHeaders(accessToken, json: true),
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 204) {
        return const MentorPinChangeResult.success();
      }

      final data = response.body.isEmpty ? null : decodeJsonBody(response.body);

      return MentorPinChangeResult.failure(
        failure: _failureFromStatusCode(response.statusCode),
        message: apiDetail(data),
      );
    } catch (error) {
      if (isInvalidApiData(error)) {
        return const MentorPinChangeResult.failure(
          failure: MentorProfileFailure.invalidData,
        );
      }
      return const MentorPinChangeResult.failure(
        failure: MentorProfileFailure.networkError,
      );
    }
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
}
