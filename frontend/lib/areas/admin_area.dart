import 'package:flutter/material.dart';

import '../controllers/controllers.dart';
import '../models/models.dart';
import '../screens/screens.dart';

class AdminArea extends StatefulWidget {
  const AdminArea({
    required this.accessToken,
    required this.onLogout,
    super.key,
  });

  final String accessToken;
  final Future<void> Function() onLogout;

  @override
  State<AdminArea> createState() => _AdminAreaState();
}

class _AdminAreaState extends State<AdminArea> {
  final _areaController = AdminAreaController();
  final _mentorManagementController = AdminMentorManagementController();
  final _courseManagementController = AdminCourseManagementController();
  final _studentManagementController = AdminStudentManagementController();
  final _viewSessionLogsController = AdminViewSessionLogsController();

  @override
  void dispose() {
    _areaController.dispose();
    _mentorManagementController.dispose();
    _courseManagementController.dispose();
    _studentManagementController.dispose();
    _viewSessionLogsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        _areaController,
        _mentorManagementController,
        _courseManagementController,
        _studentManagementController,
        _viewSessionLogsController,
      ]),
      builder: (_, _) => _buildArea(),
    );
  }

  Widget _buildArea() {
    return PopScope(
      canPop: _areaController.screen == AdminScreen.menu,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          return;
        }

        if (_areaController.screen == AdminScreen.manageMentors &&
            _mentorManagementController.view ==
                AdminMentorManagementView.form) {
          _mentorManagementController.cancelTaskScreen();
          return;
        }

        if (_areaController.screen == AdminScreen.manageCourses &&
            _courseManagementController.view !=
                AdminCourseManagementView.list) {
          _courseManagementController.cancelTaskScreen();
          return;
        }

        if (_areaController.screen == AdminScreen.manageStudents &&
            _studentManagementController.view !=
                AdminStudentManagementView.list) {
          _studentManagementController.cancelTaskScreen();
          return;
        }

        if (_areaController.screen == AdminScreen.viewSessionLogs &&
            _viewSessionLogsController.view == AdminSessionLogView.detail) {
          _viewSessionLogsController.closeDetail();
          return;
        }

        if (_areaController.screen != AdminScreen.menu) {
          _returnToMenu();
        }
      },
      child: switch (_areaController.screen) {
        AdminScreen.menu => AdminMenuScreen(
          items: _areaController.menuItems,
          onSelect: _selectScreen,
          onLogout: widget.onLogout,
        ),

        AdminScreen.manageMentors => _buildMentorManagementArea(),

        AdminScreen.manageCourses => _buildCourseManagementArea(),

        AdminScreen.manageStudents => _buildStudentManagementArea(),

        AdminScreen.viewSessionLogs => _buildViewSessionLogsArea(),

        AdminScreen.trackStudents => PlaceholderTaskScreen(
          title: 'Track students',
          onHome: _returnToMenu,
          onLogout: widget.onLogout,
        ),

        AdminScreen.reportsData => PlaceholderTaskScreen(
          title: 'Reports & data',
          onHome: _returnToMenu,
          onLogout: widget.onLogout,
        ),
      },
    );
  }

  Widget _buildMentorManagementArea() {
    return switch (_mentorManagementController.view) {
      AdminMentorManagementView.list => AdminMentorManagementScreen(
        mentors: _mentorManagementController.visibleMentors,
        statusFilter: _mentorManagementController.statusFilter,
        selectedMentorId: _mentorManagementController.selectedMentorId,
        canEdit: _mentorManagementController.canEdit,
        isLoading: _mentorManagementController.isLoading,
        isSaving: _mentorManagementController.isSaving,
        message: _mentorManagementController.message,
        clearMessage: _mentorManagementController.clearMessage,
        onStatusFilterChanged: _setMentorStatusFilter,
        onSelectMentor: _mentorManagementController.selectMentor,
        onAdd: _mentorManagementController.startAddMentor,
        onEdit: _mentorManagementController.startEditSelectedMentor,
        onResetPin: _mentorManagementController.startResetPin,
        onHome: _returnToMenu,
        onLogout: widget.onLogout,
      ),

      AdminMentorManagementView.form => AdminMentorFormScreen(
        mentor: _mentorManagementController.formMentor,
        isSaving: _mentorManagementController.isSaving,
        message: _mentorManagementController.message,
        clearMessage: _mentorManagementController.clearMessage,
        onCreate: _createMentor,
        onUpdate: _updateMentor,
        onCancel: _mentorManagementController.cancelTaskScreen,
      ),

      AdminMentorManagementView.resetPin => AdminMentorResetPinScreen(
        mentor: _mentorManagementController.selectedMentor,
        isSaving: _mentorManagementController.isSaving,
        message: _mentorManagementController.message,
        clearMessage: _mentorManagementController.clearMessage,
        onResetPin: _resetMentorPin,
        onCancel: _mentorManagementController.cancelTaskScreen,
      ),
    };
  }

  Widget _buildCourseManagementArea() {
    return switch (_courseManagementController.view) {
      AdminCourseManagementView.list => AdminCourseManagementScreen(
        courses: _courseManagementController.visibleCourses,
        statusFilter: _courseManagementController.statusFilter,
        selectedCourseId: _courseManagementController.selectedCourseId,
        canEdit: _courseManagementController.canEdit,
        canAssignMentors: _courseManagementController.canAssignMentors,
        isLoading: _courseManagementController.isLoading,
        isSaving: _courseManagementController.isSaving,
        message: _courseManagementController.message,
        clearMessage: _courseManagementController.clearMessage,
        onStatusFilterChanged: _setCourseStatusFilter,
        onSelectCourse: _courseManagementController.selectCourse,
        onAdd: _courseManagementController.startAddCourse,
        onEdit: _courseManagementController.startEditSelectedCourse,
        onAssignMentors: _startCourseMentorAssignment,
        onHome: _returnToMenu,
        onLogout: widget.onLogout,
      ),

      AdminCourseManagementView.form => AdminCourseFormScreen(
        course: _courseManagementController.formCourse,
        isSaving: _courseManagementController.isSaving,
        message: _courseManagementController.message,
        clearMessage: _courseManagementController.clearMessage,
        onCreate: _createCourse,
        onUpdate: _updateCourse,
        onCancel: _courseManagementController.cancelTaskScreen,
      ),

      AdminCourseManagementView.assignMentors =>
        AdminCourseMentorAssignmentScreen(
          course: _courseManagementController.selectedCourse,
          mentors: _courseManagementController.visibleMentors,
          assignedMentorIds: _courseManagementController.assignedMentorIds,
          statusFilter: _courseManagementController.mentorStatusFilter,
          isLoading: _courseManagementController.isLoading,
          isSaving: _courseManagementController.isSaving,
          message: _courseManagementController.message,
          clearMessage: _courseManagementController.clearMessage,
          onStatusFilterChanged: _setCourseMentorStatusFilter,
          onAssignmentChanged: (mentorId, assigned) {
            _courseManagementController.setMentorAssigned(
              mentorId: mentorId,
              assigned: assigned,
            );
          },
          onSave: _saveCourseMentorAssignments,
          onCancel: _courseManagementController.cancelTaskScreen,
        ),
    };
  }

  Widget _buildStudentManagementArea() {
    return switch (_studentManagementController.view) {
      AdminStudentManagementView.list => AdminStudentManagementScreen(
        students: _studentManagementController.visibleStudents,
        courses: _studentManagementController.courses,
        statusFilter: _studentManagementController.statusFilter,
        courseIdFilter: _studentManagementController.courseIdFilter,
        unassignedOnly: _studentManagementController.unassignedOnly,
        selectedStudentId: _studentManagementController.selectedStudentId,
        canEdit: _studentManagementController.canEdit,
        canAssignCourses: _studentManagementController.canAssignCourses,
        isLoading: _studentManagementController.isLoading,
        isSaving: _studentManagementController.isSaving,
        message: _studentManagementController.message,
        clearMessage: _studentManagementController.clearMessage,
        onStatusFilterChanged: _studentManagementController.setStatusFilter,
        onCourseFilterChanged: _studentManagementController.setCourseIdFilter,
        onUnassignedFilter: _studentManagementController.setUnassignedFilter,
        onSelectStudent: _studentManagementController.selectStudent,
        onAdd: _studentManagementController.startAddStudent,
        onEdit: _studentManagementController.startEditSelectedStudent,
        onAssignCourses: _startStudentCourseAssignment,
        onHome: _returnToMenu,
        onLogout: widget.onLogout,
      ),

      AdminStudentManagementView.form => AdminStudentFormScreen(
        student: _studentManagementController.formStudent,
        isSaving: _studentManagementController.isSaving,
        message: _studentManagementController.message,
        clearMessage: _studentManagementController.clearMessage,
        onCreate: _createStudent,
        onUpdate: _updateStudent,
        onCancel: _studentManagementController.cancelTaskScreen,
      ),

      AdminStudentManagementView.assignCourses =>
        AdminStudentCourseAssignmentScreen(
          student: _studentManagementController.selectedStudent,
          courses: _studentManagementController.visibleCourses,
          assignedCourseIds: _studentManagementController.assignedCourseIds,
          statusFilter: _studentManagementController.courseStatusFilter,
          isLoading: _studentManagementController.isLoading,
          isSaving: _studentManagementController.isSaving,
          message: _studentManagementController.message,
          clearMessage: _studentManagementController.clearMessage,
          onStatusFilterChanged: _setStudentCourseStatusFilter,
          onAssignmentChanged: (courseId, assigned) {
            _studentManagementController.setCourseAssigned(
              courseId: courseId,
              assigned: assigned,
            );
          },
          onSave: _saveStudentCourseAssignments,
          onCancel: _studentManagementController.cancelTaskScreen,
        ),
    };
  }

  Widget _buildViewSessionLogsArea() {
    final selectedSessionLog = _viewSessionLogsController.selectedSessionLog;

    return switch (_viewSessionLogsController.view) {
      AdminSessionLogView.list => AdminViewSessionLogsScreen(
        sessionLogs: _viewSessionLogsController.visibleSessionLogs,
        courses: _viewSessionLogsController.filterCourses,
        mentors: _viewSessionLogsController.filterMentors,
        selectedSessionLogId: _viewSessionLogsController.selectedSessionLogId,
        courseIdFilter: _viewSessionLogsController.courseIdFilter,
        mentorIdFilter: _viewSessionLogsController.mentorIdFilter,
        projectTypeFilter: _viewSessionLogsController.projectTypeFilter,
        canView: _viewSessionLogsController.canView,
        isLoading: _viewSessionLogsController.isLoading,
        message: _viewSessionLogsController.message,
        courseNameFor: _viewSessionLogsController.courseNameFor,
        mentorNameFor: _viewSessionLogsController.mentorNameFor,
        clearMessage: _viewSessionLogsController.clearMessage,
        onCourseFilterChanged: _viewSessionLogsController.setCourseIdFilter,
        onMentorFilterChanged: _viewSessionLogsController.setMentorIdFilter,
        onProjectTypeFilterChanged:
            _viewSessionLogsController.setProjectTypeFilter,
        onClearFilters: _viewSessionLogsController.clearFilters,
        onSelectSessionLog: _viewSessionLogsController.selectSessionLog,
        onView: _viewSessionLogsController.openSelectedSessionLog,
        onHome: _returnToMenu,
        onLogout: widget.onLogout,
      ),

      AdminSessionLogView.detail => AdminViewSessionLogScreen(
        sessionLog: selectedSessionLog!,
        courseName: _viewSessionLogsController.courseNameFor(
          selectedSessionLog,
        ),
        mentorName: _viewSessionLogsController.mentorNameFor(
          selectedSessionLog,
        ),
        studentNames: _viewSessionLogsController.studentNamesFor(
          selectedSessionLog,
        ),
        onBack: _viewSessionLogsController.closeDetail,
      ),
    };
  }

  Future<void> _selectScreen(AdminScreen screen) async {
    _areaController.select(screen);

    if (screen == AdminScreen.manageMentors) {
      await _mentorManagementController.openList(
        accessToken: widget.accessToken,
      );
    }

    if (screen == AdminScreen.manageCourses) {
      await _courseManagementController.openList(
        accessToken: widget.accessToken,
      );
    }

    if (screen == AdminScreen.manageStudents) {
      await _studentManagementController.openList(
        accessToken: widget.accessToken,
      );
    }

    if (screen == AdminScreen.viewSessionLogs) {
      await _viewSessionLogsController.openList(
        accessToken: widget.accessToken,
      );
    }
  }

  Future<void> _setMentorStatusFilter(MentorStatusFilter statusFilter) async {
    await _mentorManagementController.setStatusFilter(
      value: statusFilter,
      accessToken: widget.accessToken,
    );
  }

  Future<bool> _createMentor(MentorCreateRequest request) {
    return _mentorManagementController.createMentor(
      accessToken: widget.accessToken,
      request: request,
    );
  }

  Future<bool> _updateMentor(int mentorId, MentorUpdateRequest request) {
    return _mentorManagementController.updateMentor(
      accessToken: widget.accessToken,
      mentorId: mentorId,
      request: request,
    );
  }

  Future<bool> _resetMentorPin(MentorResetPinRequest request) {
    return _mentorManagementController.resetSelectedMentorPin(
      accessToken: widget.accessToken,
      request: request,
    );
  }

  Future<void> _setCourseStatusFilter(CourseStatusFilter statusFilter) async {
    await _courseManagementController.setStatusFilter(
      value: statusFilter,
      accessToken: widget.accessToken,
    );
  }

  Future<void> _startCourseMentorAssignment() async {
    await _courseManagementController.startAssignMentors(
      accessToken: widget.accessToken,
    );
  }

  Future<void> _setCourseMentorStatusFilter(
    CourseMentorStatusFilter statusFilter,
  ) async {
    await _courseManagementController.setMentorStatusFilter(
      value: statusFilter,
      accessToken: widget.accessToken,
    );
  }

  Future<bool> _createCourse(CourseCreateRequest request) {
    return _courseManagementController.createCourse(
      accessToken: widget.accessToken,
      request: request,
    );
  }

  Future<bool> _updateCourse(int courseId, CourseUpdateRequest request) {
    return _courseManagementController.updateCourse(
      accessToken: widget.accessToken,
      courseId: courseId,
      request: request,
    );
  }

  Future<bool> _saveCourseMentorAssignments() {
    return _courseManagementController.saveMentorAssignments(
      accessToken: widget.accessToken,
    );
  }

  Future<void> _startStudentCourseAssignment() async {
    await _studentManagementController.startAssignCourses(
      accessToken: widget.accessToken,
    );
  }

  Future<void> _setStudentCourseStatusFilter(
    StudentCourseStatusFilter statusFilter,
  ) async {
    await _studentManagementController.setCourseStatusFilter(
      value: statusFilter,
      accessToken: widget.accessToken,
    );
  }

  Future<bool> _createStudent(StudentCreateRequest request) {
    return _studentManagementController.createStudent(
      accessToken: widget.accessToken,
      request: request,
    );
  }

  Future<bool> _updateStudent(int studentId, StudentUpdateRequest request) {
    return _studentManagementController.updateStudent(
      accessToken: widget.accessToken,
      studentId: studentId,
      request: request,
    );
  }

  Future<bool> _saveStudentCourseAssignments() async {
    final success = await _studentManagementController.saveCourseAssignments(
      accessToken: widget.accessToken,
    );

    if (!success) {
      return false;
    }

    await _studentManagementController.loadCourses(
      accessToken: widget.accessToken,
    );

    return true;
  }

  void _returnToMenu() {
    _mentorManagementController.cancelTaskScreen();
    _courseManagementController.cancelTaskScreen();
    _studentManagementController.cancelTaskScreen();
    _viewSessionLogsController.reset();
    _areaController.reset();
  }
}
