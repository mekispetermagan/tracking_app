import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '_api_support.dart';
import 'api_result.dart';
import '../models/models.dart';

enum AdminStoryFailure {
  badRequest,
  unauthorized,
  forbidden,
  notFound,
  conflict,
  serverError,
  invalidData,
  networkError,
}

class AdminStoryListResult
    extends ApiResult<List<AdminStory>, AdminStoryFailure> {
  final List<AdminStory>? stories;

  @override
  final AdminStoryFailure? failure;
  @override
  final String? message;

  const AdminStoryListResult.success({required this.stories})
    : failure = null,
      message = null;

  const AdminStoryListResult.failure({required this.failure, this.message})
    : stories = null;
}

class AdminStoryResult extends ApiResult<AdminStory, AdminStoryFailure> {
  final AdminStory? story;

  @override
  final AdminStoryFailure? failure;
  @override
  final String? message;

  const AdminStoryResult.success({required this.story})
    : failure = null,
      message = null;

  const AdminStoryResult.failure({required this.failure, this.message})
    : story = null;
}

class AdminStoryWinnerResult extends ApiResult<StoryWinner, AdminStoryFailure> {
  final StoryWinner? winner;

  @override
  final AdminStoryFailure? failure;
  @override
  final String? message;

  const AdminStoryWinnerResult.success({required this.winner})
    : failure = null,
      message = null;

  const AdminStoryWinnerResult.failure({required this.failure, this.message})
    : winner = null;
}

class AdminStoryApi {
  final http.Client _client;

  AdminStoryApi({http.Client? client}) : _client = client ?? http.Client();

  Future<AdminStoryListResult> fetchStories({
    required String accessToken,
    DateTime? month,
    bool activeOnly = true,
  }) async {
    final queryParameters = <String, String>{
      'active_only': activeOnly.toString(),
    };

    if (month != null) {
      queryParameters['month'] = apiDate(month);
    }

    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/admin/stories',
    ).replace(queryParameters: queryParameters);

    try {
      final response = await _client.get(
        uri,
        headers: authenticatedHeaders(accessToken, json: true),
      );
      final data = decodeJsonBody(response.body);

      if (response.statusCode == 200) {
        final stories = (data as List<dynamic>)
            .map(
              (item) => AdminStory.fromJson(
                _withAbsolutePhotoUrl(item as Map<String, dynamic>),
              ),
            )
            .toList();

        return AdminStoryListResult.success(stories: stories);
      }

      return AdminStoryListResult.failure(
        failure: _failureFromStatusCode(response.statusCode),
        message: apiDetail(data),
      );
    } catch (error) {
      if (isInvalidApiData(error)) {
        return const AdminStoryListResult.failure(
          failure: AdminStoryFailure.invalidData,
        );
      }
      return const AdminStoryListResult.failure(
        failure: AdminStoryFailure.networkError,
      );
    }
  }

  Future<AdminStoryResult> updateStory({
    required String accessToken,
    required int storyId,
    required StoryUpdateRequest request,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/admin/stories/$storyId');

    return _sendStoryRequest(
      accessToken: accessToken,
      request: () => _client.put(
        uri,
        headers: authenticatedHeaders(accessToken, json: true),
        body: jsonEncode(request.toJson()),
      ),
    );
  }

  Future<AdminStoryResult> deactivateStory({
    required String accessToken,
    required int storyId,
  }) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/admin/stories/'
      '$storyId/deactivate',
    );

    return _sendStoryRequest(
      accessToken: accessToken,
      request: () => _client.post(
        uri,
        headers: authenticatedHeaders(accessToken, json: true),
      ),
    );
  }

  Future<AdminStoryResult> activateStory({
    required String accessToken,
    required int storyId,
  }) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/admin/stories/'
      '$storyId/activate',
    );

    return _sendStoryRequest(
      accessToken: accessToken,
      request: () => _client.post(
        uri,
        headers: authenticatedHeaders(accessToken, json: true),
      ),
    );
  }

  Future<AdminStoryWinnerResult> selectWinner({
    required String accessToken,
    required DateTime month,
    required StoryWinnerRequest request,
  }) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/admin/story-winners/'
      '${apiDate(month)}',
    );

    try {
      final response = await _client.put(
        uri,
        headers: authenticatedHeaders(accessToken, json: true),
        body: jsonEncode(request.toJson()),
      );
      final data = decodeJsonBody(response.body);

      if (response.statusCode == 200) {
        return AdminStoryWinnerResult.success(
          winner: StoryWinner.fromJson(
            _winnerWithAbsolutePhotoUrl(data as Map<String, dynamic>),
          ),
        );
      }

      return AdminStoryWinnerResult.failure(
        failure: _failureFromStatusCode(response.statusCode),
        message: apiDetail(data),
      );
    } catch (error) {
      if (isInvalidApiData(error)) {
        return const AdminStoryWinnerResult.failure(
          failure: AdminStoryFailure.invalidData,
        );
      }
      return const AdminStoryWinnerResult.failure(
        failure: AdminStoryFailure.networkError,
      );
    }
  }

  Future<AdminStoryResult> _sendStoryRequest({
    required String accessToken,
    required Future<http.Response> Function() request,
  }) async {
    try {
      final response = await request();
      final data = decodeJsonBody(response.body);

      if (response.statusCode == 200) {
        return AdminStoryResult.success(
          story: AdminStory.fromJson(
            _withAbsolutePhotoUrl(data as Map<String, dynamic>),
          ),
        );
      }

      return AdminStoryResult.failure(
        failure: _failureFromStatusCode(response.statusCode),
        message: apiDetail(data),
      );
    } catch (error) {
      if (isInvalidApiData(error)) {
        return const AdminStoryResult.failure(
          failure: AdminStoryFailure.invalidData,
        );
      }
      return const AdminStoryResult.failure(
        failure: AdminStoryFailure.networkError,
      );
    }
  }

  Map<String, dynamic> _withAbsolutePhotoUrl(Map<String, dynamic> json) {
    final result = Map<String, dynamic>.from(json);

    final photo = Map<String, dynamic>.from(
      result['photo'] as Map<String, dynamic>,
    );

    final url = photo['url'] as String;

    if (url.startsWith('/')) {
      photo['url'] = absoluteApiUrl(url);
    }

    result['photo'] = photo;

    return result;
  }

  Map<String, dynamic> _winnerWithAbsolutePhotoUrl(Map<String, dynamic> json) {
    final result = Map<String, dynamic>.from(json);

    result['story'] = _withAbsolutePhotoUrl(
      result['story'] as Map<String, dynamic>,
    );

    return result;
  }

  AdminStoryFailure _failureFromStatusCode(int statusCode) {
    return switch (statusCode) {
      400 || 422 => AdminStoryFailure.badRequest,
      401 => AdminStoryFailure.unauthorized,
      403 => AdminStoryFailure.forbidden,
      404 => AdminStoryFailure.notFound,
      409 => AdminStoryFailure.conflict,
      _ => AdminStoryFailure.serverError,
    };
  }
}
