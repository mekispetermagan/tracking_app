import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/models.dart';

enum MentorSessionLogFailure {
  badRequest,
  unauthorized,
  forbidden,
  notFound,
  conflict,
  serverError,
  networkError,
}

class MentorSessionLogListResult {
  final List<SessionLog>? sessionLogs;
  final MentorSessionLogFailure? failure;
  final String? message;

  const MentorSessionLogListResult.success({required this.sessionLogs})
    : failure = null,
      message = null;

  const MentorSessionLogListResult.failure({
    required this.failure,
    this.message,
  }) : sessionLogs = null;
}

class MentorSessionLogResult {
  final SessionLog? sessionLog;
  final MentorSessionLogFailure? failure;
  final String? message;

  const MentorSessionLogResult.success({required this.sessionLog})
    : failure = null,
      message = null;

  const MentorSessionLogResult.failure({required this.failure, this.message})
    : sessionLog = null;
}

class MentorSessionLogApi {
  Future<MentorSessionLogListResult> fetchAvailableSessionLogs({
    required String accessToken,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/mentor/session-logs');

    try {
      final response = await http.get(uri, headers: _headers(accessToken));
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final sessionLogs = (data as List<dynamic>)
            .map((item) => SessionLog.fromJson(item as Map<String, dynamic>))
            .toList();

        return MentorSessionLogListResult.success(sessionLogs: sessionLogs);
      }

      return MentorSessionLogListResult.failure(
        failure: _failureFromStatusCode(response.statusCode),
        message: _detailFromJson(data),
      );
    } catch (_) {
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
      final response = await http.post(
        uri,
        headers: _headers(accessToken),
        body: jsonEncode(request.toJson()),
      );
      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return MentorSessionLogResult.success(
          sessionLog: SessionLog.fromJson(data as Map<String, dynamic>),
        );
      }

      return MentorSessionLogResult.failure(
        failure: _failureFromStatusCode(response.statusCode),
        message: _detailFromJson(data),
      );
    } catch (_) {
      return const MentorSessionLogResult.failure(
        failure: MentorSessionLogFailure.networkError,
      );
    }
  }

  Map<String, String> _headers(String accessToken) {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $accessToken',
    };
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

  String? _detailFromJson(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data['detail']?.toString();
    }

    return null;
  }
}
