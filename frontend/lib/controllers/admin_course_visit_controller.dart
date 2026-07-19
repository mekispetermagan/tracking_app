import 'package:flutter/foundation.dart';

import '../api/api.dart';
import '../models/models.dart';

class AdminCourseVisitController extends ChangeNotifier {
  final AdminCourseVisitApi _courseVisitApi;
  final SharedCourseApi _courseApi;
  final SharedStudentApi _studentApi;
  final AdminMentorApi _mentorApi;

  AdminCourseVisitController({
    AdminCourseVisitApi? courseVisitApi,
    SharedCourseApi? courseApi,
    SharedStudentApi? studentApi,
    AdminMentorApi? mentorApi,
  }) : _courseVisitApi = courseVisitApi ?? AdminCourseVisitApi(),
       _courseApi = courseApi ?? SharedCourseApi(),
       _studentApi = studentApi ?? SharedStudentApi(),
       _mentorApi = mentorApi ?? AdminMentorApi();

  List<CourseVisitReport> _reports = [];
  List<Course> _courses = [];
  List<Student> _students = [];
  List<Mentor> _mentors = [];

  int? _selectedCourseId;
  int? _expandedReportId;

  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _message;

  List<CourseVisitReport> get reports => List.unmodifiable(_reports);
  List<Course> get courses => List.unmodifiable(_courses);
  List<Student> get students => List.unmodifiable(_students);
  List<Mentor> get mentors => List.unmodifiable(_mentors);

  List<CourseVisitReport> get filteredReports {
    final courseId = _selectedCourseId;

    if (courseId == null) {
      return List.unmodifiable(_reports);
    }

    return List.unmodifiable(
      _reports.where((report) => report.courseId == courseId),
    );
  }

  List<Course> get filterCourses {
    final usedCourseIds = {for (final report in _reports) report.courseId};

    final result = _courses
        .where((course) => usedCourseIds.contains(course.id))
        .toList();

    result.sort((first, second) => first.name.compareTo(second.name));

    return result;
  }

  List<Course> get activeCourses {
    final result = _courses.where((course) => course.active).toList();

    result.sort((first, second) => first.name.compareTo(second.name));

    return result;
  }

  List<Student> get activeStudents {
    return _students.where((student) => student.active).toList();
  }

  List<Mentor> get activeMentors {
    return _mentors.where((mentor) => mentor.active).toList();
  }

  int? get selectedCourseId => _selectedCourseId;
  int? get expandedReportId => _expandedReportId;

  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;

  String? get message => _message;

  int? get formInitialCourseId {
    final courseId = _selectedCourseId;

    if (courseId == null) {
      return null;
    }

    final courseIsActive = activeCourses.any((course) => course.id == courseId);

    return courseIsActive ? courseId : null;
  }

  String courseNameFor(CourseVisitReport report) {
    for (final course in _courses) {
      if (course.id == report.courseId) {
        return course.name;
      }
    }

    return 'Course #${report.courseId}';
  }

  String mentorNameFor(int mentorId) {
    for (final mentor in _mentors) {
      if (mentor.id == mentorId) {
        return mentor.fullName;
      }
    }

    return 'Mentor #$mentorId';
  }

  String studentNameFor(int studentId) {
    for (final student in _students) {
      if (student.id == studentId) {
        return student.fullName;
      }
    }

    return 'Student #$studentId';
  }

  Future<void> initialize({required String accessToken}) async {
    _reports = [];
    _courses = [];
    _students = [];
    _mentors = [];

    _selectedCourseId = null;
    _expandedReportId = null;

    _isSubmitting = false;

    await _loadData(accessToken: accessToken);
  }

  Future<void> refresh({required String accessToken}) async {
    if (_isLoading || _isSubmitting) {
      return;
    }

    await _loadData(accessToken: accessToken);
  }

  void setCourseFilter(int? courseId) {
    if (_selectedCourseId == courseId) {
      return;
    }

    _selectedCourseId = courseId;
    _expandedReportId = null;
    notifyListeners();
  }

  void toggleReport(int reportId) {
    final reportExists = _reports.any((report) => report.id == reportId);

    if (!reportExists) {
      return;
    }

    _expandedReportId = _expandedReportId == reportId ? null : reportId;

    notifyListeners();
  }

  Future<bool> submitReport({
    required String accessToken,
    required CourseVisitReportCreateRequest request,
  }) async {
    if (_isLoading || _isSubmitting) {
      return false;
    }

    _isSubmitting = true;
    _message = null;
    notifyListeners();

    final result = await _courseVisitApi.submitReport(
      accessToken: accessToken,
      request: request,
    );

    final report = result.report;

    if (report == null) {
      _message = result.message ?? _messageForVisitFailure(result.failure);

      _isSubmitting = false;
      notifyListeners();
      return false;
    }

    _replaceReport(report);

    if (_selectedCourseId != null && _selectedCourseId != report.courseId) {
      _selectedCourseId = report.courseId;
    }

    _expandedReportId = report.id;
    _isSubmitting = false;
    notifyListeners();

    return true;
  }

  void clearMessage() {
    if (_message == null) {
      return;
    }

    _message = null;
    notifyListeners();
  }

  void reset() {
    _reports = [];
    _courses = [];
    _students = [];
    _mentors = [];

    _selectedCourseId = null;
    _expandedReportId = null;

    _isLoading = false;
    _isSubmitting = false;
    _message = null;

    notifyListeners();
  }

  Future<void> _loadData({required String accessToken}) async {
    _isLoading = true;
    _message = null;
    notifyListeners();

    final reportResult = await _courseVisitApi.fetchReports(
      accessToken: accessToken,
    );

    if (reportResult.reports == null) {
      _finishLoading(
        reportResult.message ?? _messageForVisitFailure(reportResult.failure),
      );
      return;
    }

    _reports = reportResult.reports!;

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

    if (_expandedReportId != null) {
      final expandedReportStillExists = _reports.any(
        (report) => report.id == _expandedReportId,
      );

      if (!expandedReportStillExists) {
        _expandedReportId = null;
      }
    }

    _finishLoading(null);
  }

  void _replaceReport(CourseVisitReport report) {
    _reports = [
      report,
      for (final existing in _reports)
        if (existing.id != report.id) existing,
    ]..sort(_compareReports);
  }

  int _compareReports(CourseVisitReport first, CourseVisitReport second) {
    final dateComparison = second.date.compareTo(first.date);

    if (dateComparison != 0) {
      return dateComparison;
    }

    return second.id.compareTo(first.id);
  }

  void _finishLoading(String? message) {
    _message = message;
    _isLoading = false;
    notifyListeners();
  }

  String _messageForVisitFailure(AdminCourseVisitFailure? failure) {
    return switch (failure) {
      AdminCourseVisitFailure.badRequest => 'Invalid visit report data.',
      AdminCourseVisitFailure.unauthorized => 'Login expired.',
      AdminCourseVisitFailure.forbidden => 'Visit report access denied.',
      AdminCourseVisitFailure.notFound => 'Course not found.',
      AdminCourseVisitFailure.conflict => 'Visit report conflict.',
      AdminCourseVisitFailure.serverError => 'Server error.',
      AdminCourseVisitFailure.networkError => 'Cannot connect to server.',
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
