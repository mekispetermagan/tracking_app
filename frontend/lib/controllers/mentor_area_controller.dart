import 'package:flutter/foundation.dart';

enum MentorScreen {
  menu,
  myProfile,
  manageCourses,
  manageStudents,
  sessionLog,
  uploadPhotos,
  submitInvoice,
  storyOfTheMonth,
}

class MentorMenuItem {
  final MentorScreen screen;
  final String label;

  const MentorMenuItem({required this.screen, required this.label});
}

class MentorAreaController extends ChangeNotifier {
  MentorScreen _screen = MentorScreen.menu;

  MentorScreen get screen => _screen;

  List<MentorMenuItem> get menuItems => const [
    MentorMenuItem(screen: MentorScreen.myProfile, label: 'My profile'),
    MentorMenuItem(screen: MentorScreen.manageCourses, label: 'Manage courses'),
    MentorMenuItem(
      screen: MentorScreen.manageStudents,
      label: 'Manage students',
    ),
    MentorMenuItem(screen: MentorScreen.sessionLog, label: 'Session log'),
    MentorMenuItem(screen: MentorScreen.uploadPhotos, label: 'Upload photos'),
    MentorMenuItem(screen: MentorScreen.submitInvoice, label: 'Submit invoice'),
    MentorMenuItem(
      screen: MentorScreen.storyOfTheMonth,
      label: 'Story of the month',
    ),
  ];

  void select(MentorScreen screen) {
    if (_screen == screen) {
      return;
    }

    _screen = screen;
    notifyListeners();
  }

  void reset() {
    select(MentorScreen.menu);
  }
}
