import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/models.dart';

enum AdminCourseFailure {
  badRequest,
  unauthorized,
  forbidden,
  notFound,
  conflict,
  serverError,
  networkError,
}

class AdminCourseResult {
  final Course? course;
  final AdminCourseFailure? failure;
  final String? message;

  const AdminCourseResult.success({required this.course})
    : failure = null,
      message = null;

  const AdminCourseResult.failure({required this.failure, this.message})
    : course = null;
}

class AdminCourseApi {
  Future<AdminCourseResult> createCourse({
    required String accessToken,
    required CourseCreateRequest request,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/admin/courses');

    try {
      final response = await http.post(
        uri,
        headers: _headers(accessToken),
        body: jsonEncode(request.toJson()),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return AdminCourseResult.success(
          course: Course.fromJson(data as Map<String, dynamic>),
        );
      }

      return AdminCourseResult.failure(
        failure: _failureFromStatusCode(response.statusCode),
        message: _detailFromJson(data),
      );
    } catch (_) {
      return const AdminCourseResult.failure(
        failure: AdminCourseFailure.networkError,
      );
    }
  }

  Future<AdminCourseResult> deactivateCourse({
    required String accessToken,
    required int courseId,
  }) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/admin/courses/$courseId/deactivate',
    );

    try {
      final response = await http.post(uri, headers: _headers(accessToken));
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return AdminCourseResult.success(
          course: Course.fromJson(data as Map<String, dynamic>),
        );
      }

      return AdminCourseResult.failure(
        failure: _failureFromStatusCode(response.statusCode),
        message: _detailFromJson(data),
      );
    } catch (_) {
      return const AdminCourseResult.failure(
        failure: AdminCourseFailure.networkError,
      );
    }
  }

  Map<String, String> _headers(String accessToken) {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $accessToken',
    };
  }

  AdminCourseFailure _failureFromStatusCode(int statusCode) {
    return switch (statusCode) {
      400 || 422 => AdminCourseFailure.badRequest,
      401 => AdminCourseFailure.unauthorized,
      403 => AdminCourseFailure.forbidden,
      404 => AdminCourseFailure.notFound,
      409 => AdminCourseFailure.conflict,
      _ => AdminCourseFailure.serverError,
    };
  }

  String? _detailFromJson(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data['detail']?.toString();
    }

    return null;
  }
}
