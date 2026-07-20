import 'feature_controller.dart';

import '../api/api.dart';
import '../models/models.dart';

enum MentorCourseManagementView { list, form }

class MentorCourseManagementController extends FeatureController {
  final SharedCourseApi _sharedCourseApi;

  MentorCourseManagementController({SharedCourseApi? sharedCourseApi})
    : _sharedCourseApi = sharedCourseApi ?? SharedCourseApi();

  List<Course> _courses = [];

  MentorCourseManagementView _view = MentorCourseManagementView.list;

  int? _selectedCourseId;

  bool _isLoading = false;
  bool _isSaving = false;
  String? _message;

  List<Course> get courses => List.unmodifiable(_courses);

  MentorCourseManagementView get view => _view;

  int? get selectedCourseId => _selectedCourseId;

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get message => _message;

  Course? get selectedCourse {
    final selectedId = _selectedCourseId;

    if (selectedId == null) {
      return null;
    }

    for (final course in _courses) {
      if (course.id == selectedId) {
        return course;
      }
    }

    return null;
  }

  bool get canEdit => selectedCourse != null && !_isLoading && !_isSaving;

  Future<void> openList({required String accessToken}) async {
    _view = MentorCourseManagementView.list;
    _message = null;
    notifyListeners();

    await loadCourses(accessToken: accessToken);
  }

  Future<void> loadCourses({required String accessToken}) async {
    final request = beginRequest();
    _isLoading = true;
    _message = null;
    notifyListeners();

    final result = await _sharedCourseApi.fetchCourses(
      accessToken: accessToken,
      activeOnly: false,
    );

    if (!requestIsCurrent(request)) return;

    if (result.courses != null) {
      _courses = result.courses!.where((course) => course.active).toList();
      _clearSelectionIfMissing();
    } else {
      _message = result.message ?? _messageForFailure(result.failure);
    }

    _isLoading = false;
    notifyListeners();
  }

  void selectCourse(int courseId) {
    if (_isLoading ||
        _isSaving ||
        _selectedCourseId == courseId ||
        !_courses.any((course) => course.id == courseId)) {
      return;
    }

    _selectedCourseId = courseId;
    notifyListeners();
  }

  void clearSelection() {
    if (_selectedCourseId == null) {
      return;
    }

    _selectedCourseId = null;
    notifyListeners();
  }

  void startEditSelectedCourse() {
    if (!canEdit) {
      _message = 'No course selected.';
      notifyListeners();
      return;
    }

    _view = MentorCourseManagementView.form;
    _message = null;
    notifyListeners();
  }

  void cancelEdit() {
    _view = MentorCourseManagementView.list;
    _message = null;
    notifyListeners();
  }

  Future<bool> updateCourse({
    required String accessToken,
    required String description,
    required int dayOfWeek,
    required String startTime,
  }) async {
    if (_isLoading || _isSaving) return false;

    final course = selectedCourse;

    if (course == null) {
      _message = 'No course selected.';
      notifyListeners();
      return false;
    }

    final operation = beginRequest();
    _isSaving = true;
    _message = null;
    notifyListeners();

    final request = CourseUpdateRequest(
      name: course.name,
      description: description,
      countryId: course.countryId,
      dayOfWeek: dayOfWeek,
      startTime: startTime,
      active: course.active,
      mentorIds: course.mentorIds,
      studentIds: course.studentIds,
    );

    final result = await _sharedCourseApi.updateCourse(
      accessToken: accessToken,
      courseId: course.id,
      request: request,
    );

    if (!requestIsCurrent(operation)) return false;

    if (result.course != null) {
      _replaceCourse(result.course!);
      _selectedCourseId = result.course!.id;
      _view = MentorCourseManagementView.list;
      _isSaving = false;
      notifyListeners();
      return true;
    }

    _message = result.message ?? _messageForFailure(result.failure);
    _isSaving = false;
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
    _courses = [];
    _view = MentorCourseManagementView.list;
    _selectedCourseId = null;
    _isLoading = false;
    _isSaving = false;
    _message = null;
    notifyListeners();
  }

  void _replaceCourse(Course updatedCourse) {
    final index = _courses.indexWhere(
      (course) => course.id == updatedCourse.id,
    );

    if (index == -1) {
      _courses = [..._courses, updatedCourse];
      return;
    }

    _courses = [
      ..._courses.sublist(0, index),
      updatedCourse,
      ..._courses.sublist(index + 1),
    ];
  }

  void _clearSelectionIfMissing() {
    final selectedId = _selectedCourseId;

    if (selectedId == null) {
      return;
    }

    final stillAvailable = _courses.any((course) => course.id == selectedId);

    if (!stillAvailable) {
      _selectedCourseId = null;
    }
  }

  String _messageForFailure(SharedCourseFailure? failure) {
    return switch (failure) {
      SharedCourseFailure.badRequest => 'Invalid course data.',
      SharedCourseFailure.unauthorized => 'Login expired.',
      SharedCourseFailure.forbidden => 'Course access denied.',
      SharedCourseFailure.notFound => 'Course not found.',
      SharedCourseFailure.conflict => 'Course conflict.',
      SharedCourseFailure.serverError => 'Server error.',
      SharedCourseFailure.networkError => 'Cannot connect to server.',
      null => 'Unknown error.',
    };
  }
}
