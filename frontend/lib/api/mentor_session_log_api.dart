import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '_api_support.dart';
import 'api_result.dart';
import '../models/models.dart';

enum MentorSessionLogFailure {
  badRequest,
  unauthorized,
  forbidden,
  notFound,
  conflict,
  serverError,
  invalidData,
  networkError,
}

class MentorSessionLogListResult
    extends ApiResult<List<SessionLog>, MentorSessionLogFailure> {
  final List<SessionLog>? sessionLogs;

  @override
  final MentorSessionLogFailure? failure;
  @override
  final String? message;

  const MentorSessionLogListResult.success({required this.sessionLogs})
    : failure = null,
      message = null;

  const MentorSessionLogListResult.failure({
    required this.failure,
    this.message,
  }) : sessionLogs = null;
}

class MentorSessionLogResult
    extends ApiResult<SessionLog, MentorSessionLogFailure> {
  final SessionLog? sessionLog;

  @override
  final MentorSessionLogFailure? failure;
  @override
  final String? message;

  const MentorSessionLogResult.success({required this.sessionLog})
    : failure = null,
      message = null;

  const MentorSessionLogResult.failure({required this.failure, this.message})
    : sessionLog = null;
}

class MentorSessionLogApi {
  final http.Client _client;

  MentorSessionLogApi({http.Client? client})
    : _client = client ?? http.Client();

  Future<MentorSessionLogListResult> fetchAvailableSessionLogs({
    required String accessToken,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/mentor/session-logs');

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

        return MentorSessionLogListResult.success(sessionLogs: sessionLogs);
      }

      return MentorSessionLogListResult.failure(
        failure: _failureFromStatusCode(response.statusCode),
        message: apiDetail(data),
      );
    } catch (error) {
      if (isInvalidApiData(error)) {
        return const MentorSessionLogListResult.failure(
          failure: MentorSessionLogFailure.invalidData,
        );
      }
      return const MentorSessionLogListResult.failure(
        failure: MentorSessionLogFailure.networkError,
      );
    }
  }

  Future<MentorSessionLogResult> submitSessionLog({
    required String accessToken,
    required SessionLogCreateRequest request,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/mentor/session-logs');

    try {
      final response = await _client.post(
        uri,
        headers: authenticatedHeaders(accessToken, json: true),
        body: jsonEncode(request.toJson()),
      );
      final data = decodeJsonBody(response.body);

      if (response.statusCode == 201) {
        return MentorSessionLogResult.success(
          sessionLog: SessionLog.fromJson(data as Map<String, dynamic>),
        );
      }

      return MentorSessionLogResult.failure(
        failure: _failureFromStatusCode(response.statusCode),
        message: apiDetail(data),
      );
    } catch (error) {
      if (isInvalidApiData(error)) {
        return const MentorSessionLogResult.failure(
          failure: MentorSessionLogFailure.invalidData,
        );
      }
      return const MentorSessionLogResult.failure(
        failure: MentorSessionLogFailure.networkError,
      );
    }
  }

  MentorSessionLogFailure _failureFromStatusCode(int statusCode) {
    return switch (statusCode) {
      400 || 422 => MentorSessionLogFailure.badRequest,
      401 => MentorSessionLogFailure.unauthorized,
      403 => MentorSessionLogFailure.forbidden,
      404 => MentorSessionLogFailure.notFound,
      409 => MentorSessionLogFailure.conflict,
      _ => MentorSessionLogFailure.serverError,
    };
  }
}
