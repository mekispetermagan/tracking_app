import 'package:flutter/foundation.dart';

import '../api/api.dart';
import '../models/models.dart';

enum MentorViewSessionLogsView { list, detail }

class MentorViewSessionLogsController extends ChangeNotifier {
  final MentorSessionLogApi _sessionLogApi;
  final SharedCourseApi _courseApi;
  final SharedStudentApi _studentApi;
  final SharedCourseMentorsApi _mentorApi;

  MentorViewSessionLogsController({
    MentorSessionLogApi? sessionLogApi,
    SharedCourseApi? courseApi,
    SharedStudentApi? studentApi,
    SharedCourseMentorsApi? mentorApi,
  }) : _sessionLogApi = sessionLogApi ?? MentorSessionLogApi(),
       _courseApi = courseApi ?? SharedCourseApi(),
       _studentApi = studentApi ?? SharedStudentApi(),
       _mentorApi = mentorApi ?? SharedCourseMentorsApi();

  List<SessionLog> _sessionLogs = [];
  List<Course> _courses = [];
  List<Student> _students = [];
  List<SharedMentor> _mentors = [];

  MentorViewSessionLogsView _view = MentorViewSessionLogsView.list;

  int? _selectedSessionLogId;
  int? _courseIdFilter;
  ProjectType? _projectTypeFilter;

  bool _isLoading = false;
  String? _message;

  MentorViewSessionLogsView get view => _view;

  int? get selectedSessionLogId => _selectedSessionLogId;
  int? get courseIdFilter => _courseIdFilter;
  ProjectType? get projectTypeFilter => _projectTypeFilter;

  bool get isLoading => _isLoading;
  String? get message => _message;

  List<SessionLog> get visibleSessionLogs {
    return _sessionLogs.where((sessionLog) {
      final courseMatches =
          _courseIdFilter == null || sessionLog.courseId == _courseIdFilter;

      final projectTypeMatches =
          _projectTypeFilter == null ||
          sessionLog.projectType == _projectTypeFilter;

      return courseMatches && projectTypeMatches;
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

  String submittedByMentorNameFor(SessionLog sessionLog) {
    return _mentorNameForId(sessionLog.submittedByMentorProfileId);
  }

  List<String> teachingMentorNamesFor(SessionLog sessionLog) {
    return _mentorNamesForIds(sessionLog.teachingMentorIds);
  }

  List<String> supportingMentorNamesFor(SessionLog sessionLog) {
    return _mentorNamesForIds(sessionLog.supportingMentorIds);
  }

  List<String> studentNamesFor(SessionLog sessionLog) {
    final studentsById = {for (final student in _students) student.id: student};

    final names = sessionLog.studentIds.map((studentId) {
      final student = studentsById[studentId];

      if (student == null) {
        return 'Student #$studentId';
      }

      return '${student.firstName} '
          '${student.lastName}';
    }).toList();

    names.sort();
    return names;
  }

  Future<void> openList({required String accessToken}) async {
    _view = MentorViewSessionLogsView.list;
    _selectedSessionLogId = null;
    _sessionLogs = [];
    _courses = [];
    _students = [];
    _mentors = [];
    _isLoading = true;
    _message = null;
    notifyListeners();

    final sessionLogResult = await _sessionLogApi.fetchAvailableSessionLogs(
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

    final mentorsById = <int, SharedMentor>{};
    final courseIds = {
      for (final sessionLog in _sessionLogs) sessionLog.courseId,
    };

    for (final courseId in courseIds) {
      final mentorResult = await _mentorApi.fetchCourseMentors(
        accessToken: accessToken,
        courseId: courseId,
      );

      if (mentorResult.mentors == null) {
        _finishLoading(
          mentorResult.message ??
              _messageForMentorFailure(mentorResult.failure),
        );
        return;
      }

      for (final mentor in mentorResult.mentors!) {
        mentorsById[mentor.id] = mentor;
      }
    }

    _mentors = mentorsById.values.toList()
      ..sort((a, b) => a.fullName.compareTo(b.fullName));

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

    _view = MentorViewSessionLogsView.detail;
    _message = null;
    notifyListeners();
  }

  void closeDetail() {
    _view = MentorViewSessionLogsView.list;
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

  void setProjectTypeFilter(ProjectType? value) {
    if (_projectTypeFilter == value) {
      return;
    }

    _projectTypeFilter = value;
    _clearSelectionIfHidden();
    notifyListeners();
  }

  void clearFilters() {
    if (_courseIdFilter == null && _projectTypeFilter == null) {
      return;
    }

    _courseIdFilter = null;
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
    _view = MentorViewSessionLogsView.list;
    _selectedSessionLogId = null;
    _courseIdFilter = null;
    _projectTypeFilter = null;
    _isLoading = false;
    _message = null;
    notifyListeners();
  }

  String _mentorNameForId(int mentorId) {
    for (final mentor in _mentors) {
      if (mentor.id == mentorId) {
        return mentor.fullName;
      }
    }

    return 'Mentor #$mentorId';
  }

  List<String> _mentorNamesForIds(List<int> mentorIds) {
    final names = mentorIds.map(_mentorNameForId).toList();

    names.sort();
    return names;
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

  String _messageForSessionLogFailure(MentorSessionLogFailure? failure) {
    return switch (failure) {
      MentorSessionLogFailure.badRequest => 'Invalid session log request.',
      MentorSessionLogFailure.unauthorized => 'Login expired.',
      MentorSessionLogFailure.forbidden => 'Session log access denied.',
      MentorSessionLogFailure.notFound => 'Session logs not found.',
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
