import 'area_controller.dart';

enum AdminScreen {
  menu,
  manageMentors,
  manageCourses,
  manageStudents,
  viewSessionLogs,
  viewPhotos,
  trackStudents,
  stories,
  editStory,
  storyWinnerArchive,
  courseVisits,
  courseVisitForm,
  reportsData,
}

class AdminAreaController extends AreaController<AdminScreen> {
  AdminAreaController() : super(menuScreen: AdminScreen.menu);
  int? _selectedStoryId;

  int? get selectedStoryId => _selectedStoryId;

  @override
  List<AreaMenuItem<AdminScreen>> get menuItems => const [
    AreaMenuItem(screen: AdminScreen.manageMentors, label: 'Manage mentors'),
    AreaMenuItem(screen: AdminScreen.manageCourses, label: 'Manage courses'),
    AreaMenuItem(screen: AdminScreen.manageStudents, label: 'Manage students'),
    AreaMenuItem(
      screen: AdminScreen.viewSessionLogs,
      label: 'View session logs',
    ),
    AreaMenuItem(screen: AdminScreen.viewPhotos, label: 'View photos'),
    AreaMenuItem(screen: AdminScreen.trackStudents, label: 'Track students'),
    AreaMenuItem(screen: AdminScreen.stories, label: 'Stories'),
    AreaMenuItem(screen: AdminScreen.reportsData, label: 'Reports & data'),
    AreaMenuItem(screen: AdminScreen.courseVisits, label: 'Course visits'),
  ];

  void openStoryEdit(int storyId) {
    final storyChanged = _selectedStoryId != storyId;
    _selectedStoryId = storyId;
    final screenChanged = updateScreen(AdminScreen.editStory);
    publishIf(storyChanged || screenChanged);
  }

  void closeStoryEdit() {
    final transientStateChanged = clearTransientState();
    final screenChanged = updateScreen(AdminScreen.stories);
    publishIf(transientStateChanged || screenChanged);
  }

  void openStoryWinnerArchive() {
    publishIf(updateScreen(AdminScreen.storyWinnerArchive));
  }

  void closeStoryWinnerArchive() {
    publishIf(updateScreen(AdminScreen.stories));
  }

  void openCourseVisitForm() {
    publishIf(updateScreen(AdminScreen.courseVisitForm));
  }

  void closeCourseVisitForm() {
    publishIf(updateScreen(AdminScreen.courseVisits));
  }

  @override
  bool clearTransientState() {
    if (_selectedStoryId == null) {
      return false;
    }

    _selectedStoryId = null;
    return true;
  }
}
