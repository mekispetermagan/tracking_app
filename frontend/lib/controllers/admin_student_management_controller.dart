import 'feature_controller.dart';

import '../api/api.dart';
import '../models/models.dart';
import 'management_types.dart';

enum AdminStudentManagementView { list, form, assignCourses }

class AdminStudentManagementController extends FeatureController {
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

  ActiveStatusFilter _statusFilter = ActiveStatusFilter.active;
  ActiveStatusFilter _courseStatusFilter = ActiveStatusFilter.active;
  AdminStudentManagementView _view = AdminStudentManagementView.list;
  EntityFormMode _formMode = EntityFormMode.add;
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
        ActiveStatusFilter.active => student.active,
        ActiveStatusFilter.all => true,
        ActiveStatusFilter.inactive => !student.active,
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
        ActiveStatusFilter.active => course.active,
        ActiveStatusFilter.all => true,
        ActiveStatusFilter.inactive => !course.active,
      };
    }).toList();
  }

  ActiveStatusFilter get statusFilter => _statusFilter;
  ActiveStatusFilter get courseStatusFilter => _courseStatusFilter;
  AdminStudentManagementView get view => _view;
  EntityFormMode get formMode => _formMode;

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
    return _formMode == EntityFormMode.edit ? selectedStudent : null;
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
    final request = beginRequest();
    _view = AdminStudentManagementView.list;
    _message = null;
    notifyListeners();

    await loadCourses(accessToken: accessToken, requestRevision: request);
    if (!requestIsCurrent(request) || _message != null) return;

    await loadStudents(accessToken: accessToken, requestRevision: request);
  }

  void startAddStudent() {
    if (_isLoading || _isSaving) {
      return;
    }

    _formMode = EntityFormMode.add;
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

    _formMode = EntityFormMode.edit;
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

  Future<void> loadStudents({
    required String accessToken,
    int? requestRevision,
  }) async {
    final request = requestRevision ?? beginRequest();
    _isLoading = true;
    _message = null;
    notifyListeners();

    final result = await _studentApi.fetchStudents(
      accessToken: accessToken,
      activeOnly: false,
    );

    if (!requestIsCurrent(request)) return;

    if (result.students != null) {
      _students = result.students!;
      _clearSelectionIfHidden();
    } else {
      _message = result.message ?? _messageForStudentFailure(result.failure);
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadCourses({
    required String accessToken,
    int? requestRevision,
  }) async {
    final request = requestRevision ?? beginRequest();
    _isLoading = true;
    _message = null;
    notifyListeners();

    final result = await _courseApi.fetchCourses(
      accessToken: accessToken,
      activeOnly: false,
    );

    if (!requestIsCurrent(request)) return;

    if (result.courses != null) {
      _courses = result.courses!;
    } else {
      _message = result.message ?? _messageForCourseFailure(result.failure);
    }

    _isLoading = false;
    notifyListeners();
  }

  void setStatusFilter(ActiveStatusFilter value) {
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

  void setCourseStatusFilter(ActiveStatusFilter value) {
    if (_courseStatusFilter == value) {
      return;
    }

    _courseStatusFilter = value;
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
    if (_isLoading ||
        _isSaving ||
        _selectedStudentId == studentId ||
        !_students.any((student) => student.id == studentId)) {
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
    if (_isLoading || _isSaving) return false;

    final operation = beginRequest();
    _isSaving = true;
    _message = null;
    notifyListeners();

    final result = await _studentApi.createStudent(
      accessToken: accessToken,
      request: request,
    );

    if (!requestIsCurrent(operation)) return false;

    if (result.student != null) {
      _replaceStudent(result.student!);
      _selectedStudentId = result.student!.id;
      _view = AdminStudentManagementView.list;
      _clearSelectionIfHidden();
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
    if (_isLoading || _isSaving) return false;

    final operation = beginRequest();
    _isSaving = true;
    _message = null;
    notifyListeners();

    final result = await _studentApi.updateStudent(
      accessToken: accessToken,
      studentId: studentId,
      request: request,
    );

    if (!requestIsCurrent(operation)) return false;

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
    invalidateRequests();
    _students = [];
    _courses = [];
    _assignedCourseIds = {};
    _statusFilter = ActiveStatusFilter.active;
    _courseStatusFilter = ActiveStatusFilter.active;
    _view = AdminStudentManagementView.list;
    _formMode = EntityFormMode.add;
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
      SharedStudentFailure.invalidData => 'Invalid server data.',
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
      SharedCourseFailure.invalidData => 'Invalid server data.',
      SharedCourseFailure.serverError => 'Server error.',
      SharedCourseFailure.networkError => 'Cannot connect to server.',
      null => 'Unknown error.',
    };
  }
}
