import 'package:flutter_test/flutter_test.dart';
import 'package:agu_frontend/controllers/admin_area_controller.dart';
import 'package:agu_frontend/controllers/mentor_area_controller.dart';

void main() {
  group('MentorAreaController', () {
    test('notifies only when navigation changes', () {
      final controller = MentorAreaController();
      var notifications = 0;
      controller.addListener(() => notifications++);

      controller.reset();
      controller.selectMenuItem(MentorScreen.viewPhotos);
      controller.selectMenuItem(MentorScreen.viewPhotos);
      controller.reset();

      expect(notifications, 2);
      expect(controller.screen, MentorScreen.menu);
    });

    test('rejects nested screens as menu selections', () {
      final controller = MentorAreaController();

      expect(
        () => controller.selectMenuItem(MentorScreen.submitStory),
        throwsArgumentError,
      );
    });
  });

  group('AdminAreaController', () {
    test('clears story selection when selecting another menu screen', () {
      final controller = AdminAreaController();
      var notifications = 0;
      controller.addListener(() => notifications++);

      controller.openStoryEdit(42);
      controller.selectMenuItem(AdminScreen.manageCourses);

      expect(controller.screen, AdminScreen.manageCourses);
      expect(controller.selectedStoryId, isNull);
      expect(notifications, 2);
    });

    test('story transitions notify only when state changes', () {
      final controller = AdminAreaController();
      var notifications = 0;
      controller.addListener(() => notifications++);

      controller.openStoryEdit(42);
      controller.openStoryEdit(42);
      controller.openStoryEdit(43);
      controller.closeStoryEdit();
      controller.closeStoryEdit();

      expect(notifications, 3);
      expect(controller.screen, AdminScreen.stories);
      expect(controller.selectedStoryId, isNull);
    });

    test('reset clears transient state without redundant notifications', () {
      final controller = AdminAreaController();
      var notifications = 0;
      controller.addListener(() => notifications++);

      controller.reset();
      controller.openStoryEdit(42);
      controller.reset();
      controller.reset();

      expect(notifications, 2);
      expect(controller.screen, AdminScreen.menu);
      expect(controller.selectedStoryId, isNull);
    });

    test('rejects nested screens as menu selections', () {
      final controller = AdminAreaController();

      expect(
        () => controller.selectMenuItem(AdminScreen.editStory),
        throwsArgumentError,
      );
    });
  });
}
