import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '_api_support.dart';
import 'api_result.dart';
import '../models/models.dart';

enum AdminSessionLogFailure {
  badRequest,
  unauthorized,
  forbidden,
  serverError,
  invalidData,
  networkError,
}

class AdminSessionLogListResult
    extends ApiResult<List<SessionLog>, AdminSessionLogFailure> {
  final List<SessionLog>? sessionLogs;

  @override
  final AdminSessionLogFailure? failure;
  @override
  final String? message;

  const AdminSessionLogListResult.success({required this.sessionLogs})
    : failure = null,
      message = null;

  const AdminSessionLogListResult.failure({required this.failure, this.message})
    : sessionLogs = null;
}

class AdminSessionLogApi {
  final http.Client _client;

  AdminSessionLogApi({http.Client? client}) : _client = client ?? http.Client();

  Future<AdminSessionLogListResult> fetchSessionLogs({
    required String accessToken,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/admin/session-logs');

    try {
      final response = await _client.get(
        uri,
        headers: authenticatedHeaders(accessToken, json: true),
      );
      final data = decodeJsonBody(response.body);

      if (response.statusCode == 200) {
        final sessionLogs = (data as List<dynamic>)
            .map((item) => SessionLog.fromJson(item as Map<String, dynamic>))
            .toList();

        return AdminSessionLogListResult.success(sessionLogs: sessionLogs);
      }

      return AdminSessionLogListResult.failure(
        failure: _failureFromStatusCode(response.statusCode),
        message: apiDetail(data),
      );
    } catch (error) {
      if (isInvalidApiData(error)) {
        return const AdminSessionLogListResult.failure(
          failure: AdminSessionLogFailure.invalidData,
        );
      }
      return const AdminSessionLogListResult.failure(
        failure: AdminSessionLogFailure.networkError,
      );
    }
  }

  AdminSessionLogFailure _failureFromStatusCode(int statusCode) {
    return switch (statusCode) {
      400 || 422 => AdminSessionLogFailure.badRequest,
      401 => AdminSessionLogFailure.unauthorized,
      403 => AdminSessionLogFailure.forbidden,
      _ => AdminSessionLogFailure.serverError,
    };
  }
}
