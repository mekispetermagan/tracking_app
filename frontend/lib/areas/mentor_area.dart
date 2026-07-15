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
  final _studentController = MentorStudentManagementController();
  final _profileController = MentorProfileController();
  final _sessionLogController = MentorSessionLogController();
  final _viewSessionLogsController = MentorViewSessionLogsController();

  bool _showChangePin = false;

  @override
  void dispose() {
    _areaController.dispose();
    _courseController.dispose();
    _studentController.dispose();
    _profileController.dispose();
    _sessionLogController.dispose();
    _viewSessionLogsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        _areaController,
        _courseController,
        _studentController,
        _profileController,
        _sessionLogController,
        _viewSessionLogsController,
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

        if (_areaController.screen == MentorScreen.manageStudents &&
            _studentController.view == MentorStudentManagementView.form) {
          _studentController.cancelForm();
          return;
        }

        if (_areaController.screen == MentorScreen.viewSessionLogs &&
            _viewSessionLogsController.view ==
                MentorViewSessionLogsView.detail) {
          _viewSessionLogsController.closeDetail();
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

        MentorScreen.manageStudents => _buildStudentManagement(),

        MentorScreen.submitSessionLog => _buildSessionLogForm(),

        MentorScreen.viewSessionLogs => _buildViewSessionLogsArea(),

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

  Widget _buildStudentManagement() {
    return switch (_studentController.view) {
      MentorStudentManagementView.list => MentorStudentManagementScreen(
        students: _studentController.visibleStudents,
        courses: _studentController.courses,
        courseIdFilter: _studentController.courseIdFilter,
        selectedStudentId: _studentController.selectedStudentId,
        canEdit: _studentController.canEdit,
        isLoading: _studentController.isLoading,
        isSaving: _studentController.isSaving,
        message: _studentController.message,
        clearMessage: _studentController.clearMessage,
        onCourseFilterChanged: _studentController.setCourseIdFilter,
        onSelectStudent: _studentController.selectStudent,
        onAdd: _studentController.startAddStudent,
        onEdit: _studentController.startEditSelectedStudent,
        onHome: _goHome,
        onLogout: _logout,
      ),

      MentorStudentManagementView.form => MentorStudentFormScreen(
        student: _studentController.formStudent,
        courses: _studentController.courses,
        isSaving: _studentController.isSaving,
        message: _studentController.message,
        clearMessage: _studentController.clearMessage,
        onCreate: (request) {
          return _studentController.createStudent(
            accessToken: widget.accessToken,
            request: request,
          );
        },
        onUpdate: (studentId, request) {
          return _studentController.updateStudent(
            accessToken: widget.accessToken,
            studentId: studentId,
            request: request,
          );
        },
        onCancel: _studentController.cancelForm,
      ),
    };
  }

  Widget _buildSessionLogForm() {
    return MentorSessionLogFormScreen(
      courses: _sessionLogController.courses,
      students: _sessionLogController.students,
      selectedCourseId: _sessionLogController.selectedCourseId,
      selectedStudentIds: _sessionLogController.selectedStudentIds,
      isLoading: _sessionLogController.isLoading,
      isSaving: _sessionLogController.isSaving,
      message: _sessionLogController.message,
      clearMessage: _sessionLogController.clearMessage,
      onCourseSelected: (courseId) {
        return _sessionLogController.selectCourse(
          accessToken: widget.accessToken,
          courseId: courseId,
        );
      },
      onToggleStudent: _sessionLogController.toggleStudent,
      onSelectAllStudents: _sessionLogController.selectAllStudents,
      onClearStudents: _sessionLogController.clearStudentSelection,
      onSubmit: (request) {
        return _sessionLogController.submit(
          accessToken: widget.accessToken,
          request: request,
        );
      },
      onSubmitted: _finishSessionLogSubmission,
      onCancel: _goHome,
    );
  }

  Widget _buildViewSessionLogsArea() {
    final selectedSessionLog = _viewSessionLogsController.selectedSessionLog;

    return switch (_viewSessionLogsController.view) {
      MentorViewSessionLogsView.list => MentorViewSessionLogsScreen(
        sessionLogs: _viewSessionLogsController.visibleSessionLogs,
        courses: _viewSessionLogsController.filterCourses,
        selectedSessionLogId: _viewSessionLogsController.selectedSessionLogId,
        courseIdFilter: _viewSessionLogsController.courseIdFilter,
        projectTypeFilter: _viewSessionLogsController.projectTypeFilter,
        canView: _viewSessionLogsController.canView,
        isLoading: _viewSessionLogsController.isLoading,
        message: _viewSessionLogsController.message,
        courseNameFor: _viewSessionLogsController.courseNameFor,
        clearMessage: _viewSessionLogsController.clearMessage,
        onCourseFilterChanged: _viewSessionLogsController.setCourseIdFilter,
        onProjectTypeFilterChanged:
            _viewSessionLogsController.setProjectTypeFilter,
        onClearFilters: _viewSessionLogsController.clearFilters,
        onSelectSessionLog: _viewSessionLogsController.selectSessionLog,
        onView: _viewSessionLogsController.openSelectedSessionLog,
        onHome: _goHome,
        onLogout: _logout,
      ),

      MentorViewSessionLogsView.detail => MentorViewSessionLogScreen(
        sessionLog: selectedSessionLog!,
        courseName: _viewSessionLogsController.courseNameFor(
          selectedSessionLog,
        ),
        studentNames: _viewSessionLogsController.studentNamesFor(
          selectedSessionLog,
        ),
        onBack: _viewSessionLogsController.closeDetail,
      ),
    };
  }

  void _finishSessionLogSubmission() {
    _sessionLogController.reset();
    _areaController.reset();

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Session log submitted.')));
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

    if (screen == MentorScreen.manageStudents) {
      _studentController.openList(accessToken: widget.accessToken);
    }

    if (screen == MentorScreen.submitSessionLog) {
      _sessionLogController.initialize(accessToken: widget.accessToken);
    }

    if (screen == MentorScreen.viewSessionLogs) {
      _viewSessionLogsController.openList(accessToken: widget.accessToken);
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
    _studentController.reset();
    _sessionLogController.reset();
    _viewSessionLogsController.reset();
  }

  Future<void> _logout() async {
    setState(() {
      _showChangePin = false;
    });

    _profileController.reset();
    _courseController.reset();
    _areaController.reset();
    _studentController.reset();
    _sessionLogController.reset();
    _viewSessionLogsController.reset();

    await widget.onLogout();
  }
}
