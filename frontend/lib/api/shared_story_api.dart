import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/models.dart';

enum SharedStoryFailure { unauthorized, forbidden, serverError, networkError }

class SharedStoryWinnerListResult {
  final List<StoryWinner>? winners;
  final SharedStoryFailure? failure;
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
  Future<SharedStoryWinnerListResult> fetchWinnerArchive({
    required String accessToken,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/shared/story-winners');

    try {
      final response = await http.get(uri, headers: _headers(accessToken));
      final data = jsonDecode(response.body);

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
        message: _detailFromJson(data),
      );
    } catch (_) {
      return const SharedStoryWinnerListResult.failure(
        failure: SharedStoryFailure.networkError,
      );
    }
  }

  Map<String, String> _headers(String accessToken) {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $accessToken',
    };
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
      photo['url'] = '${ApiConfig.baseUrl}$url';
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

  String? _detailFromJson(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data['detail']?.toString();
    }

    return null;
  }
}
