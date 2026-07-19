import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/models.dart';

enum AdminCourseVisitFailure {
  badRequest,
  unauthorized,
  forbidden,
  notFound,
  conflict,
  serverError,
  networkError,
}

class AdminCourseVisitListResult {
  final List<CourseVisitReport>? reports;
  final AdminCourseVisitFailure? failure;
  final String? message;

  const AdminCourseVisitListResult.success({required this.reports})
    : failure = null,
      message = null;

  const AdminCourseVisitListResult.failure({
    required this.failure,
    this.message,
  }) : reports = null;
}

class AdminCourseVisitResult {
  final CourseVisitReport? report;
  final AdminCourseVisitFailure? failure;
  final String? message;

  const AdminCourseVisitResult.success({required this.report})
    : failure = null,
      message = null;

  const AdminCourseVisitResult.failure({required this.failure, this.message})
    : report = null;
}

class AdminCourseVisitApi {
  Future<AdminCourseVisitListResult> fetchReports({
    required String accessToken,
  }) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/admin/'
      'course-visit-reports',
    );

    try {
      final response = await http.get(uri, headers: _headers(accessToken));
      final data = jsonDecode(response.body);

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
        message: _detailFromJson(data),
      );
    } catch (_) {
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
      final response = await http.post(
        uri,
        headers: _headers(accessToken),
        body: jsonEncode(request.toJson()),
      );
      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return AdminCourseVisitResult.success(
          report: CourseVisitReport.fromJson(data as Map<String, dynamic>),
        );
      }

      return AdminCourseVisitResult.failure(
        failure: _failureFromStatusCode(response.statusCode),
        message: _detailFromJson(data),
      );
    } catch (_) {
      return const AdminCourseVisitResult.failure(
        failure: AdminCourseVisitFailure.networkError,
      );
    }
  }

  Map<String, String> _headers(String accessToken) {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $accessToken',
    };
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

  String? _detailFromJson(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data['detail']?.toString();
    }

    return null;
  }
}
