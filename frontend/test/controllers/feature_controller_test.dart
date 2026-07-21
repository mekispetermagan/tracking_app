import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:agu_frontend/api/api.dart';
import 'package:agu_frontend/controllers/area_views.dart';
import 'package:agu_frontend/controllers/session_log_browser_controller.dart';
import 'package:agu_frontend/controllers/student_record_controller.dart';
import 'package:agu_frontend/models/models.dart';

void main() {
  test(
    'reset prevents a late student-record result from restoring state',
    () async {
      final api = _DelayedStudentRecordApi();
      final controller = StudentRecordController(studentRecordApi: api);

      final load = controller.load(accessToken: 'token', studentId: 7);
      controller.reset();
      api.complete(_record(7));

      expect(await load, isFalse);
      expect(controller.studentRecord, isNull);
      expect(controller.isLoading, isFalse);
    },
  );

  test('shared session browser ignores data returned after reset', () async {
    final controller = _DelayedSessionLogBrowser();

    final load = controller.openList(accessToken: 'token');
    controller.reset();
    controller.complete();
    await load;

    expect(controller.sessionLogs, isEmpty);
    expect(controller.isLoading, isFalse);
    expect(controller.message, isNull);
  });

  test('shared session browser owns filtering and nested navigation', () async {
    final controller = _LoadedSessionLogBrowser();
    await controller.openList(accessToken: 'token');

    controller.selectSessionLog(999);
    expect(controller.selectedSessionLogId, isNull);

    controller.selectSessionLog(1);
    controller.openSelectedSessionLog();
    expect(controller.view, SessionLogAreaView.detail);

    controller.openPhotos();
    expect(controller.view, SessionLogAreaView.photos);
    controller.closePhotos();
    expect(controller.view, SessionLogAreaView.detail);

    controller.closeDetail();
    controller.setCourseIdFilter(99);
    expect(controller.visibleSessionLogs, isEmpty);
    expect(controller.selectedSessionLogId, isNull);
  });
}

class _DelayedStudentRecordApi extends SharedStudentRecordApi {
  final _result = Completer<SharedStudentRecordResult>();

  @override
  Future<SharedStudentRecordResult> fetchStudentRecord({
    required String accessToken,
    required int studentId,
  }) {
    return _result.future;
  }

  void complete(StudentRecord record) {
    _result.complete(SharedStudentRecordResult.success(studentRecord: record));
  }
}

class _DelayedSessionLogBrowser extends SessionLogBrowserController<String> {
  final _result = Completer<SessionLogBrowserData<String>>();

  @override
  int mentorId(String mentor) => int.parse(mentor);

  @override
  String mentorName(String mentor) => mentor;

  @override
  Future<SessionLogBrowserData<String>> loadData({
    required String accessToken,
  }) {
    return _result.future;
  }

  void complete() {
    _result.complete(
      const SessionLogBrowserData.success(
        sessionLogs: [],
        courses: [],
        students: [],
        mentors: [],
      ),
    );
  }
}

class _LoadedSessionLogBrowser extends SessionLogBrowserController<String> {
  @override
  int mentorId(String mentor) => int.parse(mentor);

  @override
  String mentorName(String mentor) => 'Mentor $mentor';

  @override
  Future<SessionLogBrowserData<String>> loadData({
    required String accessToken,
  }) async {
    return SessionLogBrowserData.success(
      sessionLogs: [_sessionLog()],
      courses: const [
        Course(
          id: 10,
          name: 'Course',
          description: '',
          countryId: 1,
          dayOfWeek: 1,
          startTime: '10:00',
          active: true,
          mentorIds: [2],
          studentIds: [7],
        ),
      ],
      students: const [
        Student(
          id: 7,
          firstName: 'Test',
          lastName: 'Student',
          originCountryId: 1,
          birthYear: 2010,
          gender: null,
          active: true,
          courseIds: [10],
        ),
      ],
      mentors: const ['2'],
    );
  }
}

StudentRecord _record(int id) {
  return StudentRecord(
    studentId: id,
    firstName: 'Test',
    lastName: 'Student',
    attendedSessions: 1,
    overallActivityScore: 1,
    projectGroups: const [],
    skillGames: const [],
  );
}

SessionLog _sessionLog() {
  final now = DateTime(2026);
  return SessionLog(
    id: 1,
    submittedByMentorProfileId: 2,
    courseId: 10,
    date: now,
    projectTitle: 'Project',
    projectType: ProjectType.scratch,
    otherProjectType: null,
    gamesPlayed: null,
    completionStatus: CompletionStatus.completed,
    whatWorked: null,
    challenges: null,
    nextStep: null,
    teachingMentorIds: const [2],
    supportingMentorIds: const [],
    studentIds: const [7],
    createdAt: now,
  );
}
