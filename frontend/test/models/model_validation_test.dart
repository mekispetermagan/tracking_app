import 'package:flutter_test/flutter_test.dart';
import 'package:agu_frontend/models/models.dart';

void main() {
  test('unknown session enum values throw FormatException', () {
    expect(
      () => ProjectType.fromApiValue('future_type'),
      throwsFormatException,
    );
    expect(
      () => CompletionStatus.fromApiValue('future_status'),
      throwsFormatException,
    );
  });

  test('unknown course-visit enum values throw FormatException', () {
    expect(
      () => CourseVisitSessionStatus.fromApiValue('future_status'),
      throwsFormatException,
    );
    expect(
      () => CourseVisitActionCategory.fromApiValue('future_category'),
      throwsFormatException,
    );
  });

  test('invalid date strings throw FormatException', () {
    expect(
      () => SessionPhoto.fromJson({
        'id': 30,
        'session_log_id': 11,
        'mentor_profile_id': 5,
        'mentor_name': 'Grace Hopper',
        'session_date': 'not-a-date',
        'photo_number': 1,
        'url': '/photo.jpg',
        'uploaded_at': '2026-07-20T13:00:00Z',
      }),
      throwsFormatException,
    );
  });

  test('wrong scalar types throw TypeError', () {
    expect(
      () => Course.fromJson({
        'id': '8',
        'name': 'Robotics',
        'description': '',
        'country_id': 2,
        'day_of_week': 6,
        'start_time': '09:30',
        'active': true,
        'mentor_ids': <int>[],
        'student_ids': <int>[],
      }),
      throwsA(isA<TypeError>()),
    );
  });

  test('response factories copy JSON lists', () {
    final mentorIds = <int>[3];
    final json = <String, dynamic>{
      'id': 8,
      'name': 'Robotics',
      'description': '',
      'country_id': 2,
      'day_of_week': 6,
      'start_time': '09:30',
      'active': true,
      'mentor_ids': mentorIds,
      'student_ids': <int>[],
    };

    final course = Course.fromJson(json);
    mentorIds.add(5);

    expect(course.mentorIds, [3]);
  });

  test('conversion constructors copy entity lists', () {
    final mentorIds = <int>[3];
    final course = Course(
      id: 8,
      name: 'Robotics',
      description: '',
      countryId: 2,
      dayOfWeek: 6,
      startTime: '09:30',
      active: true,
      mentorIds: mentorIds,
      studentIds: const [],
    );

    final request = CourseUpdateRequest.fromCourse(course);
    mentorIds.add(5);

    expect(request.mentorIds, [3]);
  });
}
