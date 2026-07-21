import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/models.dart';

void main() {
  group('Curriculum models', () {
    test('catalog parses translated categories and chapters', () {
      final catalog = CurriculumCatalog.fromJson({
        'categories': [
          {
            'id': 'robotics',
            'titles': {'eng': 'Robotics', 'lug': 'Robotics Luganda'},
            'chapters': [
              {
                'slug': 'motors',
                'titles': {'eng': 'Motors'},
              },
            ],
          },
        ],
      });

      expect(catalog.categories, hasLength(1));
      expect(catalog.categories.single.slug, 'robotics');
      expect(catalog.categories.single.englishTitle, 'Robotics');
      expect(catalog.categories.single.titles['lug'], 'Robotics Luganda');
      expect(catalog.categories.single.chapters.single.slug, 'motors');
      expect(catalog.categories.single.chapters.single.englishTitle, 'Motors');
    });

    test('English titles fall back to slugs', () {
      final category = CurriculumCategory.fromJson({
        'id': 'robotics',
        'titles': <String, String>{},
        'chapters': <Object>[],
      });
      final chapter = CurriculumChapter.fromJson({
        'slug': 'motors',
        'titles': <String, String>{},
      });

      expect(category.englishTitle, 'robotics');
      expect(chapter.englishTitle, 'motors');
    });
  });

  group('Course visit enums', () {
    test('every enum maps every declared API value', () {
      for (final value in CourseVisitSessionStatus.values) {
        expect(CourseVisitSessionStatus.fromApiValue(value.apiValue), value);
      }
      for (final value in CourseVisitAnswer.values) {
        expect(CourseVisitAnswer.fromApiValue(value.apiValue), value);
      }
      for (final value in CourseVisitLearnerEngagement.values) {
        expect(
          CourseVisitLearnerEngagement.fromApiValue(value.apiValue),
          value,
        );
      }
      for (final value in CourseVisitEnvironmentStatus.values) {
        expect(
          CourseVisitEnvironmentStatus.fromApiValue(value.apiValue),
          value,
        );
      }
      for (final value in CourseVisitMentorRole.values) {
        expect(CourseVisitMentorRole.fromApiValue(value.apiValue), value);
      }
      for (final value in CourseVisitStudentEnjoyment.values) {
        expect(CourseVisitStudentEnjoyment.fromApiValue(value.apiValue), value);
      }
      for (final value in CourseVisitStudentLearning.values) {
        expect(CourseVisitStudentLearning.fromApiValue(value.apiValue), value);
      }
      for (final value in CourseVisitStudentSafety.values) {
        expect(CourseVisitStudentSafety.fromApiValue(value.apiValue), value);
      }
      for (final value in CourseVisitActionCategory.values) {
        expect(CourseVisitActionCategory.fromApiValue(value.apiValue), value);
      }
    });
  });

  group('Course visit nested models', () {
    test('mentor and student parse nullable observation fields', () {
      final mentor = CourseVisitMentor.fromJson({
        'mentor_id': 5,
        'role': null,
        'performance_rating': null,
      });
      final student = CourseVisitStudent.fromJson({
        'student_id': 7,
        'interviewed': false,
        'enjoyment': null,
        'learning': null,
        'feels_safe': null,
        'note': null,
      });

      expect(mentor.mentorId, 5);
      expect(mentor.role, isNull);
      expect(mentor.performanceRating, isNull);
      expect(student.studentId, 7);
      expect(student.interviewed, isFalse);
      expect(student.enjoyment, isNull);
      expect(student.learning, isNull);
      expect(student.feelsSafe, isNull);
      expect(student.note, isNull);
    });

    test('mentor and student serialize literal enum keys', () {
      expect(
        const CourseVisitMentor(
          mentorId: 5,
          role: CourseVisitMentorRole.teaching,
          performanceRating: 4,
        ).toJson(),
        {'mentor_id': 5, 'role': 'teaching', 'performance_rating': 4},
      );
      expect(
        const CourseVisitStudent(
          studentId: 7,
          interviewed: true,
          enjoyment: CourseVisitStudentEnjoyment.mixed,
          learning: CourseVisitStudentLearning.partly,
          feelsSafe: CourseVisitStudentSafety.unsure,
          note: 'Quiet today',
        ).toJson(),
        {
          'student_id': 7,
          'interviewed': true,
          'enjoyment': 'mixed',
          'learning': 'partly',
          'feels_safe': 'unsure',
          'note': 'Quiet today',
        },
      );
    });

    test('action request serializes category and date only', () {
      final request = CourseVisitActionCreateRequest(
        category: CourseVisitActionCategory.followUpVisit,
        description: 'Return next month',
        responsiblePerson: 'Admin',
        targetDate: DateTime(2026, 8, 5, 20),
      );

      expect(request.toJson(), {
        'category': 'follow_up_visit',
        'description': 'Return next month',
        'responsible_person': 'Admin',
        'target_date': '2026-08-05',
      });
    });

    test('action response parses nullable and timestamp fields', () {
      final action = CourseVisitAction.fromJson({
        'id': 20,
        'category': 'follow_up_visit',
        'description': 'Return next month',
        'responsible_person': null,
        'target_date': null,
        'completed': true,
        'completed_at': '2026-08-02T10:00:00Z',
      });

      expect(action.id, 20);
      expect(action.category, CourseVisitActionCategory.followUpVisit);
      expect(action.responsiblePerson, isNull);
      expect(action.targetDate, isNull);
      expect(action.completed, isTrue);
      expect(action.completedAt, DateTime.utc(2026, 8, 2, 10));
    });
  });

  group('Course visit report', () {
    final reportJson = <String, dynamic>{
      'id': 40,
      'submitted_by_admin_profile_id': 2,
      'course_id': 8,
      'date': '2026-07-20',
      'session_status': 'fully_held',
      'teaching_took_place': 'yes',
      'session_followed_plan': 'partly',
      'learner_engagement': 'most',
      'equipment_adequate': 'yes',
      'environment_status': 'safe_and_respectful',
      'what_happened': 'Observed a robotics session',
      'main_strength': 'Teamwork',
      'main_problem': null,
      'support_provided': 'Coaching',
      'course_health_rating': 4,
      'safeguarding_concern': false,
      'safeguarding_note': null,
      'mentors': [
        {'mentor_id': 5, 'role': 'teaching', 'performance_rating': 4},
      ],
      'students': [
        {
          'student_id': 7,
          'interviewed': true,
          'enjoyment': 'yes',
          'learning': 'clearly',
          'feels_safe': 'yes',
          'note': null,
        },
      ],
      'actions': [
        {
          'id': 20,
          'category': 'mentor_coaching',
          'description': 'Discuss pacing',
          'responsible_person': 'Admin',
          'target_date': '2026-08-05',
          'completed': false,
          'completed_at': null,
        },
      ],
      'created_at': '2026-07-20T14:00:00Z',
      'updated_at': '2026-07-20T15:00:00Z',
    };

    test('response parses all scalar, enum, nullable, and nested fields', () {
      final report = CourseVisitReport.fromJson(reportJson);

      expect(report.id, 40);
      expect(report.submittedByAdminProfileId, 2);
      expect(report.courseId, 8);
      expect(report.date, DateTime(2026, 7, 20));
      expect(report.sessionStatus, CourseVisitSessionStatus.fullyHeld);
      expect(report.teachingTookPlace, CourseVisitAnswer.yes);
      expect(report.sessionFollowedPlan, CourseVisitAnswer.partly);
      expect(report.learnerEngagement, CourseVisitLearnerEngagement.most);
      expect(report.equipmentAdequate, CourseVisitAnswer.yes);
      expect(
        report.environmentStatus,
        CourseVisitEnvironmentStatus.safeAndRespectful,
      );
      expect(report.whatHappened, 'Observed a robotics session');
      expect(report.mainStrength, 'Teamwork');
      expect(report.mainProblem, isNull);
      expect(report.supportProvided, 'Coaching');
      expect(report.courseHealthRating, 4);
      expect(report.safeguardingConcern, isFalse);
      expect(report.safeguardingNote, isNull);
      expect(report.mentors.single.role, CourseVisitMentorRole.teaching);
      expect(
        report.students.single.learning,
        CourseVisitStudentLearning.clearly,
      );
      expect(
        report.actions.single.category,
        CourseVisitActionCategory.mentorCoaching,
      );
      expect(report.createdAt, DateTime.utc(2026, 7, 20, 14));
      expect(report.updatedAt, DateTime.utc(2026, 7, 20, 15));
    });

    test('create request emits complete literal nested wire map', () {
      final request = CourseVisitReportCreateRequest(
        courseId: 8,
        date: DateTime(2026, 7, 20, 18),
        sessionStatus: CourseVisitSessionStatus.fullyHeld,
        teachingTookPlace: CourseVisitAnswer.yes,
        sessionFollowedPlan: CourseVisitAnswer.partly,
        learnerEngagement: CourseVisitLearnerEngagement.most,
        equipmentAdequate: CourseVisitAnswer.yes,
        environmentStatus: CourseVisitEnvironmentStatus.safeAndRespectful,
        whatHappened: 'Observed a robotics session',
        mainStrength: 'Teamwork',
        mainProblem: null,
        supportProvided: 'Coaching',
        courseHealthRating: 4,
        safeguardingConcern: false,
        safeguardingNote: null,
        mentors: const [
          CourseVisitMentor(
            mentorId: 5,
            role: CourseVisitMentorRole.teaching,
            performanceRating: 4,
          ),
        ],
        students: const [
          CourseVisitStudent(
            studentId: 7,
            interviewed: true,
            enjoyment: CourseVisitStudentEnjoyment.yes,
            learning: CourseVisitStudentLearning.clearly,
            feelsSafe: CourseVisitStudentSafety.yes,
          ),
        ],
        actions: [
          CourseVisitActionCreateRequest(
            category: CourseVisitActionCategory.mentorCoaching,
            description: 'Discuss pacing',
            responsiblePerson: 'Admin',
            targetDate: DateTime(2026, 8, 5),
          ),
        ],
      );

      expect(request.toJson(), {
        'course_id': 8,
        'date': '2026-07-20',
        'session_status': 'fully_held',
        'teaching_took_place': 'yes',
        'session_followed_plan': 'partly',
        'learner_engagement': 'most',
        'equipment_adequate': 'yes',
        'environment_status': 'safe_and_respectful',
        'what_happened': 'Observed a robotics session',
        'main_strength': 'Teamwork',
        'main_problem': null,
        'support_provided': 'Coaching',
        'course_health_rating': 4,
        'safeguarding_concern': false,
        'safeguarding_note': null,
        'mentors': [
          {'mentor_id': 5, 'role': 'teaching', 'performance_rating': 4},
        ],
        'students': [
          {
            'student_id': 7,
            'interviewed': true,
            'enjoyment': 'yes',
            'learning': 'clearly',
            'feels_safe': 'yes',
            'note': null,
          },
        ],
        'actions': [
          {
            'category': 'mentor_coaching',
            'description': 'Discuss pacing',
            'responsible_person': 'Admin',
            'target_date': '2026-08-05',
          },
        ],
      });
    });

    test('not-held response accepts nullable observation fields', () {
      final report = CourseVisitReport.fromJson({
        ...reportJson,
        'session_status': 'not_held',
        'teaching_took_place': 'no',
        'session_followed_plan': null,
        'learner_engagement': null,
        'equipment_adequate': null,
        'environment_status': null,
      });

      expect(report.sessionStatus, CourseVisitSessionStatus.notHeld);
      expect(report.sessionFollowedPlan, isNull);
      expect(report.learnerEngagement, isNull);
      expect(report.equipmentAdequate, isNull);
      expect(report.environmentStatus, isNull);
    });
  });
}
