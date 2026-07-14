import 'package:flutter/foundation.dart';

import '../api/api.dart';
import '../models/models.dart';

enum MentorStudentManagementView { list, form }

enum MentorStudentFormMode { add, edit }

class MentorStudentManagementController extends ChangeNotifier {
  final SharedStudentApi _studentApi;
  final SharedCourseApi _courseApi;

  MentorStudentManagementController({
    SharedStudentApi? studentApi,
    SharedCourseApi? courseApi,
  }) : _studentApi = studentApi ?? SharedStudentApi(),
       _courseApi = courseApi ?? SharedCourseApi();

  List<Student> _students = [];
  List<Course> _courses = [];

  MentorStudentManagementView _view = MentorStudentManagementView.list;
  MentorStudentFormMode _formMode = MentorStudentFormMode.add;

  int? _countryIdFilter;
  int? _courseIdFilter;
  int? _selectedStudentId;

  bool _isLoading = false;
  bool _isSaving = false;
  String? _message;

  List<Student> get students => List.unmodifiable(_students);
  List<Course> get courses => List.unmodifiable(_courses);

  List<Student> get visibleStudents {
    return _students.where((student) {
      final countryMatches =
          _countryIdFilter == null ||
          student.originCountryId == _countryIdFilter;

      final courseMatches =
          _courseIdFilter == null ||
          student.courseIds.contains(_courseIdFilter);

      return countryMatches && courseMatches;
    }).toList();
  }

  MentorStudentManagementView get view => _view;
  MentorStudentFormMode get formMode => _formMode;

  int? get countryIdFilter => _countryIdFilter;
  int? get courseIdFilter => _courseIdFilter;
  int? get selectedStudentId => _selectedStudentId;

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get message => _message;

  Student? get selectedStudent {
    final selectedId = _selectedStudentId;

    if (selectedId == null) {
      return null;
    }

    for (final student in _students) {
      if (student.id == selectedId) {
        return student;
      }
    }

    return null;
  }

  Student? get formStudent {
    return _formMode == MentorStudentFormMode.edit ? selectedStudent : null;
  }

  Course? get filterCourse {
    final filterId = _courseIdFilter;

    if (filterId == null) {
      return null;
    }

    for (final course in _courses) {
      if (course.id == filterId) {
        return course;
      }
    }

    return null;
  }

  bool get canEdit => selectedStudent != null && !_isLoading && !_isSaving;

  Future<void> openList({required String accessToken}) async {
    _view = MentorStudentManagementView.list;
    _message = null;
    notifyListeners();

    await loadCourses(accessToken: accessToken);
    await loadStudents(accessToken: accessToken);
  }

  Future<void> loadStudents({required String accessToken}) async {
    _isLoading = true;
    _message = null;
    notifyListeners();

    final result = await _studentApi.fetchStudents(
      accessToken: accessToken,
      activeOnly: true,
    );

    if (result.students != null) {
      _students = result.students!;
      _clearSelectionIfHidden();
    } else {
      _message = result.message ?? _messageForStudentFailure(result.failure);
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadCourses({required String accessToken}) async {
    _isLoading = true;
    _message = null;
    notifyListeners();

    final result = await _courseApi.fetchCourses(
      accessToken: accessToken,
      activeOnly: false,
    );

    if (result.courses != null) {
      _courses = result.courses!;
    } else {
      _message = result.message ?? _messageForCourseFailure(result.failure);
    }

    _isLoading = false;
    notifyListeners();
  }

  void startAddStudent() {
    if (_isLoading || _isSaving) {
      return;
    }

    _formMode = MentorStudentFormMode.add;
    _view = MentorStudentManagementView.form;
    _message = null;
    notifyListeners();
  }

  void startEditSelectedStudent() {
    if (!canEdit) {
      _message = 'No student selected.';
      notifyListeners();
      return;
    }

    _formMode = MentorStudentFormMode.edit;
    _view = MentorStudentManagementView.form;
    _message = null;
    notifyListeners();
  }

  void cancelForm() {
    _view = MentorStudentManagementView.list;
    _message = null;
    notifyListeners();
  }

  void setCourseIdFilter(int? value) {
    if (_courseIdFilter == value) {
      return;
    }

    _courseIdFilter = value;
    _clearSelectionIfHidden();
    notifyListeners();
  }

  void setCountryIdFilter(int? value) {
    if (_countryIdFilter == value) {
      return;
    }

    _countryIdFilter = value;
    _clearSelectionIfHidden();
    notifyListeners();
  }

  void selectStudent(int studentId) {
    if (_selectedStudentId == studentId) {
      return;
    }

    _selectedStudentId = studentId;
    notifyListeners();
  }

  void clearSelection() {
    if (_selectedStudentId == null) {
      return;
    }

    _selectedStudentId = null;
    notifyListeners();
  }

  bool requiresUnassignmentWarning(List<int> courseIds) {
    return _formMode == MentorStudentFormMode.edit &&
        selectedStudent != null &&
        selectedStudent!.courseIds.isNotEmpty &&
        courseIds.isEmpty;
  }

  Future<bool> createStudent({
    required String accessToken,
    required MentorStudentCreateRequest request,
  }) async {
    if (request.courseIds.isEmpty) {
      _message = 'Assign the student to at least one course.';
      notifyListeners();
      return false;
    }

    _isSaving = true;
    _message = null;
    notifyListeners();

    final result = await _studentApi.createStudentAsMentor(
      accessToken: accessToken,
      request: request,
    );

    if (result.student != null) {
      _selectedStudentId = result.student!.id;
      _view = MentorStudentManagementView.list;

      await loadStudents(accessToken: accessToken);

      _isSaving = false;
      notifyListeners();
      return true;
    }

    _message = result.message ?? _messageForStudentFailure(result.failure);

    _isSaving = false;
    notifyListeners();
    return false;
  }

  Future<bool> updateStudent({
    required String accessToken,
    required int studentId,
    required MentorStudentUpdateRequest request,
  }) async {
    _isSaving = true;
    _message = null;
    notifyListeners();

    final result = await _studentApi.updateStudentAsMentor(
      accessToken: accessToken,
      studentId: studentId,
      request: request,
    );

    if (result.student != null) {
      _selectedStudentId = result.student!.id;
      _view = MentorStudentManagementView.list;

      await loadStudents(accessToken: accessToken);

      _isSaving = false;
      notifyListeners();
      return true;
    }

    _message = result.message ?? _messageForStudentFailure(result.failure);

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
    _students = [];
    _courses = [];
    _view = MentorStudentManagementView.list;
    _formMode = MentorStudentFormMode.add;
    _countryIdFilter = null;
    _courseIdFilter = null;
    _selectedStudentId = null;
    _isLoading = false;
    _isSaving = false;
    _message = null;
    notifyListeners();
  }

  void _clearSelectionIfHidden() {
    final selectedId = _selectedStudentId;

    if (selectedId == null) {
      return;
    }

    final stillVisible = visibleStudents.any(
      (student) => student.id == selectedId,
    );

    if (!stillVisible) {
      _selectedStudentId = null;
    }
  }

  String _messageForStudentFailure(SharedStudentFailure? failure) {
    return switch (failure) {
      SharedStudentFailure.badRequest => 'Invalid student data.',
      SharedStudentFailure.unauthorized => 'Login expired.',
      SharedStudentFailure.forbidden => 'Student access denied.',
      SharedStudentFailure.notFound => 'Student not found.',
      SharedStudentFailure.conflict => 'Student conflict.',
      SharedStudentFailure.serverError => 'Server error.',
      SharedStudentFailure.networkError => 'Cannot connect to server.',
      null => 'Unknown error.',
    };
  }

  String _messageForCourseFailure(SharedCourseFailure? failure) {
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
