import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/api/api.dart';
import 'package:frontend/controllers/controllers.dart';
import 'package:frontend/models/models.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../support/core_fixtures.dart';

void main() {
  test('mentor profile loads, updates, changes PIN, and resets', () async {
    final client = MockClient((request) async {
      if (request.method == 'GET') return _json(mentorJson());
      if (request.url.path.endsWith('/pin')) return http.Response('', 204);
      return _json(mentorJson(firstName: 'Updated'));
    });
    final controller = MentorProfileController(
      api: MentorProfileApi(client: client),
    );
    await controller.loadProfile(accessToken: 'token');
    expect(controller.mentor?.id, 5);
    expect(
      await controller.updateProfile(
        accessToken: 'token',
        request: const MentorSelfUpdateRequest(
          firstName: 'Updated',
          lastName: 'Hopper',
          phone: '0700000005',
        ),
      ),
      isTrue,
    );
    expect(controller.mentor?.firstName, 'Updated');
    expect(
      await controller.changePin(
        accessToken: 'token',
        request: const MentorChangePinRequest(
          currentPin: '123456',
          newPin: '654321',
        ),
      ),
      isTrue,
    );
    expect(controller.message, 'PIN changed.');
    controller.reset();
    expect(controller.mentor, isNull);
  });

  test(
    'session-log controller loads course participants and owns selections',
    () async {
      final client = MockClient((request) async {
        if (request.url.path == '/api/shared/courses') {
          return _json([courseJson()]);
        }
        if (request.url.path == '/api/shared/students') {
          return _json([studentJson(), studentJson(id: 9, active: false)]);
        }
        if (request.url.path == '/api/shared/mentors') {
          return _json([
            {
              'id': 5,
              'first_name': 'Grace',
              'last_name': 'Hopper',
              'active': true,
              'assigned_to_course': true,
            },
            {
              'id': 6,
              'first_name': 'Away',
              'last_name': 'Mentor',
              'active': false,
              'assigned_to_course': true,
            },
          ]);
        }
        return http.Response('{}', 500);
      });
      final controller = MentorSessionLogController(
        sessionLogApi: MentorSessionLogApi(client: client),
        courseApi: SharedCourseApi(client: client),
        studentApi: SharedStudentApi(client: client),
        mentorApi: SharedCourseMentorsApi(client: client),
      );
      await controller.initialize(accessToken: 'token');
      await controller.selectCourse(accessToken: 'token', courseId: 8);
      expect(controller.students.map((item) => item.id), [7]);
      expect(controller.selectedStudentIds, {7});
      expect(controller.mentors.map((item) => item.id), [5]);
      controller.toggleTeachingMentor(5);
      expect(controller.canSubmit, isTrue);
      controller.toggleSupportingMentor(5);
      expect(controller.selectedTeachingMentorIds, isEmpty);
      expect(controller.selectedSupportingMentorIds, {5});
      controller.clearMentorSelection();
      expect(controller.canSubmit, isFalse);
    },
  );

  test('track students opens and closes the selected student record', () async {
    final client = MockClient((request) async {
      if (request.url.path == '/api/shared/students') {
        return _json([studentJson()]);
      }
      if (request.url.path.endsWith('/record')) {
        return _json({
          'student_id': 7,
          'first_name': 'Ada',
          'last_name': 'Lovelace',
          'attended_sessions': 2,
          'overall_activity_score': 3,
          'project_groups': <Object>[],
          'skill_games': <Object>[],
        });
      }
      return http.Response('{}', 500);
    });
    final controller = TrackStudentsController(
      studentApi: SharedStudentApi(client: client),
      studentRecordApi: SharedStudentRecordApi(client: client),
    );
    await controller.openList(accessToken: 'token');
    controller.selectStudent(7);
    await controller.openSelectedStudentRecord(accessToken: 'token');
    expect(controller.view, TrackStudentsView.record);
    expect(controller.recordController.studentRecord?.studentId, 7);
    controller.closeRecord();
    expect(controller.view, TrackStudentsView.list);
    expect(controller.recordController.studentRecord, isNull);
  });

  test(
    'curriculum controller loads, selects, links, and closes a chapter',
    () async {
      final client = MockClient(
        (_) async => _json({
          'categories': [
            {
              'id': 'robotics',
              'titles': {'eng': 'Robotics'},
              'chapters': [
                {
                  'slug': 'motors',
                  'titles': {'eng': 'Motors'},
                },
              ],
            },
          ],
        }),
      );
      final controller = CurriculumController(
        curriculumApi: CurriculumApi(client: client),
      );
      await controller.initialize();
      final chapter = controller.categories.single.chapters.single;
      controller.selectChapter(chapter);
      expect(controller.selectedChapterUrl, contains('chapter=motors'));
      expect(controller.selectedChapterUrl, contains('lang=eng'));
      controller.closeChapter();
      expect(controller.selectedChapter, isNull);
    },
  );

  test(
    'story archive exposes failure details and can clear/reset them',
    () async {
      final controller = StoryWinnerArchiveController(
        storyApi: SharedStoryApi(
          client: MockClient(
            (_) async =>
                http.Response(jsonEncode({'detail': 'Unavailable'}), 503),
          ),
        ),
      );
      expect(await controller.load(accessToken: 'token'), isFalse);
      expect(controller.message, 'Unavailable');
      controller.clearMessage();
      expect(controller.message, isNull);
      controller.reset();
      expect(controller.winners, isEmpty);
    },
  );
}

http.Response _json(Object body, [int status = 200]) =>
    http.Response(jsonEncode(body), status);
