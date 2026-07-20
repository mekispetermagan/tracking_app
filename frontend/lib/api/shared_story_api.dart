import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '_api_support.dart';
import 'api_result.dart';
import '../models/models.dart';

enum SharedStoryFailure {
  unauthorized,
  forbidden,
  serverError,
  invalidData,
  networkError,
}

class SharedStoryWinnerListResult
    extends ApiResult<List<StoryWinner>, SharedStoryFailure> {
  final List<StoryWinner>? winners;

  @override
  final SharedStoryFailure? failure;
  @override
  final String? message;

  const SharedStoryWinnerListResult.success({required this.winners})
    : failure = null,
      message = null;

  const SharedStoryWinnerListResult.failure({
    required this.failure,
    this.message,
  }) : winners = null;
}

class SharedStoryApi {
  final http.Client _client;

  SharedStoryApi({http.Client? client}) : _client = client ?? http.Client();

  Future<SharedStoryWinnerListResult> fetchWinnerArchive({
    required String accessToken,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/shared/story-winners');

    try {
      final response = await _client.get(
        uri,
        headers: authenticatedHeaders(accessToken, json: true),
      );
      final data = decodeJsonBody(response.body);

      if (response.statusCode == 200) {
        final winners = (data as List<dynamic>)
            .map(
              (item) => StoryWinner.fromJson(
                _winnerWithAbsolutePhotoUrl(item as Map<String, dynamic>),
              ),
            )
            .toList();

        return SharedStoryWinnerListResult.success(winners: winners);
      }

      return SharedStoryWinnerListResult.failure(
        failure: _failureFromStatusCode(response.statusCode),
        message: apiDetail(data),
      );
    } catch (error) {
      if (isInvalidApiData(error)) {
        return const SharedStoryWinnerListResult.failure(
          failure: SharedStoryFailure.invalidData,
        );
      }
      return const SharedStoryWinnerListResult.failure(
        failure: SharedStoryFailure.networkError,
      );
    }
  }

  Map<String, dynamic> _winnerWithAbsolutePhotoUrl(Map<String, dynamic> json) {
    final result = Map<String, dynamic>.from(json);

    final story = Map<String, dynamic>.from(
      result['story'] as Map<String, dynamic>,
    );

    final photo = Map<String, dynamic>.from(
      story['photo'] as Map<String, dynamic>,
    );

    final url = photo['url'] as String;

    if (url.startsWith('/')) {
      photo['url'] = absoluteApiUrl(url);
    }

    story['photo'] = photo;
    result['story'] = story;

    return result;
  }

  SharedStoryFailure _failureFromStatusCode(int statusCode) {
    return switch (statusCode) {
      401 => SharedStoryFailure.unauthorized,
      403 => SharedStoryFailure.forbidden,
      _ => SharedStoryFailure.serverError,
    };
  }
}
