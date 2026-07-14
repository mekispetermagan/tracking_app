import 'package:flutter/foundation.dart';

import '../api/api.dart';
import '../models/models.dart';

enum CourseStatusFilter { active, all, inactive }

enum CourseMentorStatusFilter { active, all, inactive }

enum AdminCourseManagementView { list, form, assignMentors }

enum AdminCourseFormMode { add, edit }

class AdminCourseManagementController extends ChangeNotifier {
  final SharedCourseApi _sharedCourseApi;
  final AdminCourseApi _adminCourseApi;
  final AdminMentorApi _adminMentorApi;

  AdminCourseManagementController({
    SharedCourseApi? sharedCourseApi,
    AdminCourseApi? adminCourseApi,
    AdminMentorApi? adminMentorApi,
  }) : _sharedCourseApi = sharedCourseApi ?? SharedCourseApi(),
       _adminCourseApi = adminCourseApi ?? AdminCourseApi(),
       _adminMentorApi = adminMentorApi ?? AdminMentorApi();

  List<Course> _courses = [];
  List<Mentor> _mentors = [];
  Set<int> _assignedMentorIds = {};

  CourseStatusFilter _statusFilter = CourseStatusFilter.active;
  CourseMentorStatusFilter _mentorStatusFilter =
      CourseMentorStatusFilter.active;
  AdminCourseManagementView _view = AdminCourseManagementView.list;
  AdminCourseFormMode _formMode = AdminCourseFormMode.add;

  int? _countryIdFilter;
  int? _mentorCountryIdFilter;
  int? _selectedCourseId;

  bool _isLoading = false;
  bool _isSaving = false;
  String? _message;

  List<Course> get courses => List.unmodifiable(_courses);
  List<Mentor> get mentors => List.unmodifiable(_mentors);

  List<Course> get visibleCourses {
    return _courses.where((course) {
      final statusMatches = switch (_statusFilter) {
        CourseStatusFilter.active => course.active,
        CourseStatusFilter.all => true,
        CourseStatusFilter.inactive => !course.active,
      };

      final countryMatches =
          _countryIdFilter == null || course.countryId == _countryIdFilter;

      return statusMatches && countryMatches;
    }).toList();
  }

  List<Mentor> get visibleMentors {
    return _mentors.where((mentor) {
      final statusMatches = switch (_mentorStatusFilter) {
        CourseMentorStatusFilter.active => mentor.active,
        CourseMentorStatusFilter.all => true,
        CourseMentorStatusFilter.inactive => !mentor.active,
      };

      final countryMatches =
          _mentorCountryIdFilter == null ||
          mentor.countryId == _mentorCountryIdFilter;

      return statusMatches && countryMatches;
    }).toList();
  }

  CourseStatusFilter get statusFilter => _statusFilter;
  CourseMentorStatusFilter get mentorStatusFilter => _mentorStatusFilter;
  AdminCourseManagementView get view => _view;
  AdminCourseFormMode get formMode => _formMode;

  int? get countryIdFilter => _countryIdFilter;
  int? get mentorCountryIdFilter => _mentorCountryIdFilter;
  int? get selectedCourseId => _selectedCourseId;

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get message => _message;

  Set<int> get assignedMentorIds => Set.unmodifiable(_assignedMentorIds);

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

  Course? get formCourse {
    return _formMode == AdminCourseFormMode.edit ? selectedCourse : null;
  }

  bool get canEdit => selectedCourse != null && !_isLoading && !_isSaving;

  bool get canAssignMentors =>
      selectedCourse != null && !_isLoading && !_isSaving;

  Future<void> openList({required String accessToken}) async {
    _view = AdminCourseManagementView.list;
    _message = null;
    notifyListeners();

    await loadCourses(accessToken: accessToken);
  }

  void startAddCourse() {
    if (_isLoading || _isSaving) {
      return;
    }

    _formMode = AdminCourseFormMode.add;
    _view = AdminCourseManagementView.form;
    _message = null;
    notifyListeners();
  }

  void startEditSelectedCourse() {
    if (!canEdit) {
      _message = 'No course selected.';
      notifyListeners();
      return;
    }

    _formMode = AdminCourseFormMode.edit;
    _view = AdminCourseManagementView.form;
    _message = null;
    notifyListeners();
  }

  Future<void> startAssignMentors({required String accessToken}) async {
    final course = selectedCourse;

    if (course == null || !canAssignMentors) {
      _message = 'No course selected.';
      notifyListeners();
      return;
    }

    _assignedMentorIds = course.mentorIds.toSet();
    _view = AdminCourseManagementView.assignMentors;
    _message = null;
    notifyListeners();

    await loadMentors(accessToken: accessToken);
  }

  void cancelTaskScreen() {
    _view = AdminCourseManagementView.list;
    _assignedMentorIds = {};
    _message = null;
    notifyListeners();
  }

  Future<void> loadCourses({required String accessToken}) async {
    _isLoading = true;
    _message = null;
    notifyListeners();

    final result = await _sharedCourseApi.fetchCourses(
      accessToken: accessToken,
      activeOnly: _statusFilter == CourseStatusFilter.active,
    );

    if (result.courses != null) {
      _courses = result.courses!;
      _clearSelectionIfHidden();
    } else {
      _message = result.message ?? _messageForSharedFailure(result.failure);
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadMentors({required String accessToken}) async {
    _isLoading = true;
    _message = null;
    notifyListeners();

    final result = await _adminMentorApi.fetchMentors(
      accessToken: accessToken,
      activeOnly: _mentorStatusFilter == CourseMentorStatusFilter.active,
    );

    if (result.mentors != null) {
      _mentors = result.mentors!;
    } else {
      _message = result.message ?? _messageForMentorFailure(result.failure);
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> setStatusFilter({
    required CourseStatusFilter value,
    required String accessToken,
  }) async {
    if (_statusFilter == value) {
      return;
    }

    _statusFilter = value;
    _selectedCourseId = null;
    notifyListeners();

    await loadCourses(accessToken: accessToken);
  }

  Future<void> setMentorStatusFilter({
    required CourseMentorStatusFilter value,
    required String accessToken,
  }) async {
    if (_mentorStatusFilter == value) {
      return;
    }

    _mentorStatusFilter = value;
    notifyListeners();

    await loadMentors(accessToken: accessToken);
  }

  void setCountryIdFilter(int? value) {
    if (_countryIdFilter == value) {
      return;
    }

    _countryIdFilter = value;
    _clearSelectionIfHidden();
    notifyListeners();
  }

  void setMentorCountryIdFilter(int? value) {
    if (_mentorCountryIdFilter == value) {
      return;
    }

    _mentorCountryIdFilter = value;
    notifyListeners();
  }

  void selectCourse(int courseId) {
    if (_selectedCourseId == courseId) {
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

  void setMentorAssigned({required int mentorId, required bool assigned}) {
    if (assigned) {
      _assignedMentorIds.add(mentorId);
    } else {
      _assignedMentorIds.remove(mentorId);
    }

    notifyListeners();
  }

  void clearMessage() {
    if (_message == null) {
      return;
    }

    _message = null;
    notifyListeners();
  }

  Future<bool> createCourse({
    required String accessToken,
    required CourseCreateRequest request,
  }) async {
    _isSaving = true;
    _message = null;
    notifyListeners();

    final result = await _adminCourseApi.createCourse(
      accessToken: accessToken,
      request: request,
    );

    if (result.course != null) {
      _selectedCourseId = result.course!.id;
      _view = AdminCourseManagementView.list;
      await loadCourses(accessToken: accessToken);
      _isSaving = false;
      notifyListeners();
      return true;
    }

    _message = result.message ?? _messageForAdminFailure(result.failure);
    _isSaving = false;
    notifyListeners();
    return false;
  }

  Future<bool> updateCourse({
    required String accessToken,
    required int courseId,
    required CourseUpdateRequest request,
  }) async {
    _isSaving = true;
    _message = null;
    notifyListeners();

    final result = await _sharedCourseApi.updateCourse(
      accessToken: accessToken,
      courseId: courseId,
      request: request,
    );

    if (result.course != null) {
      _replaceCourse(result.course!);
      _selectedCourseId = result.course!.id;
      _clearSelectionIfHidden();
      _view = AdminCourseManagementView.list;
      _isSaving = false;
      notifyListeners();
      return true;
    }

    _message = result.message ?? _messageForSharedFailure(result.failure);
    _isSaving = false;
    notifyListeners();
    return false;
  }

  Future<bool> saveMentorAssignments({required String accessToken}) async {
    final course = selectedCourse;

    if (course == null) {
      _message = 'No course selected.';
      notifyListeners();
      return false;
    }

    final request = CourseUpdateRequest(
      name: course.name,
      description: course.description,
      countryId: course.countryId,
      dayOfWeek: course.dayOfWeek,
      startTime: course.startTime,
      active: course.active,
      mentorIds: _assignedMentorIds.toList(),
      studentIds: course.studentIds,
    );

    return updateCourse(
      accessToken: accessToken,
      courseId: course.id,
      request: request,
    );
  }

  Future<bool> deactivateSelectedCourse({required String accessToken}) async {
    final course = selectedCourse;

    if (course == null) {
      _message = 'No course selected.';
      notifyListeners();
      return false;
    }

    _isSaving = true;
    _message = null;
    notifyListeners();

    final result = await _adminCourseApi.deactivateCourse(
      accessToken: accessToken,
      courseId: course.id,
    );

    if (result.course != null) {
      _replaceCourse(result.course!);
      _clearSelectionIfHidden();
      _isSaving = false;
      notifyListeners();
      return true;
    }

    _message = result.message ?? _messageForAdminFailure(result.failure);
    _isSaving = false;
    notifyListeners();
    return false;
  }

  void reset() {
    _courses = [];
    _mentors = [];
    _assignedMentorIds = {};
    _statusFilter = CourseStatusFilter.active;
    _mentorStatusFilter = CourseMentorStatusFilter.active;
    _view = AdminCourseManagementView.list;
    _formMode = AdminCourseFormMode.add;
    _countryIdFilter = null;
    _mentorCountryIdFilter = null;
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

  void _clearSelectionIfHidden() {
    final selectedId = _selectedCourseId;

    if (selectedId == null) {
      return;
    }

    final stillVisible = visibleCourses.any(
      (course) => course.id == selectedId,
    );

    if (!stillVisible) {
      _selectedCourseId = null;
    }
  }

  String _messageForSharedFailure(SharedCourseFailure? failure) {
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

  String _messageForAdminFailure(AdminCourseFailure? failure) {
    return switch (failure) {
      AdminCourseFailure.badRequest => 'Invalid course data.',
      AdminCourseFailure.unauthorized => 'Login expired.',
      AdminCourseFailure.forbidden => 'Admin access required.',
      AdminCourseFailure.notFound => 'Course not found.',
      AdminCourseFailure.conflict => 'Course conflict.',
      AdminCourseFailure.serverError => 'Server error.',
      AdminCourseFailure.networkError => 'Cannot connect to server.',
      null => 'Unknown error.',
    };
  }

  String _messageForMentorFailure(AdminMentorFailure? failure) {
    return switch (failure) {
      AdminMentorFailure.badRequest => 'Invalid mentor data.',
      AdminMentorFailure.unauthorized => 'Login expired.',
      AdminMentorFailure.forbidden => 'Admin access required.',
      AdminMentorFailure.notFound => 'Mentor not found.',
      AdminMentorFailure.conflict => 'Mentor conflict.',
      AdminMentorFailure.serverError => 'Server error.',
      AdminMentorFailure.networkError => 'Cannot connect to server.',
      null => 'Unknown error.',
    };
  }
}
