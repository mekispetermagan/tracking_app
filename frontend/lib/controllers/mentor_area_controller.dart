import 'package:flutter/foundation.dart';

enum MentorScreen {
  menu,
  myProfile,
  manageCourses,
  manageStudents,
  submitSessionLog,
  viewSessionLogs,
  viewPhotos,
  trackStudents,
  submitInvoice,
  stories,
  submitStory,
  storyWinnerArchive,
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
    MentorMenuItem(
      screen: MentorScreen.submitSessionLog,
      label: 'Log a session',
    ),
    MentorMenuItem(
      screen: MentorScreen.viewSessionLogs,
      label: 'View session logs',
    ),
    MentorMenuItem(screen: MentorScreen.trackStudents, label: 'Track students'),
    MentorMenuItem(screen: MentorScreen.viewPhotos, label: 'View photos'),
    MentorMenuItem(screen: MentorScreen.stories, label: 'Stories'),
    MentorMenuItem(screen: MentorScreen.submitInvoice, label: 'Submit invoice'),
  ];

  void select(MentorScreen screen) {
    if (_screen == screen) {
      return;
    }

    _screen = screen;
    notifyListeners();
  }

  void openStoryForm() {
    select(MentorScreen.submitStory);
  }

  void closeStoryForm() {
    select(MentorScreen.stories);
  }

  void openStoryWinnerArchive() {
    select(MentorScreen.storyWinnerArchive);
  }

  void closeStoryWinnerArchive() {
    select(MentorScreen.stories);
  }

  void reset() {
    select(MentorScreen.menu);
  }
}
