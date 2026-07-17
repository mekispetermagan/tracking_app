import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/models.dart';

enum MentorStoryFailure {
  badRequest,
  unauthorized,
  forbidden,
  notFound,
  conflict,
  serverError,
  networkError,
}

class MentorStoryListResult {
  final List<MentorStory>? stories;
  final MentorStoryFailure? failure;
  final String? message;

  const MentorStoryListResult.success({required this.stories})
    : failure = null,
      message = null;

  const MentorStoryListResult.failure({required this.failure, this.message})
    : stories = null;
}

class MentorStoryResult {
  final MentorStory? story;
  final MentorStoryFailure? failure;
  final String? message;

  const MentorStoryResult.success({required this.story})
    : failure = null,
      message = null;

  const MentorStoryResult.failure({required this.failure, this.message})
    : story = null;
}

class MentorStoryApi {
  Future<MentorStoryListResult> fetchStories({
    required String accessToken,
    DateTime? month,
  }) async {
    var uri = Uri.parse('${ApiConfig.baseUrl}/api/mentor/stories');

    if (month != null) {
      uri = uri.replace(queryParameters: {'month': _dateToJson(month)});
    }

    try {
      final response = await http.get(uri, headers: _headers(accessToken));
      final data = jsonDecode(response.body);

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
        message: _detailFromJson(data),
      );
    } catch (_) {
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

      final streamedResponse = await multipartRequest.send();

      final response = await http.Response.fromStream(streamedResponse);

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return MentorStoryResult.success(
          story: MentorStory.fromJson(
            _withAbsolutePhotoUrl(data as Map<String, dynamic>),
          ),
        );
      }

      return MentorStoryResult.failure(
        failure: _failureFromStatusCode(response.statusCode),
        message: _detailFromJson(data),
      );
    } catch (_) {
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
      final response = await http.put(
        uri,
        headers: _headers(accessToken),
        body: jsonEncode(request.toJson()),
      );
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return MentorStoryResult.success(
          story: MentorStory.fromJson(
            _withAbsolutePhotoUrl(data as Map<String, dynamic>),
          ),
        );
      }

      return MentorStoryResult.failure(
        failure: _failureFromStatusCode(response.statusCode),
        message: _detailFromJson(data),
      );
    } catch (_) {
      return const MentorStoryResult.failure(
        failure: MentorStoryFailure.networkError,
      );
    }
  }

  Map<String, String> _headers(String accessToken) {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $accessToken',
    };
  }

  Map<String, dynamic> _withAbsolutePhotoUrl(Map<String, dynamic> json) {
    final result = Map<String, dynamic>.from(json);

    final photo = Map<String, dynamic>.from(
      result['photo'] as Map<String, dynamic>,
    );

    final url = photo['url'] as String;

    if (url.startsWith('/')) {
      photo['url'] = '${ApiConfig.baseUrl}$url';
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

  String? _detailFromJson(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data['detail']?.toString();
    }

    return null;
  }
}

String _dateToJson(DateTime date) {
  final year = date.year.toString().padLeft(4, '0');
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');

  return '$year-$month-$day';
}
