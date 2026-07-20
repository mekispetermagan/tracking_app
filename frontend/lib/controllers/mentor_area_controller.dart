import 'area_controller.dart';

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
  curriculum,
}

class MentorAreaController extends AreaController<MentorScreen> {
  MentorAreaController() : super(menuScreen: MentorScreen.menu);

  @override
  List<AreaMenuItem<MentorScreen>> get menuItems => const [
    AreaMenuItem(screen: MentorScreen.myProfile, label: 'My profile'),
    AreaMenuItem(screen: MentorScreen.manageCourses, label: 'Manage courses'),
    AreaMenuItem(screen: MentorScreen.manageStudents, label: 'Manage students'),
    AreaMenuItem(screen: MentorScreen.submitSessionLog, label: 'Log a session'),
    AreaMenuItem(
      screen: MentorScreen.viewSessionLogs,
      label: 'View session logs',
    ),
    AreaMenuItem(screen: MentorScreen.viewPhotos, label: 'View photos'),
    AreaMenuItem(screen: MentorScreen.trackStudents, label: 'Track students'),
    AreaMenuItem(screen: MentorScreen.stories, label: 'Stories'),
    AreaMenuItem(screen: MentorScreen.submitInvoice, label: 'Submit invoice'),
    AreaMenuItem(screen: MentorScreen.curriculum, label: 'Curriculum'),
  ];

  void openStoryForm() {
    publishIf(updateScreen(MentorScreen.submitStory));
  }

  void closeStoryForm() {
    publishIf(updateScreen(MentorScreen.stories));
  }

  void openStoryWinnerArchive() {
    publishIf(updateScreen(MentorScreen.storyWinnerArchive));
  }

  void closeStoryWinnerArchive() {
    publishIf(updateScreen(MentorScreen.stories));
  }
}
