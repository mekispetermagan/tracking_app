import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/models.dart';

enum SharedSessionPhotoFailure {
  badRequest,
  unauthorized,
  forbidden,
  notFound,
  serverError,
  networkError,
}

class SharedSessionPhotoListResult {
  final List<SessionPhoto>? photos;
  final SharedSessionPhotoFailure? failure;
  final String? message;

  const SharedSessionPhotoListResult.success({required this.photos})
    : failure = null,
      message = null;

  const SharedSessionPhotoListResult.failure({
    required this.failure,
    this.message,
  }) : photos = null;
}

class SharedSessionPhotoApi {
  Future<SharedSessionPhotoListResult> fetchSessionPhotos({
    required String accessToken,
    required int sessionLogId,
  }) {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/shared/session-logs/'
      '$sessionLogId/photos',
    );

    return _fetchPhotos(uri: uri, accessToken: accessToken);
  }

  Future<SharedSessionPhotoListResult> fetchCoursePhotos({
    required String accessToken,
    required int courseId,
  }) {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/shared/courses/'
      '$courseId/photos',
    );

    return _fetchPhotos(uri: uri, accessToken: accessToken);
  }

  Future<SharedSessionPhotoListResult> _fetchPhotos({
    required Uri uri,
    required String accessToken,
  }) async {
    try {
      final response = await http.get(uri, headers: _headers(accessToken));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final photos = (data as List<dynamic>)
            .map(
              (item) => SessionPhoto.fromJson(
                _withAbsoluteUrl(item as Map<String, dynamic>),
              ),
            )
            .toList();

        return SharedSessionPhotoListResult.success(photos: photos);
      }

      return SharedSessionPhotoListResult.failure(
        failure: _failureFromStatusCode(response.statusCode),
        message: _detailFromJson(data),
      );
    } catch (_) {
      return const SharedSessionPhotoListResult.failure(
        failure: SharedSessionPhotoFailure.networkError,
      );
    }
  }

  Map<String, String> _headers(String accessToken) {
    return {'Authorization': 'Bearer $accessToken'};
  }

  Map<String, dynamic> _withAbsoluteUrl(Map<String, dynamic> json) {
    final result = Map<String, dynamic>.from(json);
    final url = result['url'] as String;

    if (url.startsWith('/')) {
      result['url'] = '${ApiConfig.baseUrl}$url';
    }

    return result;
  }

  SharedSessionPhotoFailure _failureFromStatusCode(int statusCode) {
    return switch (statusCode) {
      400 || 422 => SharedSessionPhotoFailure.badRequest,
      401 => SharedSessionPhotoFailure.unauthorized,
      403 => SharedSessionPhotoFailure.forbidden,
      404 => SharedSessionPhotoFailure.notFound,
      _ => SharedSessionPhotoFailure.serverError,
    };
  }

  String? _detailFromJson(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data['detail']?.toString();
    }

    return null;
  }
}
