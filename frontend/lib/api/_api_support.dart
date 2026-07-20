import 'dart:convert';

import '../config/api_config.dart';

Map<String, String> authenticatedHeaders(
  String accessToken, {
  bool json = false,
}) {
  return {
    if (json) 'Content-Type': 'application/json',
    'Authorization': 'Bearer $accessToken',
  };
}

Object? decodeJsonBody(String body) {
  if (body.trim().isEmpty) return null;
  return jsonDecode(body);
}

bool isInvalidApiData(Object error) {
  return error is FormatException || error is TypeError;
}

String? apiDetail(Object? data) {
  if (data is Map<String, dynamic>) return data['detail']?.toString();
  return null;
}

String absoluteApiUrl(String url) {
  return url.startsWith('/') ? '${ApiConfig.baseUrl}$url' : url;
}

String apiDate(DateTime date) {
  final year = date.year.toString().padLeft(4, '0');
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}
