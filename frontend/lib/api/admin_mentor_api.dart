import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/models.dart';

enum AdminMentorFailure {
  badRequest,
  unauthorized,
  forbidden,
  notFound,
  conflict,
  serverError,
  networkError,
}

class AdminMentorListResult {
  final List<Mentor>? mentors;
  final AdminMentorFailure? failure;
  final String? message;

  const AdminMentorListResult.success({required this.mentors})
    : failure = null,
      message = null;

  const AdminMentorListResult.failure({required this.failure, this.message})
    : mentors = null;
}

class AdminMentorResult {
  final Mentor? mentor;
  final AdminMentorFailure? failure;
  final String? message;

  const AdminMentorResult.success({required this.mentor})
    : failure = null,
      message = null;

  const AdminMentorResult.failure({required this.failure, this.message})
    : mentor = null;
}

class AdminMentorApi {
  Future<AdminMentorListResult> fetchMentors({
    required String accessToken,
    bool activeOnly = false,
  }) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/admin/mentors',
    ).replace(queryParameters: {if (activeOnly) 'active_only': 'true'});

    try {
      final response = await http.get(uri, headers: _headers(accessToken));
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final mentors = (data as List<dynamic>)
            .map((item) => Mentor.fromJson(item as Map<String, dynamic>))
            .toList();

        return AdminMentorListResult.success(mentors: mentors);
      }

      return AdminMentorListResult.failure(
        failure: _failureFromStatusCode(response.statusCode),
        message: _detailFromJson(data),
      );
    } catch (_) {
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
      final response = await http.get(uri, headers: _headers(accessToken));
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return AdminMentorResult.success(
          mentor: Mentor.fromJson(data as Map<String, dynamic>),
        );
      }

      return AdminMentorResult.failure(
        failure: _failureFromStatusCode(response.statusCode),
        message: _detailFromJson(data),
      );
    } catch (_) {
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
      final response = await http.post(
        uri,
        headers: _headers(accessToken),
        body: jsonEncode(request.toJson()),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return AdminMentorResult.success(
          mentor: Mentor.fromJson(data as Map<String, dynamic>),
        );
      }

      return AdminMentorResult.failure(
        failure: _failureFromStatusCode(response.statusCode),
        message: _detailFromJson(data),
      );
    } catch (_) {
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
      final response = await http.put(
        uri,
        headers: _headers(accessToken),
        body: jsonEncode(request.toJson()),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return AdminMentorResult.success(
          mentor: Mentor.fromJson(data as Map<String, dynamic>),
        );
      }

      return AdminMentorResult.failure(
        failure: _failureFromStatusCode(response.statusCode),
        message: _detailFromJson(data),
      );
    } catch (_) {
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
      final response = await http.post(uri, headers: _headers(accessToken));
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return AdminMentorResult.success(
          mentor: Mentor.fromJson(data as Map<String, dynamic>),
        );
      }

      return AdminMentorResult.failure(
        failure: _failureFromStatusCode(response.statusCode),
        message: _detailFromJson(data),
      );
    } catch (_) {
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
      final response = await http.post(
        uri,
        headers: _headers(accessToken),
        body: jsonEncode(request.toJson()),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return AdminMentorResult.success(
          mentor: Mentor.fromJson(data as Map<String, dynamic>),
        );
      }

      return AdminMentorResult.failure(
        failure: _failureFromStatusCode(response.statusCode),
        message: _detailFromJson(data),
      );
    } catch (_) {
      return const AdminMentorResult.failure(
        failure: AdminMentorFailure.networkError,
      );
    }
  }

  Map<String, String> _headers(String accessToken) {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $accessToken',
    };
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

  String? _detailFromJson(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data['detail']?.toString();
    }

    return null;
  }
}
