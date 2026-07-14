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
  final _profileController = MentorProfileController();

  bool _showChangePin = false;

  @override
  void dispose() {
    _areaController.dispose();
    _courseController.dispose();
    _profileController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        _areaController,
        _courseController,
        _profileController,
      ]),
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

        if (_areaController.screen == MentorScreen.myProfile &&
            _showChangePin) {
          setState(() {
            _showChangePin = false;
          });
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

        MentorScreen.myProfile => _buildProfile(),

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

  Widget _buildProfile() {
    if (_showChangePin) {
      return MentorChangePinScreen(
        isChangingPin: _profileController.isChangingPin,
        message: _profileController.message,
        clearMessage: _profileController.clearMessage,
        onChangePin: (request) {
          return _profileController.changePin(
            accessToken: widget.accessToken,
            request: request,
          );
        },
        onCancel: () {
          setState(() {
            _showChangePin = false;
          });
        },
      );
    }

    return MentorProfileScreen(
      mentor: _profileController.mentor,
      countryName: _profileCountryName,
      courseNames: _profileCourseNames,
      isLoading: _profileController.isLoading,
      isSaving: _profileController.isSaving,
      message: _profileController.message,
      clearMessage: _profileController.clearMessage,
      onSave: (request) {
        return _profileController.updateProfile(
          accessToken: widget.accessToken,
          request: request,
        );
      },
      onChangePin: () {
        setState(() {
          _showChangePin = true;
        });
      },
      onReload: _openProfile,
      onHome: _goHome,
      onLogout: _logout,
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

  String? get _profileCountryName {
    final countryId = _profileController.mentor?.countryId;

    if (countryId == null) {
      return null;
    }

    return 'ID $countryId';
  }

  List<String> get _profileCourseNames {
    final mentor = _profileController.mentor;

    if (mentor == null) {
      return const [];
    }

    final namesById = {
      for (final course in _courseController.courses) course.id: course.name,
    };

    return mentor.courseIds
        .map((courseId) => namesById[courseId] ?? 'Course #$courseId')
        .toList();
  }

  void _selectScreen(MentorScreen screen) {
    _areaController.select(screen);

    if (screen == MentorScreen.myProfile) {
      _openProfile();
    }

    if (screen == MentorScreen.manageCourses) {
      _courseController.openList(accessToken: widget.accessToken);
    }
  }

  void _openProfile() {
    _profileController.loadProfile(accessToken: widget.accessToken);
    _courseController.openList(accessToken: widget.accessToken);
  }

  void _goHome() {
    setState(() {
      _showChangePin = false;
    });

    _profileController.reset();
    _courseController.reset();
    _areaController.reset();
  }

  Future<void> _logout() async {
    setState(() {
      _showChangePin = false;
    });

    _profileController.reset();
    _courseController.reset();
    _areaController.reset();

    await widget.onLogout();
  }
}
