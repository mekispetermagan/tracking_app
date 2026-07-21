import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/api/api.dart';
import 'package:frontend/controllers/controllers.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../support/core_fixtures.dart';

void main() {
  test(
    'mentor stories load courses, derive submission state, and rate',
    () async {
      final client = MockClient((request) async {
        if (request.url.path == '/api/shared/courses') {
          return _json([courseJson()]);
        }
        if (request.method == 'GET') {
          return _json([
            _mentorStory(id: 12, submitterId: 5, canRate: false),
            _mentorStory(id: 13, submitterId: 6, canRate: true),
          ]);
        }
        if (request.url.path.endsWith('/rating')) {
          return _json(
            _mentorStory(id: 13, submitterId: 6, canRate: true, rating: 4),
          );
        }
        return http.Response('{}', 500);
      });
      final controller = MentorStoryController(
        storyApi: MentorStoryApi(client: client),
        courseApi: SharedCourseApi(client: client),
      );
      await controller.initialize(accessToken: 'token', mentorProfileId: 5);
      expect(controller.courses.single.id, 8);
      expect(controller.hasSubmittedThisMonth, isTrue);
      expect(
        await controller.rateStory(
          accessToken: 'token',
          storyId: 13,
          rating: 4,
        ),
        isTrue,
      );
      expect(
        controller.stories.firstWhere((story) => story.id == 13).myRating,
        4,
      );
      controller.reset();
      expect(controller.stories, isEmpty);
    },
  );

  test(
    'admin stories filter active state and replace edited stories',
    () async {
      final client = MockClient((request) async {
        if (request.method == 'GET') {
          return _json([
            _adminStory(id: 12, active: true),
            _adminStory(id: 13, active: false),
          ]);
        }
        if (request.method == 'PUT') {
          return _json(_adminStory(id: 12, active: true, text: 'Edited'));
        }
        return http.Response('{}', 500);
      });
      final controller = AdminStoryController(
        storyApi: AdminStoryApi(client: client),
      );
      await controller.initialize(accessToken: 'token');
      expect(controller.stories.map((story) => story.id), [12]);
      controller.setActiveOnly(false);
      expect(controller.stories, hasLength(2));
      expect(
        await controller.updateStory(
          accessToken: 'token',
          storyId: 12,
          text: ' Edited ',
        ),
        isTrue,
      );
      expect(
        controller.stories.firstWhere((story) => story.id == 12).text,
        'Edited',
      );
    },
  );

  test(
    'session photos load course galleries and group mentor submissions',
    () async {
      final client = MockClient((request) async {
        if (request.url.path == '/api/shared/courses') {
          return _json([courseJson()]);
        }
        if (request.url.path.endsWith('/photos')) {
          return _json([
            _photo(id: 2, mentorId: 5, number: 2),
            _photo(id: 1, mentorId: 5, number: 1),
            _photo(id: 3, mentorId: 6, number: 1),
          ]);
        }
        return http.Response('{}', 500);
      });
      final controller = SessionPhotoController(
        sharedPhotoApi: SharedSessionPhotoApi(client: client),
        mentorPhotoApi: MentorSessionPhotoApi(client: client),
        courseApi: SharedCourseApi(client: client),
      );
      await controller.initializeCourseSelection(accessToken: 'token');
      controller.selectCourse(8);
      expect(
        await controller.loadSelectedCoursePhotos(accessToken: 'token'),
        isTrue,
      );
      expect(controller.hasSubmissionForMentor(5), isTrue);
      expect(controller.photosForMentor(5).map((photo) => photo.photoNumber), [
        1,
        2,
      ]);
      controller.closeGallery();
      expect(controller.photos, isEmpty);
    },
  );

  test(
    'course visits load related entities, filter, expand, and resolve names',
    () async {
      final client = MockClient((request) async {
        switch (request.url.path) {
          case '/api/admin/course-visit-reports':
            return _json([_report()]);
          case '/api/shared/courses':
            return _json([courseJson(), courseJson(id: 9, active: false)]);
          case '/api/shared/students':
            return _json([studentJson(), studentJson(id: 9, active: false)]);
          case '/api/admin/mentors':
            return _json([mentorJson(), mentorJson(id: 6, active: false)]);
        }
        return http.Response('{}', 500);
      });
      final controller = AdminCourseVisitController(
        courseVisitApi: AdminCourseVisitApi(client: client),
        courseApi: SharedCourseApi(client: client),
        studentApi: SharedStudentApi(client: client),
        mentorApi: AdminMentorApi(client: client),
      );
      await controller.initialize(accessToken: 'token');
      expect(controller.reports.single.id, 40);
      expect(controller.activeCourses.map((course) => course.id), [8]);
      expect(controller.courseNameFor(controller.reports.single), 'Robotics');
      expect(controller.mentorNameFor(5), 'Grace Hopper');
      expect(controller.studentNameFor(7), 'Ada Lovelace');
      controller.toggleReport(40);
      expect(controller.expandedReportId, 40);
      controller.setCourseFilter(9);
      expect(controller.filteredReports, isEmpty);
      expect(controller.expandedReportId, isNull);
    },
  );
}

Map<String, dynamic> _storyBase({
  required int id,
  required int submitterId,
  String text = 'A story',
}) => {
  'id': id,
  'text': text,
  'course_id': 8,
  'course_name': 'Robotics',
  'submitted_by_mentor_profile_id': submitterId,
  'submitter_first_name': 'Grace',
  'submitter_last_name': 'Hopper',
  'submission_month':
      '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-01',
  'photo': {
    'id': 2,
    'url': '/story.jpg',
    'uploaded_at': '2026-07-01T08:00:00Z',
  },
  'is_winner': false,
  'created_at': '2026-07-01T08:00:00Z',
  'updated_at': '2026-07-01T08:00:00Z',
};

Map<String, dynamic> _mentorStory({
  required int id,
  required int submitterId,
  required bool canRate,
  int? rating,
}) => {
  ..._storyBase(id: id, submitterId: submitterId),
  'my_rating': rating,
  'can_rate': canRate,
};

Map<String, dynamic> _adminStory({
  required int id,
  required bool active,
  String text = 'A story',
}) => {
  ..._storyBase(id: id, submitterId: 5, text: text),
  'active': active,
  'average_rating': 4.0,
  'rating_count': 2,
};

Map<String, dynamic> _photo({
  required int id,
  required int mentorId,
  required int number,
}) => {
  'id': id,
  'session_log_id': 11,
  'mentor_profile_id': mentorId,
  'mentor_name': 'Mentor $mentorId',
  'session_date': '2026-07-20',
  'photo_number': number,
  'url': '/photo-$id.jpg',
  'uploaded_at': '2026-07-20T13:00:00Z',
};

Map<String, dynamic> _report() => {
  'id': 40,
  'submitted_by_admin_profile_id': 2,
  'course_id': 8,
  'date': '2026-07-20',
  'session_status': 'fully_held',
  'teaching_took_place': 'yes',
  'session_followed_plan': 'yes',
  'learner_engagement': 'most',
  'equipment_adequate': 'yes',
  'environment_status': 'safe_and_respectful',
  'what_happened': 'Observed teaching',
  'main_strength': null,
  'main_problem': null,
  'support_provided': null,
  'course_health_rating': 4,
  'safeguarding_concern': false,
  'safeguarding_note': null,
  'mentors': <Object>[],
  'students': <Object>[],
  'actions': <Object>[],
  'created_at': '2026-07-20T13:00:00Z',
  'updated_at': '2026-07-20T13:00:00Z',
};

http.Response _json(Object body, [int status = 200]) =>
    http.Response(jsonEncode(body), status);
