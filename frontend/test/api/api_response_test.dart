import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/api/api.dart';
import 'package:frontend/models/models.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  const token = 'response-token';
  const courseJson = <String, dynamic>{
    'id': 8,
    'name': 'Robotics',
    'description': 'Build robots',
    'country_id': 2,
    'day_of_week': 6,
    'start_time': '09:30',
    'active': true,
    'mentor_ids': [3],
    'student_ids': [4],
  };

  test('auth success data is decoded and marked successful', () async {
    final client = MockClient(
      (_) async => http.Response(
        jsonEncode({
          'token_purpose': 'access',
          'mode': 'mentor',
          'access_token': 'access-token',
          'first_name': 'Test',
          'last_name': 'Mentor',
          'preferred_language': 'en',
        }),
        200,
      ),
    );

    final result = await AuthApi(
      client: client,
    ).mentorLogin(phone: '256700000000', pin: '1234');

    expect(result.isSuccess, isTrue);
    expect(result.isFailure, isFalse);
    expect(result.token, 'access-token');
    expect(result.tokenPurpose, AuthTokenPurpose.access);
    expect(result.mode, AuthMode.mentor);
  });

  test('model success data is decoded and marked successful', () async {
    final client = MockClient(
      (_) async => http.Response(jsonEncode(courseJson), 200),
    );

    final result = await SharedCourseApi(
      client: client,
    ).fetchCourse(accessToken: token, courseId: 8);

    expect(result.isSuccess, isTrue);
    expect(result.course?.id, 8);
    expect(result.course?.mentorIds, [3]);
  });

  group('common status mapping', () {
    const cases = <int, SharedCourseFailure>{
      400: SharedCourseFailure.badRequest,
      422: SharedCourseFailure.badRequest,
      401: SharedCourseFailure.unauthorized,
      403: SharedCourseFailure.forbidden,
      404: SharedCourseFailure.notFound,
      409: SharedCourseFailure.conflict,
      500: SharedCourseFailure.serverError,
    };

    for (final entry in cases.entries) {
      test('${entry.key} maps to ${entry.value.name}', () async {
        final client = MockClient(
          (_) async =>
              http.Response(jsonEncode({'detail': 'Server detail'}), entry.key),
        );

        final result = await SharedCourseApi(
          client: client,
        ).fetchCourse(accessToken: token, courseId: 8);

        expect(result.isFailure, isTrue);
        expect(result.failure, entry.value);
        expect(result.message, 'Server detail');
      });
    }
  });

  test('empty error response retains status classification', () async {
    final client = MockClient((_) async => http.Response('', 401));

    final result = await SharedCourseApi(
      client: client,
    ).fetchCourse(accessToken: token, courseId: 8);

    expect(result.failure, SharedCourseFailure.unauthorized);
    expect(result.message, isNull);
  });

  test('malformed success response is invalidData', () async {
    final client = MockClient((_) async => http.Response('{broken', 200));

    final result = await SharedCourseApi(
      client: client,
    ).fetchCourses(accessToken: token);

    expect(result.failure, SharedCourseFailure.invalidData);
  });

  test('structurally incompatible success response is invalidData', () async {
    final client = MockClient(
      (_) async => http.Response(jsonEncode({'unexpected': true}), 200),
    );

    final result = await SharedCourseApi(
      client: client,
    ).fetchCourse(accessToken: token, courseId: 8);

    expect(result.failure, SharedCourseFailure.invalidData);
  });

  test('client exception is networkError', () async {
    final client = MockClient((_) async => throw const SocketException('down'));

    final result = await SharedCourseApi(
      client: client,
    ).fetchCourse(accessToken: token, courseId: 8);

    expect(result.failure, SharedCourseFailure.networkError);
  });

  test('204 PIN response succeeds without JSON decoding', () async {
    final client = MockClient((_) async => http.Response('', 204));

    final result = await MentorProfileApi(client: client).changePin(
      accessToken: token,
      request: const MentorChangePinRequest(currentPin: '1234', newPin: '5678'),
    );

    expect(result.isSuccess, isTrue);
    expect(result.success, isTrue);
  });

  test('session upload rejects a non-three-photo request locally', () async {
    var sent = false;
    final client = MockClient((_) async {
      sent = true;
      return http.Response('{}', 500);
    });

    final result = await MentorSessionPhotoApi(client: client)
        .submitSessionPhotos(
          accessToken: token,
          sessionLogId: 11,
          photoPaths: const ['one.jpg', 'two.jpg'],
        );

    expect(sent, isFalse);
    expect(result.failure, MentorSessionPhotoFailure.badRequest);
  });
}
