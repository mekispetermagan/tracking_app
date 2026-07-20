import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/api/api.dart';
import 'package:frontend/config/api_config.dart';
import 'package:frontend/models/models.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

typedef ApiInvocation = Future<Object?> Function(http.Client client);

class RecordingClient extends http.BaseClient {
  http.BaseRequest? request;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    this.request = request;
    return http.StreamedResponse(Stream.value(utf8.encode('{}')), 500);
  }
}

void main() {
  const token = 'contract-token';

  void contract(
    String name, {
    required String method,
    required String path,
    required ApiInvocation invoke,
    Map<String, String> query = const {},
    Object? jsonBody,
    bool authenticated = true,
    String? origin,
  }) {
    test(name, () async {
      http.Request? captured;
      final client = MockClient((request) async {
        captured = request;
        return http.Response('{}', 500);
      });

      await invoke(client);

      final request = captured!;
      expect(request, isNotNull, reason: 'No request was sent');
      expect(request.method, method);
      expect(request.url.origin, origin ?? Uri.parse(ApiConfig.baseUrl).origin);
      expect(request.url.path, path);
      expect(request.url.queryParameters, query);
      expect(
        request.headers['authorization'],
        authenticated ? 'Bearer $token' : isNull,
      );
      if (jsonBody != null) expect(jsonDecode(request.body), jsonBody);
    });
  }

  const courseCreate = CourseCreateRequest(
    name: 'Robotics',
    countryId: 2,
    dayOfWeek: 6,
    startTime: '09:30',
    mentorIds: [3],
    studentIds: [4],
  );
  const courseUpdate = CourseUpdateRequest(
    name: 'Robotics+',
    description: 'Updated',
    countryId: 2,
    dayOfWeek: 5,
    startTime: '10:00',
    active: true,
    mentorIds: [3],
    studentIds: [4],
  );
  const studentCreate = StudentCreateRequest(
    firstName: 'Ada',
    lastName: 'Lovelace',
    active: true,
    courseIds: [9],
  );
  const studentUpdate = StudentUpdateRequest(
    firstName: 'Ada',
    lastName: 'Byron',
    originCountryId: 2,
    birthYear: 2010,
    gender: 'female',
    active: false,
    courseIds: [9],
  );
  const mentorStudentCreate = MentorStudentCreateRequest(
    firstName: 'Grace',
    lastName: 'Hopper',
    courseIds: [9],
  );
  const mentorStudentUpdate = MentorStudentUpdateRequest(
    firstName: 'Grace',
    lastName: 'Murray',
    originCountryId: 3,
    birthYear: 2011,
    gender: 'female',
    courseIds: [9],
  );
  const mentorCreate = MentorCreateRequest(
    firstName: 'New',
    lastName: 'Mentor',
    phone: '256700000001',
    temporaryPin: '1234',
    courseIds: [9],
  );
  const mentorUpdate = MentorUpdateRequest(
    firstName: 'Updated',
    lastName: 'Mentor',
    phone: '256700000002',
    countryId: 2,
    preferredLanguage: 'en',
    active: true,
    courseIds: [9],
  );
  const profileUpdate = MentorSelfUpdateRequest(
    firstName: 'Profile',
    lastName: 'Mentor',
    phone: '256700000003',
  );
  const pinChange = MentorChangePinRequest(currentPin: '1234', newPin: '5678');
  const resetPin = MentorResetPinRequest(temporaryPin: '9876');
  final sessionCreate = SessionLogCreateRequest(
    courseId: 9,
    date: DateTime(2026, 7, 20),
    projectTitle: 'Robot',
    projectType: ProjectType.robotics,
    completionStatus: CompletionStatus.completed,
    teachingMentorIds: const [5],
    supportingMentorIds: const [6],
    studentIds: const [7],
  );
  final visitCreate = CourseVisitReportCreateRequest(
    courseId: 9,
    date: DateTime(2026, 7, 20),
    sessionStatus: CourseVisitSessionStatus.fullyHeld,
    teachingTookPlace: CourseVisitAnswer.yes,
    whatHappened: 'Observed session',
    courseHealthRating: 4,
    mentors: const [CourseVisitMentor(mentorId: 5)],
    students: const [CourseVisitStudent(studentId: 7)],
  );

  group('authentication', () {
    contract(
      'mentorLogin',
      method: 'POST',
      path: '/api/auth/mentor/login',
      authenticated: false,
      jsonBody: {'phone': '256700000000', 'pin': '1234'},
      invoke: (client) => AuthApi(
        client: client,
      ).mentorLogin(phone: '256700000000', pin: '1234'),
    );
    contract(
      'adminLogin',
      method: 'POST',
      path: '/api/auth/admin/login',
      authenticated: false,
      jsonBody: {'phone': '256700000000', 'password': 'secret'},
      invoke: (client) => AuthApi(
        client: client,
      ).adminLogin(phone: '256700000000', password: 'secret'),
    );
    contract(
      'changeMentorPin',
      method: 'POST',
      path: '/api/auth/mentor/change-pin',
      jsonBody: {'new_pin': '5678'},
      invoke: (client) => AuthApi(
        client: client,
      ).changeMentorPin(setupToken: token, newPin: '5678'),
    );
    contract(
      'changeAdminPassword',
      method: 'POST',
      path: '/api/auth/admin/change-password',
      jsonBody: {'new_password': 'new-secret'},
      invoke: (client) => AuthApi(
        client: client,
      ).changeAdminPassword(setupToken: token, newPassword: 'new-secret'),
    );
    contract(
      'mentorMe',
      method: 'GET',
      path: '/api/auth/mentor/me',
      invoke: (client) => AuthApi(client: client).mentorMe(accessToken: token),
    );
    contract(
      'adminMe',
      method: 'GET',
      path: '/api/auth/admin/me',
      invoke: (client) => AuthApi(client: client).adminMe(accessToken: token),
    );
  });

  group('courses', () {
    contract(
      'createCourse',
      method: 'POST',
      path: '/api/admin/courses',
      jsonBody: courseCreate.toJson(),
      invoke: (client) => AdminCourseApi(
        client: client,
      ).createCourse(accessToken: token, request: courseCreate),
    );
    contract(
      'deactivateCourse',
      method: 'POST',
      path: '/api/admin/courses/8/deactivate',
      invoke: (client) => AdminCourseApi(
        client: client,
      ).deactivateCourse(accessToken: token, courseId: 8),
    );
    contract(
      'fetchCourses',
      method: 'GET',
      path: '/api/shared/courses',
      query: {'active_only': 'false'},
      invoke: (client) => SharedCourseApi(
        client: client,
      ).fetchCourses(accessToken: token, activeOnly: false),
    );
    contract(
      'fetchCourse',
      method: 'GET',
      path: '/api/shared/courses/8',
      invoke: (client) => SharedCourseApi(
        client: client,
      ).fetchCourse(accessToken: token, courseId: 8),
    );
    contract(
      'updateCourse',
      method: 'PUT',
      path: '/api/shared/courses/8',
      jsonBody: courseUpdate.toJson(),
      invoke: (client) => SharedCourseApi(
        client: client,
      ).updateCourse(accessToken: token, courseId: 8, request: courseUpdate),
    );
    contract(
      'fetchCourseMentors',
      method: 'GET',
      path: '/api/shared/mentors',
      query: {'course_id': '8'},
      invoke: (client) => SharedCourseMentorsApi(
        client: client,
      ).fetchCourseMentors(accessToken: token, courseId: 8),
    );
  });

  group('students', () {
    contract(
      'fetchStudents',
      method: 'GET',
      path: '/api/shared/students',
      query: {'active_only': 'false', 'course_id': '9'},
      invoke: (client) => SharedStudentApi(
        client: client,
      ).fetchStudents(accessToken: token, activeOnly: false, courseId: 9),
    );
    contract(
      'fetchStudent',
      method: 'GET',
      path: '/api/shared/students/7',
      invoke: (client) => SharedStudentApi(
        client: client,
      ).fetchStudent(accessToken: token, studentId: 7),
    );
    contract(
      'createStudent',
      method: 'POST',
      path: '/api/shared/students',
      jsonBody: studentCreate.toJson(),
      invoke: (client) => SharedStudentApi(
        client: client,
      ).createStudent(accessToken: token, request: studentCreate),
    );
    contract(
      'createStudentAsMentor',
      method: 'POST',
      path: '/api/shared/students',
      jsonBody: mentorStudentCreate.toJson(),
      invoke: (client) => SharedStudentApi(
        client: client,
      ).createStudentAsMentor(accessToken: token, request: mentorStudentCreate),
    );
    contract(
      'updateStudent',
      method: 'PUT',
      path: '/api/shared/students/7',
      jsonBody: studentUpdate.toJson(),
      invoke: (client) => SharedStudentApi(
        client: client,
      ).updateStudent(accessToken: token, studentId: 7, request: studentUpdate),
    );
    contract(
      'updateStudentAsMentor',
      method: 'PUT',
      path: '/api/shared/students/7',
      jsonBody: mentorStudentUpdate.toJson(),
      invoke: (client) =>
          SharedStudentApi(client: client).updateStudentAsMentor(
            accessToken: token,
            studentId: 7,
            request: mentorStudentUpdate,
          ),
    );
    contract(
      'fetchStudentRecord',
      method: 'GET',
      path: '/api/shared/students/7/record',
      invoke: (client) => SharedStudentRecordApi(
        client: client,
      ).fetchStudentRecord(accessToken: token, studentId: 7),
    );
  });

  group('mentors', () {
    contract(
      'fetchMentors',
      method: 'GET',
      path: '/api/admin/mentors',
      query: {'active_only': 'true'},
      invoke: (client) => AdminMentorApi(
        client: client,
      ).fetchMentors(accessToken: token, activeOnly: true),
    );
    contract(
      'fetchMentor',
      method: 'GET',
      path: '/api/admin/mentors/5',
      invoke: (client) => AdminMentorApi(
        client: client,
      ).fetchMentor(accessToken: token, mentorId: 5),
    );
    contract(
      'createMentor',
      method: 'POST',
      path: '/api/admin/mentors',
      jsonBody: mentorCreate.toJson(),
      invoke: (client) => AdminMentorApi(
        client: client,
      ).createMentor(accessToken: token, request: mentorCreate),
    );
    contract(
      'updateMentor',
      method: 'PUT',
      path: '/api/admin/mentors/5',
      jsonBody: mentorUpdate.toJson(),
      invoke: (client) => AdminMentorApi(
        client: client,
      ).updateMentor(accessToken: token, mentorId: 5, request: mentorUpdate),
    );
    contract(
      'deactivateMentor',
      method: 'POST',
      path: '/api/admin/mentors/5/deactivate',
      invoke: (client) => AdminMentorApi(
        client: client,
      ).deactivateMentor(accessToken: token, mentorId: 5),
    );
    contract(
      'resetMentorPin',
      method: 'POST',
      path: '/api/admin/mentors/5/reset-pin',
      jsonBody: resetPin.toJson(),
      invoke: (client) => AdminMentorApi(
        client: client,
      ).resetMentorPin(accessToken: token, mentorId: 5, request: resetPin),
    );
    contract(
      'fetchMyProfile',
      method: 'GET',
      path: '/api/mentor/me',
      invoke: (client) =>
          MentorProfileApi(client: client).fetchMyProfile(accessToken: token),
    );
    contract(
      'updateMyProfile',
      method: 'PUT',
      path: '/api/mentor/me',
      jsonBody: profileUpdate.toJson(),
      invoke: (client) => MentorProfileApi(
        client: client,
      ).updateMyProfile(accessToken: token, request: profileUpdate),
    );
    contract(
      'changePin',
      method: 'PUT',
      path: '/api/mentor/me/pin',
      jsonBody: pinChange.toJson(),
      invoke: (client) => MentorProfileApi(
        client: client,
      ).changePin(accessToken: token, request: pinChange),
    );
  });

  group('sessions and reports', () {
    contract(
      'fetchAvailableSessionLogs',
      method: 'GET',
      path: '/api/mentor/session-logs',
      invoke: (client) => MentorSessionLogApi(
        client: client,
      ).fetchAvailableSessionLogs(accessToken: token),
    );
    contract(
      'submitSessionLog',
      method: 'POST',
      path: '/api/mentor/session-logs',
      jsonBody: sessionCreate.toJson(),
      invoke: (client) => MentorSessionLogApi(
        client: client,
      ).submitSessionLog(accessToken: token, request: sessionCreate),
    );
    contract(
      'fetchSessionLogs',
      method: 'GET',
      path: '/api/admin/session-logs',
      invoke: (client) => AdminSessionLogApi(
        client: client,
      ).fetchSessionLogs(accessToken: token),
    );
    contract(
      'fetchSessionPhotos',
      method: 'GET',
      path: '/api/shared/session-logs/11/photos',
      invoke: (client) => SharedSessionPhotoApi(
        client: client,
      ).fetchSessionPhotos(accessToken: token, sessionLogId: 11),
    );
    contract(
      'fetchCoursePhotos',
      method: 'GET',
      path: '/api/shared/courses/8/photos',
      invoke: (client) => SharedSessionPhotoApi(
        client: client,
      ).fetchCoursePhotos(accessToken: token, courseId: 8),
    );
    contract(
      'fetchReports',
      method: 'GET',
      path: '/api/admin/course-visit-reports',
      invoke: (client) =>
          AdminCourseVisitApi(client: client).fetchReports(accessToken: token),
    );
    contract(
      'submitReport',
      method: 'POST',
      path: '/api/admin/course-visit-reports',
      jsonBody: visitCreate.toJson(),
      invoke: (client) => AdminCourseVisitApi(
        client: client,
      ).submitReport(accessToken: token, request: visitCreate),
    );
  });

  group('stories', () {
    contract(
      'fetch mentor stories',
      method: 'GET',
      path: '/api/mentor/stories',
      query: {'month': '2026-07-01'},
      invoke: (client) => MentorStoryApi(
        client: client,
      ).fetchStories(accessToken: token, month: DateTime(2026, 7)),
    );
    contract(
      'rateStory',
      method: 'PUT',
      path: '/api/mentor/stories/12/rating',
      jsonBody: const StoryRatingRequest(rating: 4).toJson(),
      invoke: (client) => MentorStoryApi(client: client).rateStory(
        accessToken: token,
        storyId: 12,
        request: const StoryRatingRequest(rating: 4),
      ),
    );
    contract(
      'fetch admin stories',
      method: 'GET',
      path: '/api/admin/stories',
      query: {'active_only': 'false', 'month': '2026-07-01'},
      invoke: (client) => AdminStoryApi(client: client).fetchStories(
        accessToken: token,
        month: DateTime(2026, 7),
        activeOnly: false,
      ),
    );
    contract(
      'updateStory',
      method: 'PUT',
      path: '/api/admin/stories/12',
      jsonBody: const StoryUpdateRequest(text: 'Edited').toJson(),
      invoke: (client) => AdminStoryApi(client: client).updateStory(
        accessToken: token,
        storyId: 12,
        request: const StoryUpdateRequest(text: 'Edited'),
      ),
    );
    contract(
      'deactivateStory',
      method: 'POST',
      path: '/api/admin/stories/12/deactivate',
      invoke: (client) => AdminStoryApi(
        client: client,
      ).deactivateStory(accessToken: token, storyId: 12),
    );
    contract(
      'activateStory',
      method: 'POST',
      path: '/api/admin/stories/12/activate',
      invoke: (client) => AdminStoryApi(
        client: client,
      ).activateStory(accessToken: token, storyId: 12),
    );
    contract(
      'selectWinner',
      method: 'PUT',
      path: '/api/admin/story-winners/2026-07-01',
      jsonBody: const StoryWinnerRequest(storyId: 12).toJson(),
      invoke: (client) => AdminStoryApi(client: client).selectWinner(
        accessToken: token,
        month: DateTime(2026, 7),
        request: const StoryWinnerRequest(storyId: 12),
      ),
    );
    contract(
      'fetchWinnerArchive',
      method: 'GET',
      path: '/api/shared/story-winners',
      invoke: (client) =>
          SharedStoryApi(client: client).fetchWinnerArchive(accessToken: token),
    );
  });

  group('uploads and external data', () {
    test('submitStory multipart contract', () async {
      final directory = await Directory.systemTemp.createTemp('story-api-');
      final file = File('${directory.path}/photo.jpg');
      await file.writeAsBytes([1, 2, 3]);
      final client = RecordingClient();
      try {
        await MentorStoryApi(client: client).submitStory(
          accessToken: token,
          request: StoryCreateRequest(
            courseId: 9,
            text: 'Story',
            photoPath: file.path,
          ),
        );
        final captured = client.request as http.MultipartRequest;
        expect(captured.method, 'POST');
        expect(captured.url.path, '/api/mentor/stories');
        expect(captured.headers['Authorization'], 'Bearer $token');
        expect(captured.fields, {'course_id': '9', 'text': 'Story'});
        expect(captured.files.single.field, 'photo');
      } finally {
        await directory.delete(recursive: true);
      }
    });

    test('submitSessionPhotos multipart contract', () async {
      final directory = await Directory.systemTemp.createTemp('photos-api-');
      final files = <File>[];
      for (var index = 0; index < 3; index++) {
        final file = File('${directory.path}/$index.jpg');
        await file.writeAsBytes([index]);
        files.add(file);
      }
      final client = RecordingClient();
      try {
        await MentorSessionPhotoApi(client: client).submitSessionPhotos(
          accessToken: token,
          sessionLogId: 11,
          photoPaths: files.map((file) => file.path).toList(),
        );
        final captured = client.request as http.MultipartRequest;
        expect(captured.method, 'POST');
        expect(captured.url.path, '/api/mentor/session-logs/11/photos');
        expect(captured.headers['Authorization'], 'Bearer $token');
        expect(captured.files, hasLength(3));
        expect(captured.files.map((file) => file.field), everyElement('files'));
      } finally {
        await directory.delete(recursive: true);
      }
    });

    contract(
      'fetchCatalog',
      method: 'GET',
      path: '/data/curriculum.json',
      origin: 'https://curriculum.afterschool-geekery.org',
      authenticated: false,
      invoke: (client) => CurriculumApi(client: client).fetchCatalog(),
    );
  });
}
