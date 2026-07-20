import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '_api_support.dart';
import 'api_result.dart';
import '../models/models.dart';

enum SharedCourseFailure {
  badRequest,
  unauthorized,
  forbidden,
  notFound,
  conflict,
  serverError,
  invalidData,
  networkError,
}

class SharedCourseListResult
    extends ApiResult<List<Course>, SharedCourseFailure> {
  final List<Course>? courses;

  @override
  final SharedCourseFailure? failure;
  @override
  final String? message;

  const SharedCourseListResult.success({required this.courses})
    : failure = null,
      message = null;

  const SharedCourseListResult.failure({required this.failure, this.message})
    : courses = null;
}

class SharedCourseResult extends ApiResult<Course, SharedCourseFailure> {
  final Course? course;

  @override
  final SharedCourseFailure? failure;
  @override
  final String? message;

  const SharedCourseResult.success({required this.course})
    : failure = null,
      message = null;

  const SharedCourseResult.failure({required this.failure, this.message})
    : course = null;
}

class SharedCourseApi {
  final http.Client _client;

  SharedCourseApi({http.Client? client}) : _client = client ?? http.Client();

  Future<SharedCourseListResult> fetchCourses({
    required String accessToken,
    bool activeOnly = true,
  }) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/shared/courses',
    ).replace(queryParameters: {'active_only': activeOnly.toString()});

    try {
      final response = await _client.get(
        uri,
        headers: authenticatedHeaders(accessToken, json: true),
      );
      final data = decodeJsonBody(response.body);

      if (response.statusCode == 200) {
        final courses = (data as List<dynamic>)
            .map((item) => Course.fromJson(item as Map<String, dynamic>))
            .toList();

        return SharedCourseListResult.success(courses: courses);
      }

      return SharedCourseListResult.failure(
        failure: _failureFromStatusCode(response.statusCode),
        message: apiDetail(data),
      );
    } catch (error) {
      if (isInvalidApiData(error)) {
        return const SharedCourseListResult.failure(
          failure: SharedCourseFailure.invalidData,
        );
      }
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
      final response = await _client.get(
        uri,
        headers: authenticatedHeaders(accessToken, json: true),
      );
      final data = decodeJsonBody(response.body);

      if (response.statusCode == 200) {
        return SharedCourseResult.success(
          course: Course.fromJson(data as Map<String, dynamic>),
        );
      }

      return SharedCourseResult.failure(
        failure: _failureFromStatusCode(response.statusCode),
        message: apiDetail(data),
      );
    } catch (error) {
      if (isInvalidApiData(error)) {
        return const SharedCourseResult.failure(
          failure: SharedCourseFailure.invalidData,
        );
      }
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
      final response = await _client.put(
        uri,
        headers: authenticatedHeaders(accessToken, json: true),
        body: jsonEncode(request.toJson()),
      );

      final data = decodeJsonBody(response.body);

      if (response.statusCode == 200) {
        return SharedCourseResult.success(
          course: Course.fromJson(data as Map<String, dynamic>),
        );
      }

      return SharedCourseResult.failure(
        failure: _failureFromStatusCode(response.statusCode),
        message: apiDetail(data),
      );
    } catch (error) {
      if (isInvalidApiData(error)) {
        return const SharedCourseResult.failure(
          failure: SharedCourseFailure.invalidData,
        );
      }
      return const SharedCourseResult.failure(
        failure: SharedCourseFailure.networkError,
      );
    }
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
}
