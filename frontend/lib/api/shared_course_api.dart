import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/models.dart';

enum SharedCourseFailure {
  badRequest,
  unauthorized,
  forbidden,
  notFound,
  conflict,
  serverError,
  networkError,
}

class SharedCourseListResult {
  final List<Course>? courses;
  final SharedCourseFailure? failure;
  final String? message;

  const SharedCourseListResult.success({required this.courses})
    : failure = null,
      message = null;

  const SharedCourseListResult.failure({required this.failure, this.message})
    : courses = null;
}

class SharedCourseResult {
  final Course? course;
  final SharedCourseFailure? failure;
  final String? message;

  const SharedCourseResult.success({required this.course})
    : failure = null,
      message = null;

  const SharedCourseResult.failure({required this.failure, this.message})
    : course = null;
}

class SharedCourseApi {
  Future<SharedCourseListResult> fetchCourses({
    required String accessToken,
    bool activeOnly = true,
  }) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/shared/courses',
    ).replace(queryParameters: {'active_only': activeOnly.toString()});

    try {
      final response = await http.get(uri, headers: _headers(accessToken));
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final courses = (data as List<dynamic>)
            .map((item) => Course.fromJson(item as Map<String, dynamic>))
            .toList();

        return SharedCourseListResult.success(courses: courses);
      }

      return SharedCourseListResult.failure(
        failure: _failureFromStatusCode(response.statusCode),
        message: _detailFromJson(data),
      );
    } catch (_) {
      return const SharedCourseListResult.failure(
        failure: SharedCourseFailure.networkError,
      );
    }
  }

  Future<SharedCourseResult> fetchCourse({
    required String accessToken,
    required int courseId,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/shared/courses/$courseId');

    try {
      final response = await http.get(uri, headers: _headers(accessToken));
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return SharedCourseResult.success(
          course: Course.fromJson(data as Map<String, dynamic>),
        );
      }

      return SharedCourseResult.failure(
        failure: _failureFromStatusCode(response.statusCode),
        message: _detailFromJson(data),
      );
    } catch (_) {
      return const SharedCourseResult.failure(
        failure: SharedCourseFailure.networkError,
      );
    }
  }

  Future<SharedCourseResult> updateCourse({
    required String accessToken,
    required int courseId,
    required CourseUpdateRequest request,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/shared/courses/$courseId');

    try {
      final response = await http.put(
        uri,
        headers: _headers(accessToken),
        body: jsonEncode(request.toJson()),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return SharedCourseResult.success(
          course: Course.fromJson(data as Map<String, dynamic>),
        );
      }

      return SharedCourseResult.failure(
        failure: _failureFromStatusCode(response.statusCode),
        message: _detailFromJson(data),
      );
    } catch (_) {
      return const SharedCourseResult.failure(
        failure: SharedCourseFailure.networkError,
      );
    }
  }

  Map<String, String> _headers(String accessToken) {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $accessToken',
    };
  }

  SharedCourseFailure _failureFromStatusCode(int statusCode) {
    return switch (statusCode) {
      400 || 422 => SharedCourseFailure.badRequest,
      401 => SharedCourseFailure.unauthorized,
      403 => SharedCourseFailure.forbidden,
      404 => SharedCourseFailure.notFound,
      409 => SharedCourseFailure.conflict,
      _ => SharedCourseFailure.serverError,
    };
  }

  String? _detailFromJson(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data['detail']?.toString();
    }

    return null;
  }
}
