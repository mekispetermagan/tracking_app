import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '_api_support.dart';
import 'api_result.dart';
import '../models/models.dart';

enum MentorStoryFailure {
  badRequest,
  unauthorized,
  forbidden,
  notFound,
  conflict,
  serverError,
  invalidData,
  networkError,
}

class MentorStoryListResult
    extends ApiResult<List<MentorStory>, MentorStoryFailure> {
  final List<MentorStory>? stories;

  @override
  final MentorStoryFailure? failure;
  @override
  final String? message;

  const MentorStoryListResult.success({required this.stories})
    : failure = null,
      message = null;

  const MentorStoryListResult.failure({required this.failure, this.message})
    : stories = null;
}

class MentorStoryResult extends ApiResult<MentorStory, MentorStoryFailure> {
  final MentorStory? story;

  @override
  final MentorStoryFailure? failure;
  @override
  final String? message;

  const MentorStoryResult.success({required this.story})
    : failure = null,
      message = null;

  const MentorStoryResult.failure({required this.failure, this.message})
    : story = null;
}

class MentorStoryApi {
  final http.Client _client;

  MentorStoryApi({http.Client? client}) : _client = client ?? http.Client();

  Future<MentorStoryListResult> fetchStories({
    required String accessToken,
    DateTime? month,
  }) async {
    var uri = Uri.parse('${ApiConfig.baseUrl}/api/mentor/stories');

    if (month != null) {
      uri = uri.replace(queryParameters: {'month': apiDate(month)});
    }

    try {
      final response = await _client.get(
        uri,
        headers: authenticatedHeaders(accessToken, json: true),
      );
      final data = decodeJsonBody(response.body);

      if (response.statusCode == 200) {
        final stories = (data as List<dynamic>)
            .map(
              (item) => MentorStory.fromJson(
                _withAbsolutePhotoUrl(item as Map<String, dynamic>),
              ),
            )
            .toList();

        return MentorStoryListResult.success(stories: stories);
      }

      return MentorStoryListResult.failure(
        failure: _failureFromStatusCode(response.statusCode),
        message: apiDetail(data),
      );
    } catch (error) {
      if (isInvalidApiData(error)) {
        return const MentorStoryListResult.failure(
          failure: MentorStoryFailure.invalidData,
        );
      }
      return const MentorStoryListResult.failure(
        failure: MentorStoryFailure.networkError,
      );
    }
  }

  Future<MentorStoryResult> submitStory({
    required String accessToken,
    required StoryCreateRequest request,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/mentor/stories');

    try {
      final multipartRequest = http.MultipartRequest('POST', uri);

      multipartRequest.headers['Authorization'] = 'Bearer $accessToken';

      multipartRequest.fields.addAll(request.toFields());

      multipartRequest.files.add(
        await http.MultipartFile.fromPath('photo', request.photoPath),
      );

      final streamedResponse = await _client.send(multipartRequest);

      final response = await http.Response.fromStream(streamedResponse);

      final data = decodeJsonBody(response.body);

      if (response.statusCode == 201) {
        return MentorStoryResult.success(
          story: MentorStory.fromJson(
            _withAbsolutePhotoUrl(data as Map<String, dynamic>),
          ),
        );
      }

      return MentorStoryResult.failure(
        failure: _failureFromStatusCode(response.statusCode),
        message: apiDetail(data),
      );
    } catch (error) {
      if (isInvalidApiData(error)) {
        return const MentorStoryResult.failure(
          failure: MentorStoryFailure.invalidData,
        );
      }
      return const MentorStoryResult.failure(
        failure: MentorStoryFailure.networkError,
      );
    }
  }

  Future<MentorStoryResult> rateStory({
    required String accessToken,
    required int storyId,
    required StoryRatingRequest request,
  }) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/mentor/stories/'
      '$storyId/rating',
    );

    try {
      final response = await _client.put(
        uri,
        headers: authenticatedHeaders(accessToken, json: true),
        body: jsonEncode(request.toJson()),
      );
      final data = decodeJsonBody(response.body);

      if (response.statusCode == 200) {
        return MentorStoryResult.success(
          story: MentorStory.fromJson(
            _withAbsolutePhotoUrl(data as Map<String, dynamic>),
          ),
        );
      }

      return MentorStoryResult.failure(
        failure: _failureFromStatusCode(response.statusCode),
        message: apiDetail(data),
      );
    } catch (error) {
      if (isInvalidApiData(error)) {
        return const MentorStoryResult.failure(
          failure: MentorStoryFailure.invalidData,
        );
      }
      return const MentorStoryResult.failure(
        failure: MentorStoryFailure.networkError,
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

  MentorStoryFailure _failureFromStatusCode(int statusCode) {
    return switch (statusCode) {
      400 || 422 => MentorStoryFailure.badRequest,
      401 => MentorStoryFailure.unauthorized,
      403 => MentorStoryFailure.forbidden,
      404 => MentorStoryFailure.notFound,
      409 => MentorStoryFailure.conflict,
      _ => MentorStoryFailure.serverError,
    };
  }
}
