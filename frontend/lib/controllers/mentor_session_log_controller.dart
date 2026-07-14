import 'package:flutter/foundation.dart';

import '../api/api.dart';
import '../models/models.dart';

class MentorSessionLogController extends ChangeNotifier {
  final MentorSessionLogApi _sessionLogApi;
  final SharedCourseApi _courseApi;
  final SharedStudentApi _studentApi;

  MentorSessionLogController({
    MentorSessionLogApi? sessionLogApi,
    SharedCourseApi? courseApi,
    SharedStudentApi? studentApi,
  }) : _sessionLogApi = sessionLogApi ?? MentorSessionLogApi(),
       _courseApi = courseApi ?? SharedCourseApi(),
       _studentApi = studentApi ?? SharedStudentApi();

  List<Course> _courses = [];
  List<Student> _students = [];

  int? _selectedCourseId;
  Set<int> _selectedStudentIds = {};

  bool _isLoading = false;
  bool _isSaving = false;
  String? _message;

  List<Course> get courses => List.unmodifiable(_courses);
  List<Student> get students => List.unmodifiable(_students);

  int? get selectedCourseId => _selectedCourseId;

  Set<int> get selectedStudentIds => Set.unmodifiable(_selectedStudentIds);

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get message => _message;

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

  bool get canSubmit =>
      _selectedCourseId != null &&
      _selectedStudentIds.isNotEmpty &&
      !_isLoading &&
      !_isSaving;

  Future<void> initialize({required String accessToken}) async {
    _courses = [];
    _students = [];
    _selectedCourseId = null;
    _selectedStudentIds = {};
    _isLoading = true;
    _message = null;
    notifyListeners();

    final result = await _courseApi.fetchCourses(
      accessToken: accessToken,
      activeOnly: true,
    );

    if (result.courses != null) {
      _courses = result.courses!;
    } else {
      _message = result.message ?? _messageForCourseFailure(result.failure);
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> selectCourse({
    required String accessToken,
    required int courseId,
  }) async {
    if (_selectedCourseId == courseId || _isSaving) {
      return;
    }

    _selectedCourseId = courseId;
    _students = [];
    _selectedStudentIds = {};
    _isLoading = true;
    _message = null;
    notifyListeners();

    final result = await _studentApi.fetchStudents(
      accessToken: accessToken,
      courseId: courseId,
      activeOnly: true,
    );

    if (result.students != null) {
      _students = result.students!;
      _selectedStudentIds = {for (final student in _students) student.id};
    } else {
      _message = result.message ?? _messageForStudentFailure(result.failure);
    }

    _isLoading = false;
    notifyListeners();
  }

  void toggleStudent(int studentId) {
    if (_isLoading || _isSaving) {
      return;
    }

    if (_selectedStudentIds.contains(studentId)) {
      _selectedStudentIds.remove(studentId);
    } else {
      _selectedStudentIds.add(studentId);
    }

    notifyListeners();
  }

  void selectAllStudents() {
    if (_isLoading || _isSaving) {
      return;
    }

    _selectedStudentIds = {for (final student in _students) student.id};
    notifyListeners();
  }

  void clearStudentSelection() {
    if (_selectedStudentIds.isEmpty || _isSaving) {
      return;
    }

    _selectedStudentIds = {};
    notifyListeners();
  }

  Future<bool> submit({
    required String accessToken,
    required SessionLogCreateRequest request,
  }) async {
    if (_selectedCourseId == null) {
      _message = 'Select a course.';
      notifyListeners();
      return false;
    }

    if (request.courseId != _selectedCourseId) {
      _message = 'Invalid course selection.';
      notifyListeners();
      return false;
    }

    if (request.studentIds.isEmpty) {
      _message = 'Select at least one student.';
      notifyListeners();
      return false;
    }

    _isSaving = true;
    _message = null;
    notifyListeners();

    final result = await _sessionLogApi.submitSessionLog(
      accessToken: accessToken,
      request: request,
    );

    if (result.sessionLog != null) {
      _isSaving = false;
      notifyListeners();
      return true;
    }

    _message = result.message ?? _messageForSessionLogFailure(result.failure);

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
    _courses = [];
    _students = [];
    _selectedCourseId = null;
    _selectedStudentIds = {};
    _isLoading = false;
    _isSaving = false;
    _message = null;
    notifyListeners();
  }

  String _messageForSessionLogFailure(MentorSessionLogFailure? failure) {
    return switch (failure) {
      MentorSessionLogFailure.badRequest => 'Invalid session log data.',
      MentorSessionLogFailure.unauthorized => 'Login expired.',
      MentorSessionLogFailure.forbidden => 'Session log access denied.',
      MentorSessionLogFailure.notFound => 'Course not found.',
      MentorSessionLogFailure.conflict => 'Session log conflict.',
      MentorSessionLogFailure.serverError => 'Server error.',
      MentorSessionLogFailure.networkError => 'Cannot connect to server.',
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
}
