import 'feature_controller.dart';

import '../api/api.dart';
import '../models/models.dart';

class StoryWinnerArchiveController extends FeatureController {
  final SharedStoryApi _storyApi;

  StoryWinnerArchiveController({SharedStoryApi? storyApi})
    : _storyApi = storyApi ?? SharedStoryApi();

  List<StoryWinner> _winners = [];

  bool _isLoading = false;
  String? _message;

  List<StoryWinner> get winners => List.unmodifiable(_winners);

  bool get isLoading => _isLoading;
  String? get message => _message;

  Future<bool> load({required String accessToken}) async {
    final request = beginRequest();
    _winners = [];
    _isLoading = true;
    _message = null;
    notifyListeners();

    final result = await _storyApi.fetchWinnerArchive(accessToken: accessToken);

    if (!requestIsCurrent(request)) return false;

    if (result.winners != null) {
      _winners = result.winners!;
      _isLoading = false;
      notifyListeners();
      return true;
    }

    _message = result.message ?? _messageForFailure(result.failure);

    _isLoading = false;
    notifyListeners();
    return false;
  }

  void clearMessage() {
    if (_message == null) {
      return;
    }

    _message = null;
    notifyListeners();
  }

  void reset() {
    invalidateRequests();
    _winners = [];
    _isLoading = false;
    _message = null;
    notifyListeners();
  }

  String _messageForFailure(SharedStoryFailure? failure) {
    return switch (failure) {
      SharedStoryFailure.unauthorized => 'Login expired.',
      SharedStoryFailure.forbidden => 'Story archive access denied.',
      SharedStoryFailure.invalidData => 'Invalid server data.',
      SharedStoryFailure.serverError => 'Server error.',
      SharedStoryFailure.networkError => 'Cannot connect to server.',
      null => 'Unknown error.',
    };
  }
}
