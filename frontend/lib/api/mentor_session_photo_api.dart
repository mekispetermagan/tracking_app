import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '_api_support.dart';
import 'api_result.dart';
import '../models/models.dart';

enum MentorSessionPhotoFailure {
  badRequest,
  unauthorized,
  forbidden,
  notFound,
  conflict,
  serverError,
  invalidData,
  networkError,
}

class MentorSessionPhotoResult
    extends ApiResult<List<SessionPhoto>, MentorSessionPhotoFailure> {
  final List<SessionPhoto>? photos;

  @override
  final MentorSessionPhotoFailure? failure;
  @override
  final String? message;

  const MentorSessionPhotoResult.success({required this.photos})
    : failure = null,
      message = null;

  const MentorSessionPhotoResult.failure({required this.failure, this.message})
    : photos = null;
}

class MentorSessionPhotoApi {
  final http.Client _client;

  MentorSessionPhotoApi({http.Client? client})
    : _client = client ?? http.Client();

  Future<MentorSessionPhotoResult> submitSessionPhotos({
    required String accessToken,
    required int sessionLogId,
    required List<String> photoPaths,
  }) async {
    if (photoPaths.length != 3) {
      return const MentorSessionPhotoResult.failure(
        failure: MentorSessionPhotoFailure.badRequest,
        message: 'Exactly three photos are required',
      );
    }

    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/mentor/session-logs/'
      '$sessionLogId/photos',
    );

    try {
      final request = http.MultipartRequest('POST', uri);

      request.headers['Authorization'] = 'Bearer $accessToken';

      for (final path in photoPaths) {
        request.files.add(await http.MultipartFile.fromPath('files', path));
      }

      final streamedResponse = await _client.send(request);
      final response = await http.Response.fromStream(streamedResponse);

      final data = decodeJsonBody(response.body);

      if (response.statusCode == 201) {
        final photos = (data as List<dynamic>)
            .map(
              (item) => SessionPhoto.fromJson(
                _withAbsoluteUrl(item as Map<String, dynamic>),
              ),
            )
            .toList();

        return MentorSessionPhotoResult.success(photos: photos);
      }

      return MentorSessionPhotoResult.failure(
        failure: _failureFromStatusCode(response.statusCode),
        message: apiDetail(data),
      );
    } catch (error) {
      if (isInvalidApiData(error)) {
        return const MentorSessionPhotoResult.failure(
          failure: MentorSessionPhotoFailure.invalidData,
        );
      }
      return const MentorSessionPhotoResult.failure(
        failure: MentorSessionPhotoFailure.networkError,
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

  MentorSessionPhotoFailure _failureFromStatusCode(int statusCode) {
    return switch (statusCode) {
      400 || 422 => MentorSessionPhotoFailure.badRequest,
      401 => MentorSessionPhotoFailure.unauthorized,
      403 => MentorSessionPhotoFailure.forbidden,
      404 => MentorSessionPhotoFailure.notFound,
      409 => MentorSessionPhotoFailure.conflict,
      _ => MentorSessionPhotoFailure.serverError,
    };
  }
}
