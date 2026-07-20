import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '_api_support.dart';
import 'api_result.dart';
import '../models/models.dart';

enum AdminCourseFailure {
  badRequest,
  unauthorized,
  forbidden,
  notFound,
  conflict,
  serverError,
  invalidData,
  networkError,
}

class AdminCourseResult extends ApiResult<Course, AdminCourseFailure> {
  final Course? course;

  @override
  final AdminCourseFailure? failure;
  @override
  final String? message;

  const AdminCourseResult.success({required this.course})
    : failure = null,
      message = null;

  const AdminCourseResult.failure({required this.failure, this.message})
    : course = null;
}

class AdminCourseApi {
  final http.Client _client;

  AdminCourseApi({http.Client? client}) : _client = client ?? http.Client();

  Future<AdminCourseResult> createCourse({
    required String accessToken,
    required CourseCreateRequest request,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/admin/courses');

    try {
      final response = await _client.post(
        uri,
        headers: authenticatedHeaders(accessToken, json: true),
        body: jsonEncode(request.toJson()),
      );

      final data = decodeJsonBody(response.body);

      if (response.statusCode == 200) {
        return AdminCourseResult.success(
          course: Course.fromJson(data as Map<String, dynamic>),
        );
      }

      return AdminCourseResult.failure(
        failure: _failureFromStatusCode(response.statusCode),
        message: apiDetail(data),
      );
    } catch (error) {
      if (isInvalidApiData(error)) {
        return const AdminCourseResult.failure(
          failure: AdminCourseFailure.invalidData,
        );
      }
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
      final response = await _client.post(
        uri,
        headers: authenticatedHeaders(accessToken, json: true),
      );
      final data = decodeJsonBody(response.body);

      if (response.statusCode == 200) {
        return AdminCourseResult.success(
          course: Course.fromJson(data as Map<String, dynamic>),
        );
      }

      return AdminCourseResult.failure(
        failure: _failureFromStatusCode(response.statusCode),
        message: apiDetail(data),
      );
    } catch (error) {
      if (isInvalidApiData(error)) {
        return const AdminCourseResult.failure(
          failure: AdminCourseFailure.invalidData,
        );
      }
      return const AdminCourseResult.failure(
        failure: AdminCourseFailure.networkError,
      );
    }
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
}
