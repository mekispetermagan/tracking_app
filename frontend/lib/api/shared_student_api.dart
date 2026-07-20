import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '_api_support.dart';
import 'api_result.dart';
import '../models/models.dart';

enum SharedStudentFailure {
  badRequest,
  unauthorized,
  forbidden,
  notFound,
  conflict,
  serverError,
  invalidData,
  networkError,
}

class SharedStudentListResult
    extends ApiResult<List<Student>, SharedStudentFailure> {
  final List<Student>? students;

  @override
  final SharedStudentFailure? failure;
  @override
  final String? message;

  const SharedStudentListResult.success({required this.students})
    : failure = null,
      message = null;

  const SharedStudentListResult.failure({required this.failure, this.message})
    : students = null;
}

class SharedStudentResult extends ApiResult<Student, SharedStudentFailure> {
  final Student? student;

  @override
  final SharedStudentFailure? failure;
  @override
  final String? message;

  const SharedStudentResult.success({required this.student})
    : failure = null,
      message = null;

  const SharedStudentResult.failure({required this.failure, this.message})
    : student = null;
}

class SharedStudentApi {
  final http.Client _client;

  SharedStudentApi({http.Client? client}) : _client = client ?? http.Client();

  Future<SharedStudentListResult> fetchStudents({
    required String accessToken,
    bool activeOnly = true,
    int? courseId,
  }) async {
    final queryParameters = <String, String>{
      'active_only': activeOnly.toString(),
    };

    if (courseId != null) {
      queryParameters['course_id'] = courseId.toString();
    }

    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/shared/students',
    ).replace(queryParameters: queryParameters);

    try {
      final response = await _client.get(
        uri,
        headers: authenticatedHeaders(accessToken, json: true),
      );
      final data = decodeJsonBody(response.body);

      if (response.statusCode == 200) {
        final students = (data as List<dynamic>)
            .map((item) => Student.fromJson(item as Map<String, dynamic>))
            .toList();

        return SharedStudentListResult.success(students: students);
      }

      return SharedStudentListResult.failure(
        failure: _failureFromStatusCode(response.statusCode),
        message: apiDetail(data),
      );
    } catch (error) {
      if (isInvalidApiData(error)) {
        return const SharedStudentListResult.failure(
          failure: SharedStudentFailure.invalidData,
        );
      }
      return const SharedStudentListResult.failure(
        failure: SharedStudentFailure.networkError,
      );
    }
  }

  Future<SharedStudentResult> fetchStudent({
    required String accessToken,
    required int studentId,
  }) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/shared/students/$studentId',
    );

    try {
      final response = await _client.get(
        uri,
        headers: authenticatedHeaders(accessToken, json: true),
      );
      final data = decodeJsonBody(response.body);

      if (response.statusCode == 200) {
        return SharedStudentResult.success(
          student: Student.fromJson(data as Map<String, dynamic>),
        );
      }

      return SharedStudentResult.failure(
        failure: _failureFromStatusCode(response.statusCode),
        message: apiDetail(data),
      );
    } catch (error) {
      if (isInvalidApiData(error)) {
        return const SharedStudentResult.failure(
          failure: SharedStudentFailure.invalidData,
        );
      }
      return const SharedStudentResult.failure(
        failure: SharedStudentFailure.networkError,
      );
    }
  }

  Future<SharedStudentResult> createStudent({
    required String accessToken,
    required StudentCreateRequest request,
  }) {
    return _createStudent(accessToken: accessToken, body: request.toJson());
  }

  Future<SharedStudentResult> createStudentAsMentor({
    required String accessToken,
    required MentorStudentCreateRequest request,
  }) {
    return _createStudent(accessToken: accessToken, body: request.toJson());
  }

  Future<SharedStudentResult> updateStudent({
    required String accessToken,
    required int studentId,
    required StudentUpdateRequest request,
  }) {
    return _updateStudent(
      accessToken: accessToken,
      studentId: studentId,
      body: request.toJson(),
    );
  }

  Future<SharedStudentResult> updateStudentAsMentor({
    required String accessToken,
    required int studentId,
    required MentorStudentUpdateRequest request,
  }) {
    return _updateStudent(
      accessToken: accessToken,
      studentId: studentId,
      body: request.toJson(),
    );
  }

  Future<SharedStudentResult> _createStudent({
    required String accessToken,
    required Map<String, dynamic> body,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/shared/students');

    try {
      final response = await _client.post(
        uri,
        headers: authenticatedHeaders(accessToken, json: true),
        body: jsonEncode(body),
      );

      final data = decodeJsonBody(response.body);

      if (response.statusCode == 200) {
        return SharedStudentResult.success(
          student: Student.fromJson(data as Map<String, dynamic>),
        );
      }

      return SharedStudentResult.failure(
        failure: _failureFromStatusCode(response.statusCode),
        message: apiDetail(data),
      );
    } catch (error) {
      if (isInvalidApiData(error)) {
        return const SharedStudentResult.failure(
          failure: SharedStudentFailure.invalidData,
        );
      }
      return const SharedStudentResult.failure(
        failure: SharedStudentFailure.networkError,
      );
    }
  }

  Future<SharedStudentResult> _updateStudent({
    required String accessToken,
    required int studentId,
    required Map<String, dynamic> body,
  }) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/shared/students/$studentId',
    );

    try {
      final response = await _client.put(
        uri,
        headers: authenticatedHeaders(accessToken, json: true),
        body: jsonEncode(body),
      );

      final data = decodeJsonBody(response.body);

      if (response.statusCode == 200) {
        return SharedStudentResult.success(
          student: Student.fromJson(data as Map<String, dynamic>),
        );
      }

      return SharedStudentResult.failure(
        failure: _failureFromStatusCode(response.statusCode),
        message: apiDetail(data),
      );
    } catch (error) {
      if (isInvalidApiData(error)) {
        return const SharedStudentResult.failure(
          failure: SharedStudentFailure.invalidData,
        );
      }
      return const SharedStudentResult.failure(
        failure: SharedStudentFailure.networkError,
      );
    }
  }

  SharedStudentFailure _failureFromStatusCode(int statusCode) {
    return switch (statusCode) {
      400 || 422 => SharedStudentFailure.badRequest,
      401 => SharedStudentFailure.unauthorized,
      403 => SharedStudentFailure.forbidden,
      404 => SharedStudentFailure.notFound,
      409 => SharedStudentFailure.conflict,
      _ => SharedStudentFailure.serverError,
    };
  }
}
