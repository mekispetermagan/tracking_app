import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/models.dart';

enum AdminSessionLogFailure {
  badRequest,
  unauthorized,
  forbidden,
  serverError,
  networkError,
}

class AdminSessionLogListResult {
  final List<SessionLog>? sessionLogs;
  final AdminSessionLogFailure? failure;
  final String? message;

  const AdminSessionLogListResult.success({required this.sessionLogs})
    : failure = null,
      message = null;

  const AdminSessionLogListResult.failure({required this.failure, this.message})
    : sessionLogs = null;
}

class AdminSessionLogApi {
  Future<AdminSessionLogListResult> fetchSessionLogs({
    required String accessToken,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/admin/session-logs');

    try {
      final response = await http.get(uri, headers: _headers(accessToken));
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final sessionLogs = (data as List<dynamic>)
            .map((item) => SessionLog.fromJson(item as Map<String, dynamic>))
            .toList();

        return AdminSessionLogListResult.success(sessionLogs: sessionLogs);
      }

      return AdminSessionLogListResult.failure(
        failure: _failureFromStatusCode(response.statusCode),
        message: _detailFromJson(data),
      );
    } catch (_) {
      return const AdminSessionLogListResult.failure(
        failure: AdminSessionLogFailure.networkError,
      );
    }
  }

  Map<String, String> _headers(String accessToken) {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $accessToken',
    };
  }

  AdminSessionLogFailure _failureFromStatusCode(int statusCode) {
    return switch (statusCode) {
      400 || 422 => AdminSessionLogFailure.badRequest,
      401 => AdminSessionLogFailure.unauthorized,
      403 => AdminSessionLogFailure.forbidden,
      _ => AdminSessionLogFailure.serverError,
    };
  }

  String? _detailFromJson(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data['detail']?.toString();
    }

    return null;
  }
}
