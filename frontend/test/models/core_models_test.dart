import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/models.dart';

void main() {
  group('Course models', () {
    const json = <String, dynamic>{
      'id': 8,
      'name': 'Robotics',
      'description': 'Build robots',
      'country_id': 2,
      'day_of_week': 6,
      'start_time': '09:30',
      'active': true,
      'mentor_ids': [3, 5],
      'student_ids': [7, 9],
    };

    test('Course parses every response field', () {
      final course = Course.fromJson(json);

      expect(course.id, 8);
      expect(course.name, 'Robotics');
      expect(course.description, 'Build robots');
      expect(course.countryId, 2);
      expect(course.dayOfWeek, 6);
      expect(course.startTime, '09:30');
      expect(course.active, isTrue);
      expect(course.mentorIds, [3, 5]);
      expect(course.studentIds, [7, 9]);
    });

    test('CourseCreateRequest preserves defaults and literal keys', () {
      const request = CourseCreateRequest(
        name: 'Robotics',
        countryId: 2,
        dayOfWeek: 6,
        startTime: '09:30',
      );

      expect(request.toJson(), {
        'name': 'Robotics',
        'description': '',
        'country_id': 2,
        'day_of_week': 6,
        'start_time': '09:30',
        'active': true,
        'mentor_ids': <int>[],
        'student_ids': <int>[],
      });
    });

    test('CourseUpdateRequest copies a course and preserves literal keys', () {
      final course = Course.fromJson(json);
      final request = CourseUpdateRequest.fromCourse(course);

      expect(request.toJson(), {
        'name': 'Robotics',
        'description': 'Build robots',
        'country_id': 2,
        'day_of_week': 6,
        'start_time': '09:30',
        'active': true,
        'mentor_ids': [3, 5],
        'student_ids': [7, 9],
      });
    });
  });

  group('Student models', () {
    const json = <String, dynamic>{
      'id': 7,
      'first_name': 'Ada',
      'last_name': 'Lovelace',
      'origin_country_id': null,
      'birth_year': null,
      'gender': null,
      'active': true,
      'course_ids': [8],
    };

    test('Student parses nullable demographics and derives full name', () {
      final student = Student.fromJson(json);

      expect(student.id, 7);
      expect(student.fullName, 'Ada Lovelace');
      expect(student.originCountryId, isNull);
      expect(student.birthYear, isNull);
      expect(student.gender, isNull);
      expect(student.active, isTrue);
      expect(student.courseIds, [8]);
    });

    test('admin create request includes active and nullable keys', () {
      const request = StudentCreateRequest(
        firstName: 'Ada',
        lastName: 'Lovelace',
      );

      expect(request.toJson(), {
        'first_name': 'Ada',
        'last_name': 'Lovelace',
        'origin_country_id': null,
        'birth_year': null,
        'gender': null,
        'active': true,
        'course_ids': <int>[],
      });
    });

    test('admin update constructor copies all student fields', () {
      final request = StudentUpdateRequest.fromStudent(Student.fromJson(json));

      expect(request.toJson(), {
        'first_name': 'Ada',
        'last_name': 'Lovelace',
        'origin_country_id': null,
        'birth_year': null,
        'gender': null,
        'active': true,
        'course_ids': [8],
      });
    });

    test('mentor create request deliberately omits active', () {
      const request = MentorStudentCreateRequest(
        firstName: 'Ada',
        lastName: 'Lovelace',
        courseIds: [8],
      );

      expect(request.toJson(), {
        'first_name': 'Ada',
        'last_name': 'Lovelace',
        'origin_country_id': null,
        'birth_year': null,
        'gender': null,
        'course_ids': [8],
      });
      expect(request.toJson(), isNot(contains('active')));
    });

    test('mentor update constructor deliberately omits active', () {
      final request = MentorStudentUpdateRequest.fromStudent(
        Student.fromJson(json),
      );

      expect(request.toJson(), {
        'first_name': 'Ada',
        'last_name': 'Lovelace',
        'origin_country_id': null,
        'birth_year': null,
        'gender': null,
        'course_ids': [8],
      });
      expect(request.toJson(), isNot(contains('active')));
    });
  });

  group('Mentor models', () {
    const json = <String, dynamic>{
      'id': 5,
      'account_id': 15,
      'first_name': 'Grace',
      'last_name': 'Hopper',
      'phone': '256700000001',
      'country_id': null,
      'preferred_language': 'en',
      'active': true,
      'course_ids': [8],
    };

    test('Mentor parses every field and derives full name', () {
      final mentor = Mentor.fromJson(json);

      expect(mentor.id, 5);
      expect(mentor.accountId, 15);
      expect(mentor.fullName, 'Grace Hopper');
      expect(mentor.phone, '256700000001');
      expect(mentor.countryId, isNull);
      expect(mentor.preferredLanguage, 'en');
      expect(mentor.active, isTrue);
      expect(mentor.courseIds, [8]);
    });

    test('create request preserves defaults and temporary PIN key', () {
      const request = MentorCreateRequest(
        firstName: 'Grace',
        lastName: 'Hopper',
        phone: '256700000001',
        temporaryPin: '1234',
      );

      expect(request.toJson(), {
        'first_name': 'Grace',
        'last_name': 'Hopper',
        'phone': '256700000001',
        'country_id': null,
        'preferred_language': 'en',
        'temporary_pin': '1234',
        'active': true,
        'course_ids': <int>[],
      });
    });

    test('admin update constructor copies all editable fields', () {
      final request = MentorUpdateRequest.fromMentor(Mentor.fromJson(json));

      expect(request.toJson(), {
        'first_name': 'Grace',
        'last_name': 'Hopper',
        'phone': '256700000001',
        'country_id': null,
        'preferred_language': 'en',
        'active': true,
        'course_ids': [8],
      });
    });

    test('self update exposes only self-editable fields', () {
      final request = MentorSelfUpdateRequest.fromMentor(Mentor.fromJson(json));

      expect(request.toJson(), {
        'first_name': 'Grace',
        'last_name': 'Hopper',
        'phone': '256700000001',
      });
    });

    test('PIN requests preserve their distinct literal keys', () {
      expect(const MentorResetPinRequest(temporaryPin: '9876').toJson(), {
        'temporary_pin': '9876',
      });
      expect(
        const MentorChangePinRequest(
          currentPin: '1234',
          newPin: '5678',
        ).toJson(),
        {'current_pin': '1234', 'new_pin': '5678'},
      );
    });
  });

  test('SharedMentor parses course context and availability', () {
    final mentor = SharedMentor.fromJson({
      'id': 5,
      'first_name': 'Grace',
      'last_name': 'Hopper',
      'active': true,
      'assigned_to_course': false,
    });

    expect(mentor.fullName, 'Grace Hopper');
    expect(mentor.active, isTrue);
    expect(mentor.assignedToCourse, isFalse);
    expect(mentor.availableForSession, isFalse);
  });
}
