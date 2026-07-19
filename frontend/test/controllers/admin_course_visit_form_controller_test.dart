import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/controllers/admin_course_visit_form_controller.dart';
import 'package:frontend/models/models.dart';

void main() {
  group('AdminCourseVisitFormController', () {
    test('builds a normalized report request from the form state', () {
      final controller = _controller();
      addTearDown(controller.dispose);

      controller.whatHappenedController.text = '  Productive lesson  ';
      controller.mainStrengthController.text = '  Clear examples  ';
      controller.setMentorState(10, CourseVisitMentorState.teaching);
      controller.setMentorRating(10, 4);
      controller.setStudentPresent(20, true);
      controller.setStudentInterviewed(20, true);
      controller.setStudentEnjoyment(20, CourseVisitStudentEnjoyment.mixed);
      controller.setStudentLearning(20, CourseVisitStudentLearning.partly);
      controller.setStudentSafety(20, CourseVisitStudentSafety.unsure);
      controller.noteControllerFor(20).text = '  Wants more practice  ';
      controller.addAction();
      controller.setActionCategory(0, CourseVisitActionCategory.equipment);
      controller.actions.single.descriptionController.text =
          '  Replace cable  ';
      controller.actions.single.responsiblePersonController.text =
          '  Site lead  ';
      controller.setActionDate(
        controller.actions.single,
        DateTime(2026, 8, 1, 14),
      );

      final request = controller.buildRequest()!;

      expect(request.courseId, 1);
      expect(request.date, DateTime(2026, 7, 19));
      expect(request.whatHappened, 'Productive lesson');
      expect(request.mainStrength, 'Clear examples');
      expect(request.mainProblem, isNull);
      expect(request.mentors.single.mentorId, 10);
      expect(request.mentors.single.role, CourseVisitMentorRole.teaching);
      expect(request.mentors.single.performanceRating, 4);
      expect(request.students.single.interviewed, isTrue);
      expect(
        request.students.single.enjoyment,
        CourseVisitStudentEnjoyment.mixed,
      );
      expect(
        request.students.single.learning,
        CourseVisitStudentLearning.partly,
      );
      expect(
        request.students.single.feelsSafe,
        CourseVisitStudentSafety.unsure,
      );
      expect(request.students.single.note, 'Wants more practice');
      expect(
        request.actions.single.category,
        CourseVisitActionCategory.equipment,
      );
      expect(request.actions.single.description, 'Replace cable');
      expect(request.actions.single.responsiblePerson, 'Site lead');
      expect(request.actions.single.targetDate, DateTime(2026, 8, 1));
    });

    test('switching course clears participant state', () {
      final controller = _controller();
      addTearDown(controller.dispose);

      controller.setMentorState(10, CourseVisitMentorState.supporting);
      controller.setStudentPresent(20, true);
      controller.setStudentInterviewed(20, true);
      controller.noteControllerFor(20).text = 'Interview';

      controller.selectCourse(2);

      expect(controller.selectedCourseId, 2);
      expect(controller.mentorState(10), CourseVisitMentorState.absent);
      expect(controller.presentStudentCount, 0);
      expect(controller.isStudentInterviewed(20), isFalse);
      expect(controller.buildRequest()!.mentors, isEmpty);
      expect(controller.buildRequest()!.students, isEmpty);
    });

    test('not-held session suppresses inapplicable observation answers', () {
      final controller = _controller();
      addTearDown(controller.dispose);

      controller.setSessionFollowedPlan(CourseVisitAnswer.partly);
      controller.setLearnerEngagement(CourseVisitLearnerEngagement.few);
      controller.setEquipmentAdequate(CourseVisitAnswer.no);
      controller.setEnvironmentStatus(
        CourseVisitEnvironmentStatus.seriousConcern,
      );
      controller.setSessionStatus(CourseVisitSessionStatus.notHeld);

      final request = controller.buildRequest()!;

      expect(request.teachingTookPlace, CourseVisitAnswer.no);
      expect(request.sessionFollowedPlan, isNull);
      expect(request.learnerEngagement, isNull);
      expect(request.equipmentAdequate, isNull);
      expect(request.environmentStatus, isNull);
    });

    test('moving visit date clears action dates that are now invalid', () {
      final controller = _controller();
      addTearDown(controller.dispose);
      controller.addAction();
      final action = controller.actions.single;
      controller.setActionDate(action, DateTime(2026, 7, 25));

      controller.setDate(DateTime(2026, 7, 26));

      expect(action.targetDate, isNull);
    });
  });
}

AdminCourseVisitFormController _controller() {
  return AdminCourseVisitFormController(
    courses: const [
      Course(
        id: 1,
        name: 'Course one',
        description: '',
        countryId: 1,
        dayOfWeek: 1,
        startTime: '09:00',
        active: true,
        mentorIds: [10],
        studentIds: [20],
      ),
      Course(
        id: 2,
        name: 'Course two',
        description: '',
        countryId: 1,
        dayOfWeek: 2,
        startTime: '10:00',
        active: true,
        mentorIds: [],
        studentIds: [],
      ),
    ],
    mentors: const [
      Mentor(
        id: 10,
        accountId: 100,
        firstName: 'Ada',
        lastName: 'Mentor',
        phone: '',
        countryId: 1,
        preferredLanguage: 'en',
        active: true,
        courseIds: [1],
      ),
    ],
    students: const [
      Student(
        id: 20,
        firstName: 'Sam',
        lastName: 'Student',
        originCountryId: 1,
        birthYear: 2010,
        gender: null,
        active: true,
        courseIds: [1],
      ),
    ],
    selectedCourseId: 1,
    initialDate: DateTime(2026, 7, 19, 14),
  );
}
