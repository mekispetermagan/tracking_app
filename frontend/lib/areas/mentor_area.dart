import 'package:flutter/material.dart';

import '../controllers/controllers.dart';
import '../screens/screens.dart';

class MentorArea extends StatefulWidget {
  const MentorArea({
    required this.accessToken,
    required this.onLogout,
    super.key,
  });

  final String accessToken;
  final Future<void> Function() onLogout;

  @override
  State<MentorArea> createState() => _MentorAreaState();
}

class _MentorAreaState extends State<MentorArea> {
  final _areaController = MentorAreaController();
  final _courseController = MentorCourseManagementController();

  @override
  void dispose() {
    _areaController.dispose();
    _courseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([_areaController, _courseController]),
      builder: (_, _) => _buildArea(),
    );
  }

  Widget _buildArea() {
    return PopScope(
      canPop: _areaController.screen == MentorScreen.menu,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          return;
        }

        if (_areaController.screen == MentorScreen.manageCourses &&
            _courseController.view == MentorCourseManagementView.form) {
          _courseController.cancelEdit();
          return;
        }

        _goHome();
      },
      child: switch (_areaController.screen) {
        MentorScreen.menu => MentorMenuScreen(
          items: _areaController.menuItems,
          onSelect: _selectScreen,
          onLogout: _logout,
        ),

        MentorScreen.myProfile => PlaceholderTaskScreen(
          title: 'My profile',
          onHome: _goHome,
          onLogout: _logout,
        ),

        MentorScreen.manageCourses => _buildCourseManagement(),

        MentorScreen.manageStudents => PlaceholderTaskScreen(
          title: 'Manage students',
          onHome: _goHome,
          onLogout: _logout,
        ),

        MentorScreen.sessionLog => PlaceholderTaskScreen(
          title: 'Session log',
          onHome: _goHome,
          onLogout: _logout,
        ),

        MentorScreen.uploadPhotos => PlaceholderTaskScreen(
          title: 'Upload photos',
          onHome: _goHome,
          onLogout: _logout,
        ),

        MentorScreen.submitInvoice => PlaceholderTaskScreen(
          title: 'Submit invoice',
          onHome: _goHome,
          onLogout: _logout,
        ),

        MentorScreen.storyOfTheMonth => PlaceholderTaskScreen(
          title: 'Story of the month',
          onHome: _goHome,
          onLogout: _logout,
        ),
      },
    );
  }

  Widget _buildCourseManagement() {
    return switch (_courseController.view) {
      MentorCourseManagementView.list => MentorCourseManagementScreen(
        courses: _courseController.courses,
        selectedCourseId: _courseController.selectedCourseId,
        canEdit: _courseController.canEdit,
        isLoading: _courseController.isLoading,
        isSaving: _courseController.isSaving,
        message: _courseController.message,
        clearMessage: _courseController.clearMessage,
        onSelectCourse: _courseController.selectCourse,
        onEdit: _courseController.startEditSelectedCourse,
        onHome: _goHome,
        onLogout: _logout,
      ),

      MentorCourseManagementView.form => MentorCourseFormScreen(
        course: _courseController.selectedCourse!,
        isSaving: _courseController.isSaving,
        message: _courseController.message,
        clearMessage: _courseController.clearMessage,
        onSave:
            ({required description, required dayOfWeek, required startTime}) {
              return _courseController.updateCourse(
                accessToken: widget.accessToken,
                description: description,
                dayOfWeek: dayOfWeek,
                startTime: startTime,
              );
            },
        onCancel: _courseController.cancelEdit,
      ),
    };
  }

  void _selectScreen(MentorScreen screen) {
    _areaController.select(screen);

    if (screen == MentorScreen.manageCourses) {
      _courseController.openList(accessToken: widget.accessToken);
    }
  }

  void _goHome() {
    _courseController.reset();
    _areaController.reset();
  }

  Future<void> _logout() async {
    _courseController.reset();
    _areaController.reset();
    await widget.onLogout();
  }
}
