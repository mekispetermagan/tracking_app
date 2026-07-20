import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '_api_support.dart';
import 'api_result.dart';
import '../models/models.dart';

enum AdminCourseVisitFailure {
  badRequest,
  unauthorized,
  forbidden,
  notFound,
  conflict,
  serverError,
  invalidData,
  networkError,
}

class AdminCourseVisitListResult
    extends ApiResult<List<CourseVisitReport>, AdminCourseVisitFailure> {
  final List<CourseVisitReport>? reports;

  @override
  final AdminCourseVisitFailure? failure;
  @override
  final String? message;

  const AdminCourseVisitListResult.success({required this.reports})
    : failure = null,
      message = null;

  const AdminCourseVisitListResult.failure({
    required this.failure,
    this.message,
  }) : reports = null;
}

class AdminCourseVisitResult
    extends ApiResult<CourseVisitReport, AdminCourseVisitFailure> {
  final CourseVisitReport? report;

  @override
  final AdminCourseVisitFailure? failure;
  @override
  final String? message;

  const AdminCourseVisitResult.success({required this.report})
    : failure = null,
      message = null;

  const AdminCourseVisitResult.failure({required this.failure, this.message})
    : report = null;
}

class AdminCourseVisitApi {
  final http.Client _client;

  AdminCourseVisitApi({http.Client? client})
    : _client = client ?? http.Client();

  Future<AdminCourseVisitListResult> fetchReports({
    required String accessToken,
  }) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/admin/'
      'course-visit-reports',
    );

    try {
      final response = await _client.get(
        uri,
        headers: authenticatedHeaders(accessToken, json: true),
      );
      final data = decodeJsonBody(response.body);

      if (response.statusCode == 200) {
        final reports = (data as List<dynamic>)
            .map(
              (item) =>
                  CourseVisitReport.fromJson(item as Map<String, dynamic>),
            )
            .toList();

        return AdminCourseVisitListResult.success(reports: reports);
      }

      return AdminCourseVisitListResult.failure(
        failure: _failureFromStatusCode(response.statusCode),
        message: apiDetail(data),
      );
    } catch (error) {
      if (isInvalidApiData(error)) {
        return const AdminCourseVisitListResult.failure(
          failure: AdminCourseVisitFailure.invalidData,
        );
      }
      return const AdminCourseVisitListResult.failure(
        failure: AdminCourseVisitFailure.networkError,
      );
    }
  }

  Future<AdminCourseVisitResult> submitReport({
    required String accessToken,
    required CourseVisitReportCreateRequest request,
  }) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/admin/'
      'course-visit-reports',
    );

    try {
      final response = await _client.post(
        uri,
        headers: authenticatedHeaders(accessToken, json: true),
        body: jsonEncode(request.toJson()),
      );
      final data = decodeJsonBody(response.body);

      if (response.statusCode == 201) {
        return AdminCourseVisitResult.success(
          report: CourseVisitReport.fromJson(data as Map<String, dynamic>),
        );
      }

      return AdminCourseVisitResult.failure(
        failure: _failureFromStatusCode(response.statusCode),
        message: apiDetail(data),
      );
    } catch (error) {
      if (isInvalidApiData(error)) {
        return const AdminCourseVisitResult.failure(
          failure: AdminCourseVisitFailure.invalidData,
        );
      }
      return const AdminCourseVisitResult.failure(
        failure: AdminCourseVisitFailure.networkError,
      );
    }
  }

  AdminCourseVisitFailure _failureFromStatusCode(int statusCode) {
    return switch (statusCode) {
      400 || 422 => AdminCourseVisitFailure.badRequest,
      401 => AdminCourseVisitFailure.unauthorized,
      403 => AdminCourseVisitFailure.forbidden,
      404 => AdminCourseVisitFailure.notFound,
      409 => AdminCourseVisitFailure.conflict,
      _ => AdminCourseVisitFailure.serverError,
    };
  }
}
