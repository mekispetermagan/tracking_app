import 'feature_controller.dart';
import 'package:image_picker/image_picker.dart';

import '../api/api.dart';
import '../models/models.dart';
import 'month_utils.dart';

class MentorStoryController extends FeatureController {
  final MentorStoryApi _storyApi;
  final SharedCourseApi _courseApi;
  final ImagePicker _imagePicker;

  MentorStoryController({
    MentorStoryApi? storyApi,
    SharedCourseApi? courseApi,
    ImagePicker? imagePicker,
  }) : _storyApi = storyApi ?? MentorStoryApi(),
       _courseApi = courseApi ?? SharedCourseApi(),
       _imagePicker = imagePicker ?? ImagePicker();

  List<MentorStory> _stories = [];
  List<Course> _courses = [];

  DateTime _selectedMonth = monthStart(DateTime.now());

  int? _mentorProfileId;
  int? _selectedCourseId;
  XFile? _selectedPhoto;

  bool _isLoading = false;
  bool _isSelectingPhoto = false;
  bool _isSubmitting = false;
  int? _ratingStoryId;

  String? _message;

  List<MentorStory> get stories => List.unmodifiable(_stories);
  List<Course> get courses => List.unmodifiable(_courses);

  DateTime get selectedMonth => _selectedMonth;

  int? get selectedCourseId => _selectedCourseId;
  XFile? get selectedPhoto => _selectedPhoto;

  bool get isLoading => _isLoading;
  bool get isSelectingPhoto => _isSelectingPhoto;
  bool get isSubmitting => _isSubmitting;
  int? get ratingStoryId => _ratingStoryId;

  String? get message => _message;

  bool get isCurrentMonth {
    return _sameMonth(_selectedMonth, DateTime.now());
  }

  bool get hasSubmittedThisMonth {
    final mentorProfileId = _mentorProfileId;

    if (mentorProfileId == null || !isCurrentMonth) {
      return false;
    }

    return _stories.any(
      (story) => story.submittedByMentorProfileId == mentorProfileId,
    );
  }

  bool get canSubmit {
    return isCurrentMonth &&
        !hasSubmittedThisMonth &&
        _selectedCourseId != null &&
        _selectedPhoto != null &&
        !_isLoading &&
        !_isSelectingPhoto &&
        !_isSubmitting;
  }

  Course? get selectedCourse {
    final courseId = _selectedCourseId;

    if (courseId == null) {
      return null;
    }

    for (final course in _courses) {
      if (course.id == courseId) {
        return course;
      }
    }

    return null;
  }

  Future<void> initialize({
    required String accessToken,
    required int mentorProfileId,
  }) async {
    final request = beginRequest();
    _stories = [];
    _courses = [];
    _selectedMonth = monthStart(DateTime.now());
    _mentorProfileId = mentorProfileId;
    _selectedCourseId = null;
    _selectedPhoto = null;
    _isLoading = true;
    _isSelectingPhoto = false;
    _isSubmitting = false;
    _ratingStoryId = null;
    _message = null;
    notifyListeners();

    String? failureMessage;

    final courseResult = await _courseApi.fetchCourses(
      accessToken: accessToken,
      activeOnly: false,
    );

    if (!requestIsCurrent(request)) return;

    if (courseResult.courses != null) {
      _courses = courseResult.courses!.where((course) => course.active).toList()
        ..sort((a, b) => a.name.compareTo(b.name));
    } else {
      failureMessage =
          courseResult.message ??
          _messageForCourseFailure(courseResult.failure);
    }

    final storyResult = await _storyApi.fetchStories(
      accessToken: accessToken,
      month: _selectedMonth,
    );

    if (!requestIsCurrent(request)) return;

    if (storyResult.stories != null) {
      _stories = storyResult.stories!;
    } else {
      failureMessage ??=
          storyResult.message ?? _messageForStoryFailure(storyResult.failure);
    }

    _message = failureMessage;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadMonth({
    required String accessToken,
    required DateTime month,
  }) async {
    if (_isLoading || _isSubmitting) {
      return;
    }

    final request = beginRequest();
    _selectedMonth = monthStart(month);
    _stories = [];
    _isLoading = true;
    _message = null;
    notifyListeners();

    final result = await _storyApi.fetchStories(
      accessToken: accessToken,
      month: _selectedMonth,
    );

    if (!requestIsCurrent(request)) return;

    if (result.stories != null) {
      _stories = result.stories!;
    } else {
      _message = result.message ?? _messageForStoryFailure(result.failure);
    }

    _isLoading = false;
    notifyListeners();
  }

  void selectCourse(int courseId) {
    if (_isLoading ||
        _isSubmitting ||
        !_courses.any((course) => course.id == courseId)) {
      return;
    }

    _selectedCourseId = courseId;
    _message = null;
    notifyListeners();
  }

  Future<void> selectPhoto() async {
    if (_isLoading || _isSelectingPhoto || _isSubmitting) {
      return;
    }

    final request = beginRequest();
    _isSelectingPhoto = true;
    _message = null;
    notifyListeners();

    try {
      final photo = await _imagePicker.pickImage(source: ImageSource.gallery);

      if (!requestIsCurrent(request)) return;

      if (photo != null) {
        _selectedPhoto = photo;
      }
    } catch (_) {
      if (!requestIsCurrent(request)) return;
      _selectedPhoto = null;
      _message = 'Could not select photo.';
    }

    _isSelectingPhoto = false;
    notifyListeners();
  }

  void clearPhoto() {
    if (_selectedPhoto == null || _isSubmitting) {
      return;
    }

    _selectedPhoto = null;
    _message = null;
    notifyListeners();
  }

  Future<bool> submit({
    required String accessToken,
    required String text,
  }) async {
    final storyText = text.trim();

    if (!isCurrentMonth) {
      _message = 'Stories can only be submitted for the current month.';
      notifyListeners();
      return false;
    }

    if (hasSubmittedThisMonth) {
      _message = 'You have already submitted a story this month.';
      notifyListeners();
      return false;
    }

    final courseId = _selectedCourseId;

    if (courseId == null) {
      _message = 'Select a course.';
      notifyListeners();
      return false;
    }

    final photo = _selectedPhoto;

    if (photo == null) {
      _message = 'Select a photo.';
      notifyListeners();
      return false;
    }

    if (storyText.isEmpty) {
      _message = 'Story text is required.';
      notifyListeners();
      return false;
    }

    if (_isLoading || _isSelectingPhoto || _isSubmitting) {
      return false;
    }

    final request = beginRequest();
    _isSubmitting = true;
    _message = null;
    notifyListeners();

    final result = await _storyApi.submitStory(
      accessToken: accessToken,
      request: StoryCreateRequest(
        courseId: courseId,
        text: storyText,
        photoPath: photo.path,
      ),
    );

    if (!requestIsCurrent(request)) return false;

    if (result.story != null) {
      _stories = [
        result.story!,
        ..._stories.where((story) => story.id != result.story!.id),
      ];
      _selectedPhoto = null;
      _isSubmitting = false;
      notifyListeners();
      return true;
    }

    _message = result.message ?? _messageForStoryFailure(result.failure);

    _isSubmitting = false;
    notifyListeners();
    return false;
  }

  Future<bool> rateStory({
    required String accessToken,
    required int storyId,
    required int rating,
  }) async {
    if (rating < 1 || rating > 5) {
      _message = 'Rating must be between 1 and 5.';
      notifyListeners();
      return false;
    }

    final story = _storyById(storyId);

    if (story == null) {
      _message = 'Story not found.';
      notifyListeners();
      return false;
    }

    if (!story.canRate) {
      _message = 'This story cannot be rated.';
      notifyListeners();
      return false;
    }

    if (_ratingStoryId != null) {
      return false;
    }

    final request = beginRequest();
    _ratingStoryId = storyId;
    _message = null;
    notifyListeners();

    final result = await _storyApi.rateStory(
      accessToken: accessToken,
      storyId: storyId,
      request: StoryRatingRequest(rating: rating),
    );

    if (!requestIsCurrent(request)) return false;

    if (result.story != null) {
      _replaceStory(result.story!);
      _ratingStoryId = null;
      notifyListeners();
      return true;
    }

    _message = result.message ?? _messageForStoryFailure(result.failure);

    _ratingStoryId = null;
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
    _courses = [];
    _selectedMonth = monthStart(DateTime.now());
    _mentorProfileId = null;
    _selectedCourseId = null;
    _selectedPhoto = null;
    _isLoading = false;
    _isSelectingPhoto = false;
    _isSubmitting = false;
    _ratingStoryId = null;
    _message = null;
    notifyListeners();
  }

  MentorStory? _storyById(int storyId) {
    for (final story in _stories) {
      if (story.id == storyId) {
        return story;
      }
    }

    return null;
  }

  void _replaceStory(MentorStory story) {
    _stories = [
      for (final existing in _stories)
        if (existing.id == story.id) story else existing,
    ];
  }

  String _messageForStoryFailure(MentorStoryFailure? failure) {
    return switch (failure) {
      MentorStoryFailure.badRequest => 'Invalid story data.',
      MentorStoryFailure.unauthorized => 'Login expired.',
      MentorStoryFailure.forbidden => 'Story access denied.',
      MentorStoryFailure.notFound => 'Story or course not found.',
      MentorStoryFailure.conflict => 'Story conflict.',
      MentorStoryFailure.invalidData => 'Invalid server data.',
      MentorStoryFailure.serverError => 'Server error.',
      MentorStoryFailure.networkError => 'Cannot connect to server.',
      null => 'Unknown error.',
    };
  }

  String _messageForCourseFailure(SharedCourseFailure? failure) {
    return switch (failure) {
      SharedCourseFailure.badRequest => 'Invalid course request.',
      SharedCourseFailure.unauthorized => 'Login expired.',
      SharedCourseFailure.forbidden => 'Course access denied.',
      SharedCourseFailure.notFound => 'Course not found.',
      SharedCourseFailure.conflict => 'Course conflict.',
      SharedCourseFailure.invalidData => 'Invalid server data.',
      SharedCourseFailure.serverError => 'Server error.',
      SharedCourseFailure.networkError => 'Cannot connect to server.',
      null => 'Unknown error.',
    };
  }
}

bool _sameMonth(DateTime first, DateTime second) {
  return first.year == second.year && first.month == second.month;
}
