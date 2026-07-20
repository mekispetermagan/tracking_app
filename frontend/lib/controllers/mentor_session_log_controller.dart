import 'package:flutter/foundation.dart';

import 'feature_controller.dart';

import '../api/api.dart';
import '../models/models.dart';

class MentorSessionLogController extends FeatureController {
  final MentorSessionLogApi _sessionLogApi;
  final SharedCourseApi _courseApi;
  final SharedStudentApi _studentApi;
  final SharedCourseMentorsApi _mentorApi;

  MentorSessionLogController({
    MentorSessionLogApi? sessionLogApi,
    SharedCourseApi? courseApi,
    SharedStudentApi? studentApi,
    SharedCourseMentorsApi? mentorApi,
  }) : _sessionLogApi = sessionLogApi ?? MentorSessionLogApi(),
       _courseApi = courseApi ?? SharedCourseApi(),
       _studentApi = studentApi ?? SharedStudentApi(),
       _mentorApi = mentorApi ?? SharedCourseMentorsApi();

  List<Course> _courses = [];
  List<Student> _students = [];
  List<SharedMentor> _mentors = [];

  int? _selectedCourseId;
  Set<int> _selectedStudentIds = {};
  Set<int> _selectedTeachingMentorIds = {};
  Set<int> _selectedSupportingMentorIds = {};

  bool _isLoading = false;
  bool _isSaving = false;
  String? _message;

  List<Course> get courses => List.unmodifiable(_courses);
  List<Student> get students => List.unmodifiable(_students);
  List<SharedMentor> get mentors => List.unmodifiable(_mentors);

  int? get selectedCourseId => _selectedCourseId;

  Set<int> get selectedStudentIds => Set.unmodifiable(_selectedStudentIds);

  Set<int> get selectedTeachingMentorIds =>
      Set.unmodifiable(_selectedTeachingMentorIds);

  Set<int> get selectedSupportingMentorIds =>
      Set.unmodifiable(_selectedSupportingMentorIds);

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
      _selectedTeachingMentorIds.isNotEmpty &&
      !_isLoading &&
      !_isSaving;

  Future<void> initialize({required String accessToken}) async {
    final request = beginRequest();
    _courses = [];
    _students = [];
    _mentors = [];
    _selectedCourseId = null;
    _selectedStudentIds = {};
    _selectedTeachingMentorIds = {};
    _selectedSupportingMentorIds = {};
    _isLoading = true;
    _message = null;
    notifyListeners();

    final result = await _courseApi.fetchCourses(
      accessToken: accessToken,
      activeOnly: false,
    );

    if (!requestIsCurrent(request)) return;

    if (result.courses != null) {
      _courses = result.courses!.where((course) => course.active).toList();
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

    final request = beginRequest();
    _selectedCourseId = courseId;
    _students = [];
    _mentors = [];
    _selectedStudentIds = {};
    _selectedTeachingMentorIds = {};
    _selectedSupportingMentorIds = {};
    _isLoading = true;
    _message = null;
    notifyListeners();

    final studentResult = await _studentApi.fetchStudents(
      accessToken: accessToken,
      courseId: courseId,
      activeOnly: false,
    );

    if (!requestIsCurrent(request)) return;

    if (studentResult.students == null) {
      _message =
          studentResult.message ??
          _messageForStudentFailure(studentResult.failure);
      _isLoading = false;
      notifyListeners();
      return;
    }

    _students = studentResult.students!
        .where((student) => student.active)
        .toList();
    _selectedStudentIds = {for (final student in _students) student.id};

    final mentorResult = await _mentorApi.fetchCourseMentors(
      accessToken: accessToken,
      courseId: courseId,
    );

    if (!requestIsCurrent(request)) return;

    if (mentorResult.mentors == null) {
      _message =
          mentorResult.message ??
          _messageForMentorFailure(mentorResult.failure);
      _isLoading = false;
      notifyListeners();
      return;
    }

    _mentors =
        mentorResult.mentors!
            .where((mentor) => mentor.availableForSession)
            .toList()
          ..sort((a, b) => a.fullName.compareTo(b.fullName));

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

  void toggleTeachingMentor(int mentorId) {
    if (_isLoading || _isSaving || !_mentorIsAvailable(mentorId)) {
      return;
    }

    if (_selectedTeachingMentorIds.contains(mentorId)) {
      _selectedTeachingMentorIds.remove(mentorId);
    } else {
      _selectedSupportingMentorIds.remove(mentorId);
      _selectedTeachingMentorIds.add(mentorId);
    }

    notifyListeners();
  }

  void toggleSupportingMentor(int mentorId) {
    if (_isLoading || _isSaving || !_mentorIsAvailable(mentorId)) {
      return;
    }

    if (_selectedSupportingMentorIds.contains(mentorId)) {
      _selectedSupportingMentorIds.remove(mentorId);
    } else {
      _selectedTeachingMentorIds.remove(mentorId);
      _selectedSupportingMentorIds.add(mentorId);
    }

    notifyListeners();
  }

  void clearMentorSelection() {
    if (_isSaving) {
      return;
    }

    _selectedTeachingMentorIds = {};
    _selectedSupportingMentorIds = {};
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

    if (request.teachingMentorIds.isEmpty) {
      _message = 'Select at least one teaching mentor.';
      notifyListeners();
      return false;
    }

    final teachingIds = request.teachingMentorIds.toSet();
    final supportingIds = request.supportingMentorIds.toSet();

    if (teachingIds.intersection(supportingIds).isNotEmpty) {
      _message = 'A mentor cannot be both teaching and supporting.';
      notifyListeners();
      return false;
    }

    final availableMentorIds = {for (final mentor in _mentors) mentor.id};

    if (!availableMentorIds.containsAll(teachingIds.union(supportingIds))) {
      _message = 'Invalid mentor selection.';
      notifyListeners();
      return false;
    }

    if (!setEquals(teachingIds, _selectedTeachingMentorIds) ||
        !setEquals(supportingIds, _selectedSupportingMentorIds)) {
      _message = 'Invalid mentor selection.';
      notifyListeners();
      return false;
    }

    if (_isLoading || _isSaving) return false;

    final operation = beginRequest();
    _isSaving = true;
    _message = null;
    notifyListeners();

    final result = await _sessionLogApi.submitSessionLog(
      accessToken: accessToken,
      request: request,
    );

    if (!requestIsCurrent(operation)) return false;

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
    invalidateRequests();
    _courses = [];
    _students = [];
    _mentors = [];
    _selectedCourseId = null;
    _selectedStudentIds = {};
    _selectedTeachingMentorIds = {};
    _selectedSupportingMentorIds = {};
    _isLoading = false;
    _isSaving = false;
    _message = null;
    notifyListeners();
  }

  bool _mentorIsAvailable(int mentorId) {
    return _mentors.any((mentor) => mentor.id == mentorId);
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

  String _messageForMentorFailure(SharedCourseMentorsFailure? failure) {
    return switch (failure) {
      SharedCourseMentorsFailure.badRequest => 'Invalid mentor request.',
      SharedCourseMentorsFailure.unauthorized => 'Login expired.',
      SharedCourseMentorsFailure.forbidden => 'Mentor access denied.',
      SharedCourseMentorsFailure.notFound => 'Course not found.',
      SharedCourseMentorsFailure.serverError => 'Server error.',
      SharedCourseMentorsFailure.networkError => 'Cannot connect to server.',
      null => 'Unknown error.',
    };
  }
}
