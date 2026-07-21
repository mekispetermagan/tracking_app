import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/api/api.dart';
import 'package:frontend/controllers/controllers.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../support/core_fixtures.dart';

Map<String, dynamic> _log({int id = 11, int courseId = 8}) => {
  'id': id,
  'submitted_by_mentor_profile_id': 5,
  'course_id': courseId,
  'date': '2026-07-20',
  'project_title': 'Robot arm',
  'project_type': 'robotics',
  'other_project_type': null,
  'games_played': null,
  'completion_status': 'completed',
  'what_worked': null,
  'challenges': null,
  'next_step': null,
  'teaching_mentor_ids': [5],
  'supporting_mentor_ids': <int>[],
  'student_ids': [7],
  'created_at': '2026-07-20T12:30:00Z',
};

void main() {
  test('admin session browser composes logs with reference data', () async {
    final client = MockClient((request) async {
      final body = switch (request.url.path) {
        '/api/admin/session-logs' => [_log()],
        '/api/shared/courses' => [courseJson()],
        '/api/shared/students' => [studentJson()],
        '/api/admin/mentors' => [mentorJson()],
        _ => throw StateError('Unexpected ${request.url}'),
      };
      return http.Response(jsonEncode(body), 200);
    });
    final controller = AdminViewSessionLogsController(
      sessionLogApi: AdminSessionLogApi(client: client),
      courseApi: SharedCourseApi(client: client),
      studentApi: SharedStudentApi(client: client),
      mentorApi: AdminMentorApi(client: client),
    );

    await controller.openList(accessToken: 'token');

    expect(controller.sessionLogs.single.id, 11);
    expect(controller.courses.single.name, 'Robotics');
    expect(controller.students.single.firstName, 'Ada');
    expect(controller.mentorName(controller.mentors.single), 'Grace Hopper');
  });

  test(
    'mentor session browser deduplicates mentors across logged courses',
    () async {
      final client = MockClient((request) async {
        final body = switch (request.url.path) {
          '/api/mentor/session-logs' => [_log(), _log(id: 12, courseId: 9)],
          '/api/shared/courses' => [courseJson(), courseJson(id: 9)],
          '/api/shared/students' => [studentJson()],
          '/api/shared/mentors' => [
            {
              'id': 5,
              'first_name': 'Grace',
              'last_name': 'Hopper',
              'active': true,
              'assigned_to_course': true,
            },
          ],
          _ => throw StateError('Unexpected ${request.url}'),
        };
        return http.Response(jsonEncode(body), 200);
      });
      final controller = MentorViewSessionLogsController(
        sessionLogApi: MentorSessionLogApi(client: client),
        courseApi: SharedCourseApi(client: client),
        studentApi: SharedStudentApi(client: client),
        mentorApi: SharedCourseMentorsApi(client: client),
      );

      await controller.openList(accessToken: 'token');

      expect(controller.sessionLogs, hasLength(2));
      expect(controller.mentors, hasLength(1));
      expect(controller.mentorName(controller.mentors.single), 'Grace Hopper');
    },
  );

  test(
    'session browsers stop early for empty logs and expose API detail',
    () async {
      final emptyClient = MockClient((_) async => http.Response('[]', 200));
      final empty = AdminViewSessionLogsController(
        sessionLogApi: AdminSessionLogApi(client: emptyClient),
      );
      await empty.openList(accessToken: 'token');
      expect(empty.sessionLogs, isEmpty);
      expect(empty.message, isNull);

      final failedClient = MockClient(
        (_) async =>
            http.Response(jsonEncode({'detail': 'Access revoked'}), 403),
      );
      final failed = MentorViewSessionLogsController(
        sessionLogApi: MentorSessionLogApi(client: failedClient),
      );
      await failed.openList(accessToken: 'token');
      expect(failed.message, 'Access revoked');
    },
  );
}
