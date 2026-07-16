import 'package:flutter/foundation.dart';

enum AdminScreen {
  menu,
  manageMentors,
  manageCourses,
  manageStudents,
  viewSessionLogs,
  viewPhotos,
  trackStudents,
  reportsData,
}

class AdminMenuItem {
  final AdminScreen screen;
  final String label;

  const AdminMenuItem({required this.screen, required this.label});
}

class AdminAreaController extends ChangeNotifier {
  AdminScreen _screen = AdminScreen.menu;

  AdminScreen get screen => _screen;

  List<AdminMenuItem> get menuItems => const [
    AdminMenuItem(screen: AdminScreen.manageMentors, label: 'Manage mentors'),
    AdminMenuItem(screen: AdminScreen.manageCourses, label: 'Manage courses'),
    AdminMenuItem(screen: AdminScreen.manageStudents, label: 'Manage students'),
    AdminMenuItem(
      screen: AdminScreen.viewSessionLogs,
      label: 'View session logs',
    ),
    AdminMenuItem(screen: AdminScreen.viewPhotos, label: 'View photos'),
    AdminMenuItem(screen: AdminScreen.trackStudents, label: 'Track students'),
    AdminMenuItem(screen: AdminScreen.reportsData, label: 'Reports & data'),
  ];

  void select(AdminScreen screen) {
    if (_screen == screen) {
      return;
    }

    _screen = screen;
    notifyListeners();
  }

  void reset() {
    select(AdminScreen.menu);
  }
}
