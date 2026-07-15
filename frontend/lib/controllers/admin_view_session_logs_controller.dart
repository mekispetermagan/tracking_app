import 'package:flutter/foundation.dart';

import '../api/api.dart';
import '../models/models.dart';

enum AdminSessionLogView { list, detail }

class AdminViewSessionLogsController extends ChangeNotifier {
  final AdminSessionLogApi _sessionLogApi;
  final SharedCourseApi _courseApi;
  final SharedStudentApi _studentApi;
  final AdminMentorApi _mentorApi;

  AdminViewSessionLogsController({
    AdminSessionLogApi? sessionLogApi,
    SharedCourseApi? courseApi,
    SharedStudentApi? studentApi,
    AdminMentorApi? mentorApi,
  }) : _sessionLogApi = sessionLogApi ?? AdminSessionLogApi(),
       _courseApi = courseApi ?? SharedCourseApi(),
       _studentApi = studentApi ?? SharedStudentApi(),
       _mentorApi = mentorApi ?? AdminMentorApi();

  List<SessionLog> _sessionLogs = [];
  List<Course> _courses = [];
  List<Student> _students = [];
  List<Mentor> _mentors = [];

  AdminSessionLogView _view = AdminSessionLogView.list;

  int? _selectedSessionLogId;
  int? _courseIdFilter;
  int? _mentorIdFilter;
  ProjectType? _projectTypeFilter;

  bool _isLoading = false;
  String? _message;

  List<SessionLog> get sessionLogs => List.unmodifiable(_sessionLogs);
  List<Course> get courses => List.unmodifiable(_courses);
  List<Student> get students => List.unmodifiable(_students);
  List<Mentor> get mentors => List.unmodifiable(_mentors);

  AdminSessionLogView get view => _view;

  int? get selectedSessionLogId => _selectedSessionLogId;
  int? get courseIdFilter => _courseIdFilter;
  int? get mentorIdFilter => _mentorIdFilter;
  ProjectType? get projectTypeFilter => _projectTypeFilter;

  bool get isLoading => _isLoading;
  String? get message => _message;

  List<SessionLog> get visibleSessionLogs {
    return _sessionLogs.where((sessionLog) {
      final courseMatches =
          _courseIdFilter == null || sessionLog.courseId == _courseIdFilter;

      final mentorMatches =
          _mentorIdFilter == null ||
          sessionLog.mentorProfileId == _mentorIdFilter;

      final projectTypeMatches =
          _projectTypeFilter == null ||
          sessionLog.projectType == _projectTypeFilter;

      return courseMatches && mentorMatches && projectTypeMatches;
    }).toList();
  }

  List<Course> get filterCourses {
    final usedCourseIds = {
      for (final sessionLog in _sessionLogs) sessionLog.courseId,
    };

    final result = _courses
        .where((course) => usedCourseIds.contains(course.id))
        .toList();

    result.sort((a, b) => a.name.compareTo(b.name));
    return result;
  }

  List<Mentor> get filterMentors {
    final usedMentorIds = {
      for (final sessionLog in _sessionLogs) sessionLog.mentorProfileId,
    };

    final result = _mentors
        .where((mentor) => usedMentorIds.contains(mentor.id))
        .toList();

    result.sort((a, b) {
      final firstNameComparison = a.firstName.compareTo(b.firstName);

      if (firstNameComparison != 0) {
        return firstNameComparison;
      }

      return a.lastName.compareTo(b.lastName);
    });

    return result;
  }

  SessionLog? get selectedSessionLog {
    final selectedId = _selectedSessionLogId;

    if (selectedId == null) {
      return null;
    }

    for (final sessionLog in _sessionLogs) {
      if (sessionLog.id == selectedId) {
        return sessionLog;
      }
    }

    return null;
  }

  bool get canView => selectedSessionLog != null && !_isLoading;

  String courseNameFor(SessionLog sessionLog) {
    for (final course in _courses) {
      if (course.id == sessionLog.courseId) {
        return course.name;
      }
    }

    return 'Course #${sessionLog.courseId}';
  }

  String mentorNameFor(SessionLog sessionLog) {
    for (final mentor in _mentors) {
      if (mentor.id == sessionLog.mentorProfileId) {
        return '${mentor.firstName} ${mentor.lastName}';
      }
    }

    return 'Mentor #${sessionLog.mentorProfileId}';
  }

  List<String> studentNamesFor(SessionLog sessionLog) {
    final studentsById = {for (final student in _students) student.id: student};

    final names = sessionLog.studentIds.map((studentId) {
      final student = studentsById[studentId];

      if (student == null) {
        return 'Student #$studentId';
      }

      return '${student.firstName} ${student.lastName}';
    }).toList();

    names.sort();
    return names;
  }

  Future<void> openList({required String accessToken}) async {
    _view = AdminSessionLogView.list;
    _selectedSessionLogId = null;
    _sessionLogs = [];
    _courses = [];
    _students = [];
    _mentors = [];
    _isLoading = true;
    _message = null;
    notifyListeners();

    final sessionLogResult = await _sessionLogApi.fetchSessionLogs(
      accessToken: accessToken,
    );

    if (sessionLogResult.sessionLogs == null) {
      _finishLoading(
        sessionLogResult.message ??
            _messageForSessionLogFailure(sessionLogResult.failure),
      );
      return;
    }

    _sessionLogs = sessionLogResult.sessionLogs!;

    if (_sessionLogs.isEmpty) {
      _finishLoading(null);
      return;
    }

    final courseResult = await _courseApi.fetchCourses(
      accessToken: accessToken,
      activeOnly: false,
    );

    if (courseResult.courses == null) {
      _finishLoading(
        courseResult.message ?? _messageForCourseFailure(courseResult.failure),
      );
      return;
    }

    _courses = courseResult.courses!;

    final studentResult = await _studentApi.fetchStudents(
      accessToken: accessToken,
      activeOnly: false,
    );

    if (studentResult.students == null) {
      _finishLoading(
        studentResult.message ??
            _messageForStudentFailure(studentResult.failure),
      );
      return;
    }

    _students = studentResult.students!;

    final mentorResult = await _mentorApi.fetchMentors(
      accessToken: accessToken,
      activeOnly: false,
    );

    if (mentorResult.mentors == null) {
      _finishLoading(
        mentorResult.message ?? _messageForMentorFailure(mentorResult.failure),
      );
      return;
    }

    _mentors = mentorResult.mentors!;

    _finishLoading(null);
  }

  void selectSessionLog(int sessionLogId) {
    if (_selectedSessionLogId == sessionLogId) {
      return;
    }

    _selectedSessionLogId = sessionLogId;
    notifyListeners();
  }

  void openSelectedSessionLog() {
    if (!canView) {
      _message = 'No session log selected.';
      notifyListeners();
      return;
    }

    _view = AdminSessionLogView.detail;
    _message = null;
    notifyListeners();
  }

  void closeDetail() {
    _view = AdminSessionLogView.list;
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

  void setMentorIdFilter(int? value) {
    if (_mentorIdFilter == value) {
      return;
    }

    _mentorIdFilter = value;
    _clearSelectionIfHidden();
    notifyListeners();
  }

  void setProjectTypeFilter(ProjectType? value) {
    if (_projectTypeFilter == value) {
      return;
    }

    _projectTypeFilter = value;
    _clearSelectionIfHidden();
    notifyListeners();
  }

  void clearFilters() {
    if (_courseIdFilter == null &&
        _mentorIdFilter == null &&
        _projectTypeFilter == null) {
      return;
    }

    _courseIdFilter = null;
    _mentorIdFilter = null;
    _projectTypeFilter = null;
    notifyListeners();
  }

  void clearMessage() {
    if (_message == null) {
      return;
    }

    _message = null;
    notifyListeners();
  }

  void reset() {
    _sessionLogs = [];
    _courses = [];
    _students = [];
    _mentors = [];
    _view = AdminSessionLogView.list;
    _selectedSessionLogId = null;
    _courseIdFilter = null;
    _mentorIdFilter = null;
    _projectTypeFilter = null;
    _isLoading = false;
    _message = null;
    notifyListeners();
  }

  void _clearSelectionIfHidden() {
    final selectedId = _selectedSessionLogId;

    if (selectedId == null) {
      return;
    }

    final stillVisible = visibleSessionLogs.any(
      (sessionLog) => sessionLog.id == selectedId,
    );

    if (!stillVisible) {
      _selectedSessionLogId = null;
    }
  }

  void _finishLoading(String? message) {
    _message = message;
    _isLoading = false;
    notifyListeners();
  }

  String _messageForSessionLogFailure(AdminSessionLogFailure? failure) {
    return switch (failure) {
      AdminSessionLogFailure.badRequest => 'Invalid session log request.',
      AdminSessionLogFailure.unauthorized => 'Login expired.',
      AdminSessionLogFailure.forbidden => 'Session log access denied.',
      AdminSessionLogFailure.serverError => 'Server error.',
      AdminSessionLogFailure.networkError => 'Cannot connect to server.',
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

  String _messageForMentorFailure(AdminMentorFailure? failure) {
    return switch (failure) {
      AdminMentorFailure.badRequest => 'Invalid mentor data.',
      AdminMentorFailure.unauthorized => 'Login expired.',
      AdminMentorFailure.forbidden => 'Mentor access denied.',
      AdminMentorFailure.notFound => 'Mentor not found.',
      AdminMentorFailure.conflict => 'Mentor conflict.',
      AdminMentorFailure.serverError => 'Server error.',
      AdminMentorFailure.networkError => 'Cannot connect to server.',
      null => 'Unknown error.',
    };
  }
}
