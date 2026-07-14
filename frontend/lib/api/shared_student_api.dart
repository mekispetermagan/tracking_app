import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/models.dart';

enum SharedStudentFailure {
  badRequest,
  unauthorized,
  forbidden,
  notFound,
  conflict,
  serverError,
  networkError,
}

class SharedStudentListResult {
  final List<Student>? students;
  final SharedStudentFailure? failure;
  final String? message;

  const SharedStudentListResult.success({required this.students})
    : failure = null,
      message = null;

  const SharedStudentListResult.failure({required this.failure, this.message})
    : students = null;
}

class SharedStudentResult {
  final Student? student;
  final SharedStudentFailure? failure;
  final String? message;

  const SharedStudentResult.success({required this.student})
    : failure = null,
      message = null;

  const SharedStudentResult.failure({required this.failure, this.message})
    : student = null;
}

class SharedStudentApi {
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
      final response = await http.get(uri, headers: _headers(accessToken));
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final students = (data as List<dynamic>)
            .map((item) => Student.fromJson(item as Map<String, dynamic>))
            .toList();

        return SharedStudentListResult.success(students: students);
      }

      return SharedStudentListResult.failure(
        failure: _failureFromStatusCode(response.statusCode),
        message: _detailFromJson(data),
      );
    } catch (_) {
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
      final response = await http.get(uri, headers: _headers(accessToken));
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return SharedStudentResult.success(
          student: Student.fromJson(data as Map<String, dynamic>),
        );
      }

      return SharedStudentResult.failure(
        failure: _failureFromStatusCode(response.statusCode),
        message: _detailFromJson(data),
      );
    } catch (_) {
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
      final response = await http.post(
        uri,
        headers: _headers(accessToken),
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return SharedStudentResult.success(
          student: Student.fromJson(data as Map<String, dynamic>),
        );
      }

      return SharedStudentResult.failure(
        failure: _failureFromStatusCode(response.statusCode),
        message: _detailFromJson(data),
      );
    } catch (_) {
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
      final response = await http.put(
        uri,
        headers: _headers(accessToken),
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return SharedStudentResult.success(
          student: Student.fromJson(data as Map<String, dynamic>),
        );
      }

      return SharedStudentResult.failure(
        failure: _failureFromStatusCode(response.statusCode),
        message: _detailFromJson(data),
      );
    } catch (_) {
      return const SharedStudentResult.failure(
        failure: SharedStudentFailure.networkError,
      );
    }
  }

  Map<String, String> _headers(String accessToken) {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $accessToken',
    };
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

  String? _detailFromJson(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data['detail']?.toString();
    }

    return null;
  }
}
