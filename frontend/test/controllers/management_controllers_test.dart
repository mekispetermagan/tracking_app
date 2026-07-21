import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/api/api.dart';
import 'package:frontend/controllers/controllers.dart';
import 'package:frontend/models/models.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../support/core_fixtures.dart';

void main() {
  late MockClient client;
  setUp(() => client = MockClient(_backend));

  test(
    'admin mentor management loads, filters, navigates, and creates',
    () async {
      final controller = AdminMentorManagementController(
        api: AdminMentorApi(client: client),
      );
      await controller.openList(accessToken: 'token');
      expect(controller.mentors, hasLength(2));
      expect(controller.visibleMentors.single.id, 5);
      controller.setStatusFilter(ActiveStatusFilter.inactive);
      expect(controller.visibleMentors.single.id, 6);
      controller.selectMentor(6);
      controller.startEditSelectedMentor();
      expect(controller.view, AdminMentorManagementView.form);
      expect(controller.formMode, EntityFormMode.edit);
      controller.cancelTaskScreen();
      controller.startAddMentor();
      final created = await controller.createMentor(
        accessToken: 'token',
        request: const MentorCreateRequest(
          firstName: 'New',
          lastName: 'Mentor',
          phone: '0700000099',
          temporaryPin: '123456',
        ),
      );
      expect(created, isTrue);
      expect(controller.mentors.any((mentor) => mentor.id == 9), isTrue);
      expect(controller.selectedMentorId, isNull);
      expect(controller.view, AdminMentorManagementView.list);
    },
  );

  test('admin course management owns filters and mentor assignments', () async {
    final controller = AdminCourseManagementController(
      sharedCourseApi: SharedCourseApi(client: client),
      adminCourseApi: AdminCourseApi(client: client),
      adminMentorApi: AdminMentorApi(client: client),
    );
    await controller.openList(accessToken: 'token');
    expect(controller.visibleCourses.single.id, 8);
    controller.setStatusFilter(ActiveStatusFilter.inactive);
    expect(controller.visibleCourses.single.id, 9);
    controller.setStatusFilter(ActiveStatusFilter.all);
    controller.selectCourse(8);
    await controller.startAssignMentors(accessToken: 'token');
    expect(controller.assignedMentorIds, {5});
    controller.setMentorAssigned(mentorId: 6, assigned: true);
    expect(
      await controller.saveMentorAssignments(accessToken: 'token'),
      isTrue,
    );
    expect(controller.selectedCourse?.mentorIds, {5, 6});
  });

  test(
    'admin student management combines course and unassigned filters',
    () async {
      final controller = AdminStudentManagementController(
        studentApi: SharedStudentApi(client: client),
        courseApi: SharedCourseApi(client: client),
      );
      await controller.openList(accessToken: 'token');
      controller.setStatusFilter(ActiveStatusFilter.all);
      controller.setCourseIdFilter(8);
      expect(controller.visibleStudents.map((item) => item.id), [7]);
      controller.setUnassignedFilter();
      expect(controller.visibleStudents.map((item) => item.id), [9]);
      controller.selectStudent(9);
      await controller.startAssignCourses(accessToken: 'token');
      controller.setCourseAssigned(courseId: 8, assigned: true);
      expect(
        await controller.saveCourseAssignments(accessToken: 'token'),
        isTrue,
      );
      expect(
        controller.students.firstWhere((student) => student.id == 9).courseIds,
        [8],
      );
    },
  );

  test('mentor course management loads, edits, and updates', () async {
    final controller = MentorCourseManagementController(
      sharedCourseApi: SharedCourseApi(client: client),
    );
    await controller.openList(accessToken: 'token');
    controller.selectCourse(8);
    controller.startEditSelectedCourse();
    expect(controller.view, MentorCourseManagementView.form);
    final updated = await controller.updateCourse(
      accessToken: 'token',
      description: 'Updated',
      dayOfWeek: 2,
      startTime: '10:00',
    );
    expect(updated, isTrue);
    expect(controller.selectedCourse?.description, 'Updated');
  });

  test(
    'mentor student management filters and warns before unassignment',
    () async {
      final controller = MentorStudentManagementController(
        studentApi: SharedStudentApi(client: client),
        courseApi: SharedCourseApi(client: client),
      );
      await controller.openList(accessToken: 'token');
      controller.setCourseIdFilter(8);
      expect(controller.visibleStudents.single.id, 7);
      controller.selectStudent(7);
      controller.startEditSelectedStudent();
      expect(controller.requiresUnassignmentWarning(const []), isTrue);
      expect(controller.view, MentorStudentManagementView.form);
      controller.cancelForm();
      expect(controller.view, MentorStudentManagementView.list);
    },
  );
}

Future<http.Response> _backend(http.Request request) async {
  final path = request.url.path;
  if (request.method == 'GET' && path == '/api/admin/mentors') {
    return _json([
      mentorJson(),
      mentorJson(id: 6, firstName: 'Inactive', active: false),
    ]);
  }
  if (request.method == 'GET' && path == '/api/shared/mentors') {
    return _json([
      mentorJson(),
      mentorJson(id: 6, firstName: 'Inactive', active: false),
    ]);
  }
  if (request.method == 'GET' && path == '/api/shared/courses') {
    return _json([
      courseJson(),
      courseJson(
        id: 9,
        name: 'Inactive',
        active: false,
        mentorIds: [],
        studentIds: [],
      ),
    ]);
  }
  if (request.method == 'GET' && path == '/api/shared/students') {
    return _json([
      studentJson(),
      studentJson(id: 9, firstName: 'Unassigned', active: false, courseIds: []),
    ]);
  }
  if (request.method == 'POST' && path == '/api/admin/mentors') {
    return _json(mentorJson(id: 9, firstName: 'New', courseIds: []));
  }
  if (request.method == 'PUT' && path == '/api/shared/courses/8') {
    final body = jsonDecode(request.body) as Map<String, dynamic>;
    return _json({
      ...courseJson(mentorIds: List<int>.from(body['mentor_ids'] as List)),
      'description': body['description'],
      'day_of_week': body['day_of_week'],
      'start_time': body['start_time'],
    });
  }
  if (request.method == 'PUT' && path == '/api/shared/students/9') {
    return _json(studentJson(id: 9, firstName: 'Unassigned', courseIds: [8]));
  }
  return http.Response(
    jsonEncode({'detail': 'Unhandled ${request.method} $path'}),
    500,
  );
}

http.Response _json(Object body, [int status = 200]) =>
    http.Response(jsonEncode(body), status);
