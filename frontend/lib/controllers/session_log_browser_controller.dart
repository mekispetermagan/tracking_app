import '../models/models.dart';
import 'area_views.dart';
import 'feature_controller.dart';
import 'student_record_controller.dart';

class SessionLogBrowserData<M> {
  const SessionLogBrowserData.success({
    required this.sessionLogs,
    required this.courses,
    required this.students,
    required this.mentors,
  }) : message = null;

  const SessionLogBrowserData.failure(this.message)
    : sessionLogs = const [],
      courses = const [],
      students = const [],
      mentors = const [];

  final List<SessionLog> sessionLogs;
  final List<Course> courses;
  final List<Student> students;
  final List<M> mentors;
  final String? message;
}

abstract class SessionLogBrowserController<M> extends FeatureController {
  SessionLogBrowserController({
    StudentRecordController? studentRecordController,
  }) : studentRecordController =
           studentRecordController ?? StudentRecordController();

  final StudentRecordController studentRecordController;

  List<SessionLog> _sessionLogs = [];
  List<Course> _courses = [];
  List<Student> _students = [];
  List<M> _mentors = [];

  SessionLogAreaView _view = SessionLogAreaView.list;
  int? _selectedSessionLogId;
  int? _courseIdFilter;
  int? _mentorIdFilter;
  ProjectType? _projectTypeFilter;
  bool _isLoading = false;
  String? _message;

  List<SessionLog> get sessionLogs => List.unmodifiable(_sessionLogs);
  List<Course> get courses => List.unmodifiable(_courses);
  List<Student> get students => List.unmodifiable(_students);
  List<M> get mentors => List.unmodifiable(_mentors);
  SessionLogAreaView get view => _view;
  int? get selectedSessionLogId => _selectedSessionLogId;
  int? get courseIdFilter => _courseIdFilter;
  int? get mentorIdFilter => _mentorIdFilter;
  ProjectType? get projectTypeFilter => _projectTypeFilter;
  bool get isLoading => _isLoading;
  String? get message => _message;

  List<SessionLog> get visibleSessionLogs {
    return _sessionLogs.where((sessionLog) {
      final participantMentorIds = {
        ...sessionLog.teachingMentorIds,
        ...sessionLog.supportingMentorIds,
      };

      return (_courseIdFilter == null ||
              sessionLog.courseId == _courseIdFilter) &&
          (_mentorIdFilter == null ||
              participantMentorIds.contains(_mentorIdFilter)) &&
          (_projectTypeFilter == null ||
              sessionLog.projectType == _projectTypeFilter);
    }).toList();
  }

  List<Course> get filterCourses {
    final usedIds = {for (final log in _sessionLogs) log.courseId};
    return _courses.where((course) => usedIds.contains(course.id)).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  List<M> get filterMentors {
    final usedIds = <int>{};
    for (final log in _sessionLogs) {
      usedIds.addAll(log.teachingMentorIds);
      usedIds.addAll(log.supportingMentorIds);
    }

    return _mentors
        .where((mentor) => usedIds.contains(mentorId(mentor)))
        .toList()
      ..sort((a, b) => mentorName(a).compareTo(mentorName(b)));
  }

  SessionLog? get selectedSessionLog {
    final selectedId = _selectedSessionLogId;
    if (selectedId == null) return null;

    for (final log in _sessionLogs) {
      if (log.id == selectedId) return log;
    }
    return null;
  }

  bool get canView => selectedSessionLog != null && !_isLoading;

  int mentorId(M mentor);
  String mentorName(M mentor);

  Future<SessionLogBrowserData<M>> loadData({required String accessToken});

  Future<void> openList({required String accessToken}) async {
    final request = beginRequest();
    _view = SessionLogAreaView.list;
    _selectedSessionLogId = null;
    _sessionLogs = [];
    _courses = [];
    _students = [];
    _mentors = [];
    _isLoading = true;
    _message = null;
    notifyListeners();

    final data = await loadData(accessToken: accessToken);
    if (!requestIsCurrent(request)) return;

    _sessionLogs = data.sessionLogs;
    _courses = data.courses;
    _students = data.students;
    _mentors = data.mentors;
    _message = data.message;
    _isLoading = false;
    notifyListeners();
  }

  String courseNameFor(SessionLog log) {
    for (final course in _courses) {
      if (course.id == log.courseId) return course.name;
    }
    return 'Course #${log.courseId}';
  }

  String submittedByMentorNameFor(SessionLog log) {
    return _mentorNameForId(log.submittedByMentorProfileId);
  }

  String mentorNameFor(SessionLog log) => submittedByMentorNameFor(log);

  List<String> teachingMentorNamesFor(SessionLog log) {
    return _mentorNamesForIds(log.teachingMentorIds);
  }

  List<String> supportingMentorNamesFor(SessionLog log) {
    return _mentorNamesForIds(log.supportingMentorIds);
  }

  List<String> studentNamesFor(SessionLog log) {
    final namesById = {
      for (final student in _students)
        student.id: '${student.firstName} ${student.lastName}',
    };
    final names = [
      for (final id in log.studentIds) namesById[id] ?? 'Student #$id',
    ];
    names.sort();
    return names;
  }

  List<Student> studentsFor(SessionLog log) {
    final ids = log.studentIds.toSet();
    return _students.where((student) => ids.contains(student.id)).toList()
      ..sort((a, b) {
        final first = a.firstName.compareTo(b.firstName);
        return first != 0 ? first : a.lastName.compareTo(b.lastName);
      });
  }

  void selectSessionLog(int id) {
    if (_isLoading ||
        _selectedSessionLogId == id ||
        !_sessionLogs.any((log) => log.id == id)) {
      return;
    }
    _selectedSessionLogId = id;
    notifyListeners();
  }

  void openSelectedSessionLog() {
    if (!canView) {
      _message = 'No session log selected.';
      notifyListeners();
      return;
    }
    _view = SessionLogAreaView.detail;
    _message = null;
    notifyListeners();
  }

  void closeDetail() => _setView(SessionLogAreaView.list);
  void openPhotos() {
    if (_view == SessionLogAreaView.detail) _setView(SessionLogAreaView.photos);
  }

  void closePhotos() {
    if (_view == SessionLogAreaView.photos) _setView(SessionLogAreaView.detail);
  }

  Future<void> openStudentRecord({
    required String accessToken,
    required int studentId,
  }) async {
    final log = selectedSessionLog;
    if (log == null || !log.studentIds.contains(studentId)) {
      _message = 'Student not available.';
      notifyListeners();
      return;
    }

    _setView(SessionLogAreaView.studentRecord);
    await studentRecordController.load(
      accessToken: accessToken,
      studentId: studentId,
    );
  }

  void closeStudentRecord() {
    studentRecordController.reset();
    _setView(SessionLogAreaView.detail);
  }

  void setCourseIdFilter(int? value) {
    if (_courseIdFilter == value) return;
    _courseIdFilter = value;
    _clearSelectionIfHidden();
    notifyListeners();
  }

  void setMentorIdFilter(int? value) {
    if (_mentorIdFilter == value) return;
    _mentorIdFilter = value;
    _clearSelectionIfHidden();
    notifyListeners();
  }

  void setProjectTypeFilter(ProjectType? value) {
    if (_projectTypeFilter == value) return;
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
    if (_message == null) return;
    _message = null;
    notifyListeners();
  }

  void reset() {
    invalidateRequests();
    _sessionLogs = [];
    _courses = [];
    _students = [];
    _mentors = [];
    _view = SessionLogAreaView.list;
    _selectedSessionLogId = null;
    _courseIdFilter = null;
    _mentorIdFilter = null;
    _projectTypeFilter = null;
    _isLoading = false;
    _message = null;
    studentRecordController.reset();
    notifyListeners();
  }

  void _setView(SessionLogAreaView value) {
    if (_view == value) return;
    _view = value;
    _message = null;
    notifyListeners();
  }

  void _clearSelectionIfHidden() {
    final id = _selectedSessionLogId;
    if (id != null && !visibleSessionLogs.any((log) => log.id == id)) {
      _selectedSessionLogId = null;
    }
  }

  String _mentorNameForId(int id) {
    for (final mentor in _mentors) {
      if (mentorId(mentor) == id) return mentorName(mentor);
    }
    return 'Mentor #$id';
  }

  List<String> _mentorNamesForIds(List<int> ids) {
    return ids.map(_mentorNameForId).toList()..sort();
  }

  @override
  void dispose() {
    studentRecordController.dispose();
    super.dispose();
  }
}
