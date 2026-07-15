import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/models.dart';

enum SharedCourseMentorsFailure {
  badRequest,
  unauthorized,
  forbidden,
  notFound,
  serverError,
  networkError,
}

class SharedCourseMentorListResult {
  final List<SharedMentor>? mentors;
  final SharedCourseMentorsFailure? failure;
  final String? message;

  const SharedCourseMentorListResult.success({required this.mentors})
    : failure = null,
      message = null;

  const SharedCourseMentorListResult.failure({
    required this.failure,
    this.message,
  }) : mentors = null;
}

class SharedCourseMentorsApi {
  Future<SharedCourseMentorListResult> fetchCourseMentors({
    required String accessToken,
    required int courseId,
  }) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/shared/mentors',
    ).replace(queryParameters: {'course_id': courseId.toString()});

    try {
      final response = await http.get(uri, headers: _headers(accessToken));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final mentors = (data as List<dynamic>)
            .map((item) => SharedMentor.fromJson(item as Map<String, dynamic>))
            .toList();

        return SharedCourseMentorListResult.success(mentors: mentors);
      }

      return SharedCourseMentorListResult.failure(
        failure: _failureFromStatusCode(response.statusCode),
        message: _detailFromJson(data),
      );
    } catch (_) {
      return const SharedCourseMentorListResult.failure(
        failure: SharedCourseMentorsFailure.networkError,
      );
    }
  }

  Map<String, String> _headers(String accessToken) {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $accessToken',
    };
  }

  SharedCourseMentorsFailure _failureFromStatusCode(int statusCode) {
    return switch (statusCode) {
      400 || 422 => SharedCourseMentorsFailure.badRequest,
      401 => SharedCourseMentorsFailure.unauthorized,
      403 => SharedCourseMentorsFailure.forbidden,
      404 => SharedCourseMentorsFailure.notFound,
      _ => SharedCourseMentorsFailure.serverError,
    };
  }

  String? _detailFromJson(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data['detail']?.toString();
    }

    return null;
  }
}
