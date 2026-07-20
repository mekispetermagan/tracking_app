import 'feature_controller.dart';

import '../api/api.dart';
import '../models/models.dart';
import 'month_utils.dart';

class AdminStoryController extends FeatureController {
  final AdminStoryApi _storyApi;

  AdminStoryController({AdminStoryApi? storyApi})
    : _storyApi = storyApi ?? AdminStoryApi();

  List<AdminStory> _stories = [];

  DateTime _selectedMonth = monthStart(DateTime.now());
  bool _activeOnly = true;

  bool _isLoading = false;
  int? _savingStoryId;
  bool _isSelectingWinner = false;

  String? _message;

  List<AdminStory> get stories => List.unmodifiable(
    _activeOnly ? _stories.where((story) => story.active) : _stories,
  );

  DateTime get selectedMonth => _selectedMonth;
  bool get activeOnly => _activeOnly;

  bool get isLoading => _isLoading;
  int? get savingStoryId => _savingStoryId;
  bool get isSelectingWinner => _isSelectingWinner;

  String? get message => _message;

  bool get canSelectWinner {
    return _selectedMonth.isBefore(monthStart(DateTime.now()));
  }

  AdminStory? get selectedWinner {
    for (final story in _stories) {
      if (story.isWinner) {
        return story;
      }
    }

    return null;
  }

  Future<void> initialize({required String accessToken}) async {
    _stories = [];
    _selectedMonth = monthStart(DateTime.now());
    _activeOnly = true;
    _isLoading = false;
    _savingStoryId = null;
    _isSelectingWinner = false;
    _message = null;

    await _loadStories(accessToken: accessToken);
  }

  Future<void> loadMonth({
    required String accessToken,
    required DateTime month,
  }) async {
    if (_isLoading || _savingStoryId != null || _isSelectingWinner) {
      return;
    }

    _selectedMonth = monthStart(month);

    await _loadStories(accessToken: accessToken);
  }

  void setActiveOnly(bool value) {
    if (_activeOnly == value ||
        _isLoading ||
        _savingStoryId != null ||
        _isSelectingWinner) {
      return;
    }

    _activeOnly = value;
    notifyListeners();
  }

  Future<bool> updateStory({
    required String accessToken,
    required int storyId,
    required String text,
  }) async {
    final storyText = text.trim();

    if (storyText.isEmpty) {
      _message = 'Story text is required.';
      notifyListeners();
      return false;
    }

    if (!_canModify(storyId)) {
      return false;
    }

    final request = beginRequest();
    _savingStoryId = storyId;
    _message = null;
    notifyListeners();

    final result = await _storyApi.updateStory(
      accessToken: accessToken,
      storyId: storyId,
      request: StoryUpdateRequest(text: storyText),
    );

    if (!requestIsCurrent(request)) return false;

    return _finishStoryChange(result);
  }

  Future<bool> deactivateStory({
    required String accessToken,
    required int storyId,
  }) async {
    if (!_canModify(storyId)) {
      return false;
    }

    final request = beginRequest();
    _savingStoryId = storyId;
    _message = null;
    notifyListeners();

    final result = await _storyApi.deactivateStory(
      accessToken: accessToken,
      storyId: storyId,
    );

    if (!requestIsCurrent(request)) return false;

    return _finishStoryChange(result);
  }

  Future<bool> activateStory({
    required String accessToken,
    required int storyId,
  }) async {
    if (!_canModify(storyId)) {
      return false;
    }

    final request = beginRequest();
    _savingStoryId = storyId;
    _message = null;
    notifyListeners();

    final result = await _storyApi.activateStory(
      accessToken: accessToken,
      storyId: storyId,
    );

    if (!requestIsCurrent(request)) return false;

    return _finishStoryChange(result);
  }

  Future<bool> selectWinner({
    required String accessToken,
    required int storyId,
  }) async {
    if (!canSelectWinner) {
      _message =
          'A winner can only be selected '
          'after the month has ended.';
      notifyListeners();
      return false;
    }

    final story = _storyById(storyId);

    if (story == null || !story.active) {
      _message = 'Select an active story.';
      notifyListeners();
      return false;
    }

    if (_isLoading || _savingStoryId != null || _isSelectingWinner) {
      return false;
    }

    final request = beginRequest();
    _isSelectingWinner = true;
    _message = null;
    notifyListeners();

    final result = await _storyApi.selectWinner(
      accessToken: accessToken,
      month: _selectedMonth,
      request: StoryWinnerRequest(storyId: storyId),
    );

    if (!requestIsCurrent(request)) return false;

    if (result.winner == null) {
      _message = result.message ?? _messageForFailure(result.failure);

      _isSelectingWinner = false;
      notifyListeners();
      return false;
    }

    final refreshResult = await _storyApi.fetchStories(
      accessToken: accessToken,
      month: _selectedMonth,
      activeOnly: false,
    );

    if (!requestIsCurrent(request)) return false;

    if (refreshResult.stories != null) {
      _stories = refreshResult.stories!;
      _isSelectingWinner = false;
      notifyListeners();
      return true;
    }

    _message =
        refreshResult.message ?? _messageForFailure(refreshResult.failure);

    _isSelectingWinner = false;
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
    _stories = [];
    _selectedMonth = monthStart(DateTime.now());
    _activeOnly = true;
    _isLoading = false;
    _savingStoryId = null;
    _isSelectingWinner = false;
    _message = null;
    notifyListeners();
  }

  Future<void> _loadStories({required String accessToken}) async {
    final request = beginRequest();
    _stories = [];
    _isLoading = true;
    _message = null;
    notifyListeners();

    final result = await _storyApi.fetchStories(
      accessToken: accessToken,
      month: _selectedMonth,
      activeOnly: false,
    );

    if (!requestIsCurrent(request)) return;

    if (result.stories != null) {
      _stories = result.stories!;
    } else {
      _message = result.message ?? _messageForFailure(result.failure);
    }

    _isLoading = false;
    notifyListeners();
  }

  bool _canModify(int storyId) {
    if (_storyById(storyId) == null) {
      _message = 'Story not found.';
      notifyListeners();
      return false;
    }

    if (_isLoading || _savingStoryId != null || _isSelectingWinner) {
      return false;
    }

    return true;
  }

  Future<bool> _finishStoryChange(AdminStoryResult result) async {
    if (result.story != null) {
      final story = result.story!;

      _replaceStory(story);

      _savingStoryId = null;
      notifyListeners();
      return true;
    }

    _message = result.message ?? _messageForFailure(result.failure);

    _savingStoryId = null;
    notifyListeners();
    return false;
  }

  AdminStory? _storyById(int storyId) {
    for (final story in _stories) {
      if (story.id == storyId) {
        return story;
      }
    }

    return null;
  }

  void _replaceStory(AdminStory story) {
    final exists = _stories.any((existing) => existing.id == story.id);

    if (!exists) {
      _stories = [story, ..._stories];
      return;
    }

    _stories = [
      for (final existing in _stories)
        if (existing.id == story.id) story else existing,
    ];
  }

  String _messageForFailure(AdminStoryFailure? failure) {
    return switch (failure) {
      AdminStoryFailure.badRequest => 'Invalid story data.',
      AdminStoryFailure.unauthorized => 'Login expired.',
      AdminStoryFailure.forbidden => 'Story access denied.',
      AdminStoryFailure.notFound => 'Story not found.',
      AdminStoryFailure.conflict => 'Story conflict.',
      AdminStoryFailure.invalidData => 'Invalid server data.',
      AdminStoryFailure.serverError => 'Server error.',
      AdminStoryFailure.networkError => 'Cannot connect to server.',
      null => 'Unknown error.',
    };
  }
}
