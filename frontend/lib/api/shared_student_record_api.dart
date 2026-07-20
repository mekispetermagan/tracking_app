import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '_api_support.dart';
import 'api_result.dart';
import '../models/models.dart';

enum SharedStudentRecordFailure {
  unauthorized,
  forbidden,
  notFound,
  serverError,
  invalidData,
  networkError,
}

class SharedStudentRecordResult
    extends ApiResult<StudentRecord, SharedStudentRecordFailure> {
  final StudentRecord? studentRecord;

  @override
  final SharedStudentRecordFailure? failure;
  @override
  final String? message;

  const SharedStudentRecordResult.success({required this.studentRecord})
    : failure = null,
      message = null;

  const SharedStudentRecordResult.failure({required this.failure, this.message})
    : studentRecord = null;
}

class SharedStudentRecordApi {
  final http.Client _client;

  SharedStudentRecordApi({http.Client? client})
    : _client = client ?? http.Client();

  Future<SharedStudentRecordResult> fetchStudentRecord({
    required String accessToken,
    required int studentId,
  }) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/shared/students/$studentId/record',
    );

    try {
      final response = await _client.get(
        uri,
        headers: authenticatedHeaders(accessToken, json: true),
      );
      final data = decodeJsonBody(response.body);

      if (response.statusCode == 200) {
        return SharedStudentRecordResult.success(
          studentRecord: StudentRecord.fromJson(data as Map<String, dynamic>),
        );
      }

      return SharedStudentRecordResult.failure(
        failure: _failureFromStatusCode(response.statusCode),
        message: apiDetail(data),
      );
    } catch (error) {
      if (isInvalidApiData(error)) {
        return const SharedStudentRecordResult.failure(
          failure: SharedStudentRecordFailure.invalidData,
        );
      }
      return const SharedStudentRecordResult.failure(
        failure: SharedStudentRecordFailure.networkError,
      );
    }
  }

  SharedStudentRecordFailure _failureFromStatusCode(int statusCode) {
    return switch (statusCode) {
      401 => SharedStudentRecordFailure.unauthorized,
      403 => SharedStudentRecordFailure.forbidden,
      404 => SharedStudentRecordFailure.notFound,
      _ => SharedStudentRecordFailure.serverError,
    };
  }
}
