import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '_api_support.dart';
import 'api_result.dart';
import '../models/models.dart';

enum SharedCourseMentorsFailure {
  badRequest,
  unauthorized,
  forbidden,
  notFound,
  serverError,
  invalidData,
  networkError,
}

class SharedCourseMentorListResult
    extends ApiResult<List<SharedMentor>, SharedCourseMentorsFailure> {
  final List<SharedMentor>? mentors;

  @override
  final SharedCourseMentorsFailure? failure;
  @override
  final String? message;

  const SharedCourseMentorListResult.success({required this.mentors})
    : failure = null,
      message = null;

  const SharedCourseMentorListResult.failure({
    required this.failure,
    this.message,
  }) : mentors = null;
}

class SharedCourseMentorsApi {
  final http.Client _client;

  SharedCourseMentorsApi({http.Client? client})
    : _client = client ?? http.Client();

  Future<SharedCourseMentorListResult> fetchCourseMentors({
    required String accessToken,
    required int courseId,
  }) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/shared/mentors',
    ).replace(queryParameters: {'course_id': courseId.toString()});

    try {
      final response = await _client.get(
        uri,
        headers: authenticatedHeaders(accessToken, json: true),
      );

      final data = decodeJsonBody(response.body);

      if (response.statusCode == 200) {
        final mentors = (data as List<dynamic>)
            .map((item) => SharedMentor.fromJson(item as Map<String, dynamic>))
            .toList();

        return SharedCourseMentorListResult.success(mentors: mentors);
      }

      return SharedCourseMentorListResult.failure(
        failure: _failureFromStatusCode(response.statusCode),
        message: apiDetail(data),
      );
    } catch (error) {
      if (isInvalidApiData(error)) {
        return const SharedCourseMentorListResult.failure(
          failure: SharedCourseMentorsFailure.invalidData,
        );
      }
      return const SharedCourseMentorListResult.failure(
        failure: SharedCourseMentorsFailure.networkError,
      );
    }
  }

  SharedCourseMentorsFailure _failureFromStatusCode(int statusCode) {
    return switch (statusCode) {
      400 || 422 => SharedCourseMentorsFailure.badRequest,
      401 => SharedCourseMentorsFailure.unauthorized,
      403 => SharedCourseMentorsFailure.forbidden,
      404 => SharedCourseMentorsFailure.notFound,
      _ => SharedCourseMentorsFailure.serverError,
    };
  }
}
