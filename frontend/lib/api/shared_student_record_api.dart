import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/models.dart';

enum SharedStudentRecordFailure {
  unauthorized,
  forbidden,
  notFound,
  serverError,
  networkError,
}

class SharedStudentRecordResult {
  final StudentRecord? studentRecord;
  final SharedStudentRecordFailure? failure;
  final String? message;

  const SharedStudentRecordResult.success({required this.studentRecord})
    : failure = null,
      message = null;

  const SharedStudentRecordResult.failure({required this.failure, this.message})
    : studentRecord = null;
}

class SharedStudentRecordApi {
  Future<SharedStudentRecordResult> fetchStudentRecord({
    required String accessToken,
    required int studentId,
  }) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/shared/students/$studentId/record',
    );

    try {
      final response = await http.get(uri, headers: _headers(accessToken));
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return SharedStudentRecordResult.success(
          studentRecord: StudentRecord.fromJson(data as Map<String, dynamic>),
        );
      }

      return SharedStudentRecordResult.failure(
        failure: _failureFromStatusCode(response.statusCode),
        message: _detailFromJson(data),
      );
    } catch (_) {
      return const SharedStudentRecordResult.failure(
        failure: SharedStudentRecordFailure.networkError,
      );
    }
  }

  Map<String, String> _headers(String accessToken) {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $accessToken',
    };
  }

  SharedStudentRecordFailure _failureFromStatusCode(int statusCode) {
    return switch (statusCode) {
      401 => SharedStudentRecordFailure.unauthorized,
      403 => SharedStudentRecordFailure.forbidden,
      404 => SharedStudentRecordFailure.notFound,
      _ => SharedStudentRecordFailure.serverError,
    };
  }

  String? _detailFromJson(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data['detail']?.toString();
    }

    return null;
  }
}
