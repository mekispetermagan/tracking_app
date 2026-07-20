import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '_api_support.dart';
import 'api_result.dart';
import '../models/models.dart';

enum AdminMentorFailure {
  badRequest,
  unauthorized,
  forbidden,
  notFound,
  conflict,
  serverError,
  invalidData,
  networkError,
}

class AdminMentorListResult
    extends ApiResult<List<Mentor>, AdminMentorFailure> {
  final List<Mentor>? mentors;

  @override
  final AdminMentorFailure? failure;
  @override
  final String? message;

  const AdminMentorListResult.success({required this.mentors})
    : failure = null,
      message = null;

  const AdminMentorListResult.failure({required this.failure, this.message})
    : mentors = null;
}

class AdminMentorResult extends ApiResult<Mentor, AdminMentorFailure> {
  final Mentor? mentor;

  @override
  final AdminMentorFailure? failure;
  @override
  final String? message;

  const AdminMentorResult.success({required this.mentor})
    : failure = null,
      message = null;

  const AdminMentorResult.failure({required this.failure, this.message})
    : mentor = null;
}

class AdminMentorApi {
  final http.Client _client;

  AdminMentorApi({http.Client? client}) : _client = client ?? http.Client();

  Future<AdminMentorListResult> fetchMentors({
    required String accessToken,
    bool activeOnly = false,
  }) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/admin/mentors',
    ).replace(queryParameters: {if (activeOnly) 'active_only': 'true'});

    try {
      final response = await _client.get(
        uri,
        headers: authenticatedHeaders(accessToken, json: true),
      );
      final data = decodeJsonBody(response.body);

      if (response.statusCode == 200) {
        final mentors = (data as List<dynamic>)
            .map((item) => Mentor.fromJson(item as Map<String, dynamic>))
            .toList();

        return AdminMentorListResult.success(mentors: mentors);
      }

      return AdminMentorListResult.failure(
        failure: _failureFromStatusCode(response.statusCode),
        message: apiDetail(data),
      );
    } catch (error) {
      if (isInvalidApiData(error)) {
        return const AdminMentorListResult.failure(
          failure: AdminMentorFailure.invalidData,
        );
      }
      return const AdminMentorListResult.failure(
        failure: AdminMentorFailure.networkError,
      );
    }
  }

  Future<AdminMentorResult> fetchMentor({
    required String accessToken,
    required int mentorId,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/admin/mentors/$mentorId');

    try {
      final response = await _client.get(
        uri,
        headers: authenticatedHeaders(accessToken, json: true),
      );
      final data = decodeJsonBody(response.body);

      if (response.statusCode == 200) {
        return AdminMentorResult.success(
          mentor: Mentor.fromJson(data as Map<String, dynamic>),
        );
      }

      return AdminMentorResult.failure(
        failure: _failureFromStatusCode(response.statusCode),
        message: apiDetail(data),
      );
    } catch (error) {
      if (isInvalidApiData(error)) {
        return const AdminMentorResult.failure(
          failure: AdminMentorFailure.invalidData,
        );
      }
      return const AdminMentorResult.failure(
        failure: AdminMentorFailure.networkError,
      );
    }
  }

  Future<AdminMentorResult> createMentor({
    required String accessToken,
    required MentorCreateRequest request,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/admin/mentors');

    try {
      final response = await _client.post(
        uri,
        headers: authenticatedHeaders(accessToken, json: true),
        body: jsonEncode(request.toJson()),
      );

      final data = decodeJsonBody(response.body);

      if (response.statusCode == 200) {
        return AdminMentorResult.success(
          mentor: Mentor.fromJson(data as Map<String, dynamic>),
        );
      }

      return AdminMentorResult.failure(
        failure: _failureFromStatusCode(response.statusCode),
        message: apiDetail(data),
      );
    } catch (error) {
      if (isInvalidApiData(error)) {
        return const AdminMentorResult.failure(
          failure: AdminMentorFailure.invalidData,
        );
      }
      return const AdminMentorResult.failure(
        failure: AdminMentorFailure.networkError,
      );
    }
  }

  Future<AdminMentorResult> updateMentor({
    required String accessToken,
    required int mentorId,
    required MentorUpdateRequest request,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/admin/mentors/$mentorId');

    try {
      final response = await _client.put(
        uri,
        headers: authenticatedHeaders(accessToken, json: true),
        body: jsonEncode(request.toJson()),
      );

      final data = decodeJsonBody(response.body);

      if (response.statusCode == 200) {
        return AdminMentorResult.success(
          mentor: Mentor.fromJson(data as Map<String, dynamic>),
        );
      }

      return AdminMentorResult.failure(
        failure: _failureFromStatusCode(response.statusCode),
        message: apiDetail(data),
      );
    } catch (error) {
      if (isInvalidApiData(error)) {
        return const AdminMentorResult.failure(
          failure: AdminMentorFailure.invalidData,
        );
      }
      return const AdminMentorResult.failure(
        failure: AdminMentorFailure.networkError,
      );
    }
  }

  Future<AdminMentorResult> deactivateMentor({
    required String accessToken,
    required int mentorId,
  }) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/admin/mentors/$mentorId/deactivate',
    );

    try {
      final response = await _client.post(
        uri,
        headers: authenticatedHeaders(accessToken, json: true),
      );
      final data = decodeJsonBody(response.body);

      if (response.statusCode == 200) {
        return AdminMentorResult.success(
          mentor: Mentor.fromJson(data as Map<String, dynamic>),
        );
      }

      return AdminMentorResult.failure(
        failure: _failureFromStatusCode(response.statusCode),
        message: apiDetail(data),
      );
    } catch (error) {
      if (isInvalidApiData(error)) {
        return const AdminMentorResult.failure(
          failure: AdminMentorFailure.invalidData,
        );
      }
      return const AdminMentorResult.failure(
        failure: AdminMentorFailure.networkError,
      );
    }
  }

  Future<AdminMentorResult> resetMentorPin({
    required String accessToken,
    required int mentorId,
    required MentorResetPinRequest request,
  }) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/admin/mentors/$mentorId/reset-pin',
    );

    try {
      final response = await _client.post(
        uri,
        headers: authenticatedHeaders(accessToken, json: true),
        body: jsonEncode(request.toJson()),
      );

      final data = decodeJsonBody(response.body);

      if (response.statusCode == 200) {
        return AdminMentorResult.success(
          mentor: Mentor.fromJson(data as Map<String, dynamic>),
        );
      }

      return AdminMentorResult.failure(
        failure: _failureFromStatusCode(response.statusCode),
        message: apiDetail(data),
      );
    } catch (error) {
      if (isInvalidApiData(error)) {
        return const AdminMentorResult.failure(
          failure: AdminMentorFailure.invalidData,
        );
      }
      return const AdminMentorResult.failure(
        failure: AdminMentorFailure.networkError,
      );
    }
  }

  AdminMentorFailure _failureFromStatusCode(int statusCode) {
    return switch (statusCode) {
      400 || 422 => AdminMentorFailure.badRequest,
      401 => AdminMentorFailure.unauthorized,
      403 => AdminMentorFailure.forbidden,
      404 => AdminMentorFailure.notFound,
      409 => AdminMentorFailure.conflict,
      _ => AdminMentorFailure.serverError,
    };
  }
}
