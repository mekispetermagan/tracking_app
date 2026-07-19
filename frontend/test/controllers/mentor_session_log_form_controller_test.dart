import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/controllers/mentor_session_log_form_controller.dart';
import 'package:frontend/models/models.dart';

void main() {
  group('MentorSessionLogFormController', () {
    test('builds a normalized request with sorted selections', () {
      final controller = MentorSessionLogFormController(
        initialDate: DateTime(2026, 7, 19, 14),
      );
      addTearDown(controller.dispose);
      controller.projectTitleController.text = '  Reading project  ';
      controller.whatWorkedController.text = '  Good teamwork  ';
      controller.challengesController.text = '   ';
      controller.nextStepController.text = '  Add animation  ';
      controller.setCompletionStatus(CompletionStatus.partlyCompleted);
      controller.setGameSelected('Reading game', true);
      controller.setGameSelected('Mixed letters', true);

      final request = controller.buildRequest(
        courseId: 3,
        teachingMentorIds: {8, 2},
        supportingMentorIds: {7, 4},
        studentIds: {9, 1},
      )!;

      expect(request.courseId, 3);
      expect(request.date, DateTime(2026, 7, 19));
      expect(request.projectTitle, 'Reading project');
      expect(request.projectType, ProjectType.scratch);
      expect(request.otherProjectType, isNull);
      expect(request.gamesPlayed, 'Mixed letters, Reading game');
      expect(request.completionStatus, CompletionStatus.partlyCompleted);
      expect(request.whatWorked, 'Good teamwork');
      expect(request.challenges, isNull);
      expect(request.nextStep, 'Add animation');
      expect(request.teachingMentorIds, [2, 8]);
      expect(request.supportingMentorIds, [4, 7]);
      expect(request.studentIds, [1, 9]);
    });

    test('other project type is included only while other is selected', () {
      final controller = MentorSessionLogFormController();
      addTearDown(controller.dispose);
      controller.projectTitleController.text = 'Project';
      controller.setProjectType(ProjectType.other);
      controller.otherProjectTypeController.text = '  Electronics  ';

      final otherRequest = controller.buildRequest(
        courseId: 1,
        teachingMentorIds: {2},
        supportingMentorIds: {},
        studentIds: {3},
      )!;

      expect(otherRequest.otherProjectType, 'Electronics');

      controller.setProjectType(ProjectType.robotics);
      final roboticsRequest = controller.buildRequest(
        courseId: 1,
        teachingMentorIds: {2},
        supportingMentorIds: {},
        studentIds: {3},
      )!;

      expect(controller.otherProjectTypeController.text, isEmpty);
      expect(roboticsRequest.otherProjectType, isNull);
    });

    test('participant validation reports and clears both errors', () {
      final controller = MentorSessionLogFormController();
      addTearDown(controller.dispose);

      expect(
        controller.validateParticipants(teachingMentorIds: {}, studentIds: {}),
        isFalse,
      );
      expect(controller.mentorError, 'Select at least one teaching mentor.');
      expect(controller.attendanceError, 'Select at least one student.');

      controller.clearMentorError();
      controller.clearAttendanceError();

      expect(controller.mentorError, isNull);
      expect(controller.attendanceError, isNull);
    });

    test('date is normalized and unknown games are ignored', () {
      final controller = MentorSessionLogFormController();
      addTearDown(controller.dispose);
      controller.projectTitleController.text = 'Project';
      controller.setDate(DateTime(2026, 6, 5, 23, 30));
      controller.setGameSelected('Unknown game', true);

      final request = controller.buildRequest(
        courseId: 1,
        teachingMentorIds: {2},
        supportingMentorIds: {},
        studentIds: {3},
      )!;

      expect(request.date, DateTime(2026, 6, 5));
      expect(request.gamesPlayed, isNull);
    });
  });
}
