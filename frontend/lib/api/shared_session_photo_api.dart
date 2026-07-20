import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '_api_support.dart';
import 'api_result.dart';
import '../models/models.dart';

enum SharedSessionPhotoFailure {
  badRequest,
  unauthorized,
  forbidden,
  notFound,
  serverError,
  invalidData,
  networkError,
}

class SharedSessionPhotoListResult
    extends ApiResult<List<SessionPhoto>, SharedSessionPhotoFailure> {
  final List<SessionPhoto>? photos;

  @override
  final SharedSessionPhotoFailure? failure;
  @override
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
  final http.Client _client;

  SharedSessionPhotoApi({http.Client? client})
    : _client = client ?? http.Client();

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
      final response = await _client.get(
        uri,
        headers: authenticatedHeaders(accessToken),
      );

      final data = decodeJsonBody(response.body);

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
        message: apiDetail(data),
      );
    } catch (error) {
      if (isInvalidApiData(error)) {
        return const SharedSessionPhotoListResult.failure(
          failure: SharedSessionPhotoFailure.invalidData,
        );
      }
      return const SharedSessionPhotoListResult.failure(
        failure: SharedSessionPhotoFailure.networkError,
      );
    }
  }

  Map<String, dynamic> _withAbsoluteUrl(Map<String, dynamic> json) {
    final result = Map<String, dynamic>.from(json);
    final url = result['url'] as String;

    if (url.startsWith('/')) {
      result['url'] = absoluteApiUrl(url);
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
}
