import 'package:flutter/foundation.dart';

import '../api/api.dart';
import '../models/models.dart';

enum StudentStatusFilter { active, all, inactive }

enum StudentCourseStatusFilter { active, all, inactive }

enum AdminStudentManagementView { list, form, assignCourses }

enum AdminStudentFormMode { add, edit }

class AdminStudentManagementController extends ChangeNotifier {
  final SharedStudentApi _studentApi;
  final SharedCourseApi _courseApi;

  AdminStudentManagementController({
    SharedStudentApi? studentApi,
    SharedCourseApi? courseApi,
  }) : _studentApi = studentApi ?? SharedStudentApi(),
       _courseApi = courseApi ?? SharedCourseApi();

  List<Student> _students = [];
  List<Course> _courses = [];
  Set<int> _assignedCourseIds = {};

  StudentStatusFilter _statusFilter = StudentStatusFilter.active;
  StudentCourseStatusFilter _courseStatusFilter =
      StudentCourseStatusFilter.active;
  AdminStudentManagementView _view = AdminStudentManagementView.list;
  AdminStudentFormMode _formMode = AdminStudentFormMode.add;
  bool _unassignedOnly = false;

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
      final statusMatches = switch (_statusFilter) {
        StudentStatusFilter.active => student.active,
        StudentStatusFilter.all => true,
        StudentStatusFilter.inactive => !student.active,
      };

      final countryMatches =
          _countryIdFilter == null ||
          student.originCountryId == _countryIdFilter;

      final courseMatches = _unassignedOnly
          ? student.courseIds.isEmpty
          : _courseIdFilter == null ||
                student.courseIds.contains(_courseIdFilter);

      return statusMatches && countryMatches && courseMatches;
    }).toList();
  }

  List<Course> get visibleCourses {
    return _courses.where((course) {
      return switch (_courseStatusFilter) {
        StudentCourseStatusFilter.active => course.active,
        StudentCourseStatusFilter.all => true,
        StudentCourseStatusFilter.inactive => !course.active,
      };
    }).toList();
  }

  StudentStatusFilter get statusFilter => _statusFilter;
  StudentCourseStatusFilter get courseStatusFilter => _courseStatusFilter;
  AdminStudentManagementView get view => _view;
  AdminStudentFormMode get formMode => _formMode;

  int? get countryIdFilter => _countryIdFilter;
  int? get courseIdFilter => _courseIdFilter;
  int? get selectedStudentId => _selectedStudentId;
  bool get unassignedOnly => _unassignedOnly;

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get message => _message;

  Set<int> get assignedCourseIds => Set.unmodifiable(_assignedCourseIds);

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
    return _formMode == AdminStudentFormMode.edit ? selectedStudent : null;
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

  bool get canAssignCourses =>
      selectedStudent != null && !_isLoading && !_isSaving;

  Future<void> openList({required String accessToken}) async {
    _view = AdminStudentManagementView.list;
    _message = null;
    notifyListeners();

    await loadCourses(accessToken: accessToken);

    await loadStudents(accessToken: accessToken);
  }

  void startAddStudent() {
    if (_isLoading || _isSaving) {
      return;
    }

    _formMode = AdminStudentFormMode.add;
    _view = AdminStudentManagementView.form;
    _message = null;
    notifyListeners();
  }

  void startEditSelectedStudent() {
    if (!canEdit) {
      _message = 'No student selected.';
      notifyListeners();
      return;
    }

    _formMode = AdminStudentFormMode.edit;
    _view = AdminStudentManagementView.form;
    _message = null;
    notifyListeners();
  }

  Future<void> startAssignCourses({required String accessToken}) async {
    final student = selectedStudent;

    if (student == null || !canAssignCourses) {
      _message = 'No student selected.';
      notifyListeners();
      return;
    }

    _assignedCourseIds = student.courseIds.toSet();
    _view = AdminStudentManagementView.assignCourses;
    _message = null;
    notifyListeners();

    await loadCourses(accessToken: accessToken);
  }

  void cancelTaskScreen() {
    _view = AdminStudentManagementView.list;
    _assignedCourseIds = {};
    _message = null;
    notifyListeners();
  }

  Future<void> loadStudents({required String accessToken}) async {
    _isLoading = true;
    _message = null;
    notifyListeners();

    final result = await _studentApi.fetchStudents(
      accessToken: accessToken,
      activeOnly: false,
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
      activeOnly: _courseStatusFilter == StudentCourseStatusFilter.active,
    );

    if (result.courses != null) {
      _courses = result.courses!;
    } else {
      _message = result.message ?? _messageForCourseFailure(result.failure);
    }

    _isLoading = false;
    notifyListeners();
  }

  void setStatusFilter(StudentStatusFilter value) {
    if (_statusFilter == value) {
      return;
    }

    _statusFilter = value;
    _clearSelectionIfHidden();
    notifyListeners();
  }

  void setCourseIdFilter(int? value) {
    if (_courseIdFilter == value && !_unassignedOnly) {
      return;
    }

    _courseIdFilter = value;
    _unassignedOnly = false;
    _clearSelectionIfHidden();
    notifyListeners();
  }

  void setUnassignedFilter() {
    if (_unassignedOnly) {
      return;
    }

    _courseIdFilter = null;
    _unassignedOnly = true;
    _clearSelectionIfHidden();
    notifyListeners();
  }

  Future<void> setCourseStatusFilter({
    required StudentCourseStatusFilter value,
    required String accessToken,
  }) async {
    if (_courseStatusFilter == value) {
      return;
    }

    _courseStatusFilter = value;
    notifyListeners();

    await loadCourses(accessToken: accessToken);
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

  void setCourseAssigned({required int courseId, required bool assigned}) {
    if (assigned) {
      _assignedCourseIds.add(courseId);
    } else {
      _assignedCourseIds.remove(courseId);
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

  Future<bool> createStudent({
    required String accessToken,
    required StudentCreateRequest request,
  }) async {
    _isSaving = true;
    _message = null;
    notifyListeners();

    final result = await _studentApi.createStudent(
      accessToken: accessToken,
      request: request,
    );

    if (result.student != null) {
      _selectedStudentId = result.student!.id;
      _view = AdminStudentManagementView.list;
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
    required StudentUpdateRequest request,
  }) async {
    _isSaving = true;
    _message = null;
    notifyListeners();

    final result = await _studentApi.updateStudent(
      accessToken: accessToken,
      studentId: studentId,
      request: request,
    );

    if (result.student != null) {
      _replaceStudent(result.student!);
      _selectedStudentId = result.student!.id;
      _clearSelectionIfHidden();
      _view = AdminStudentManagementView.list;
      _isSaving = false;
      notifyListeners();
      return true;
    }

    _message = result.message ?? _messageForStudentFailure(result.failure);
    _isSaving = false;
    notifyListeners();
    return false;
  }

  Future<bool> saveCourseAssignments({required String accessToken}) async {
    final student = selectedStudent;

    if (student == null) {
      _message = 'No student selected.';
      notifyListeners();
      return false;
    }

    final request = StudentUpdateRequest(
      firstName: student.firstName,
      lastName: student.lastName,
      originCountryId: student.originCountryId,
      birthYear: student.birthYear,
      gender: student.gender,
      active: student.active,
      courseIds: _assignedCourseIds.toList(),
    );

    return updateStudent(
      accessToken: accessToken,
      studentId: student.id,
      request: request,
    );
  }

  void reset() {
    _students = [];
    _courses = [];
    _assignedCourseIds = {};
    _statusFilter = StudentStatusFilter.active;
    _courseStatusFilter = StudentCourseStatusFilter.active;
    _view = AdminStudentManagementView.list;
    _formMode = AdminStudentFormMode.add;
    _countryIdFilter = null;
    _courseIdFilter = null;
    _selectedStudentId = null;
    _isLoading = false;
    _isSaving = false;
    _message = null;
    _unassignedOnly = false;
    notifyListeners();
  }

  void _replaceStudent(Student updatedStudent) {
    final index = _students.indexWhere(
      (student) => student.id == updatedStudent.id,
    );

    if (index == -1) {
      _students = [..._students, updatedStudent];
      return;
    }

    _students = [
      ..._students.sublist(0, index),
      updatedStudent,
      ..._students.sublist(index + 1),
    ];
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
