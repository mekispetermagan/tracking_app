import 'package:flutter/material.dart';

import 'controllers/controllers.dart';
import 'models/models.dart';
import 'screens/screens.dart';

void main() {
  runApp(const ProgressTrackingApp());
}

class ProgressTrackingApp extends StatelessWidget {
  const ProgressTrackingApp({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF3F7CAC),
      brightness: Brightness.light,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorScheme: scheme, useMaterial3: true),
      home: const AppRoot(),
    );
  }
}

class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  final _sessionController = SessionController();
  final _mentorLoginController = MentorLoginController();
  final _adminLoginController = AdminLoginController();
  final _mentorSetupPinController = MentorSetupPinController();
  final _adminSetupPasswordController = AdminSetupPasswordController();
  final _mentorAreaController = MentorAreaController();
  final _adminAreaController = AdminAreaController();
  final _adminMentorManagementController = AdminMentorManagementController();
  final _adminCourseManagementController = AdminCourseManagementController();
  final _adminStudentManagementController = AdminStudentManagementController();

  @override
  void initState() {
    super.initState();
    _sessionController.restoreSession();
    _mentorLoginController.loadLastPhone();
    _adminLoginController.loadLastPhone();
  }

  @override
  void dispose() {
    _sessionController.dispose();
    _mentorLoginController.dispose();
    _adminLoginController.dispose();
    _mentorSetupPinController.dispose();
    _adminSetupPasswordController.dispose();
    _mentorAreaController.dispose();
    _adminAreaController.dispose();
    _adminMentorManagementController.dispose();
    _adminCourseManagementController.dispose();
    _adminStudentManagementController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        _sessionController,
        _mentorLoginController,
        _adminLoginController,
        _mentorSetupPinController,
        _adminSetupPasswordController,
        _mentorAreaController,
        _adminAreaController,
        _adminMentorManagementController,
        _adminCourseManagementController,
        _adminStudentManagementController,
      ]),
      builder: (_, _) => _buildCurrentScreen(),
    );
  }

  Widget _buildCurrentScreen() {
    return switch (_sessionController.status) {
      SessionStatus.restoring => const SplashScreen(),

      SessionStatus.start => StartScreen(
        onAdminLogin: _sessionController.startAdminLogin,
        onMentorLogin: _sessionController.startMentorLogin,
      ),

      SessionStatus.adminLogin => AdminLoginScreen(
        phone: _adminLoginController.phone,
        password: _adminLoginController.password,
        phoneFieldVersion: _adminLoginController.phoneFieldVersion,
        phoneIsValid: _adminLoginController.phoneIsValid,
        canSubmit: _adminLoginController.canSubmit,
        isSubmitting: _sessionController.adminLoginIsSubmitting,
        message: _sessionController.adminLoginMessage,
        clearMessage: _sessionController.clearAdminLoginMessage,
        onPhoneChanged: _adminLoginController.setPhone,
        onPasswordChanged: _adminLoginController.setPassword,
        onClearPhone: _adminLoginController.clearPhone,
        onSubmit: _enterAdminArea,
        onCancel: _cancelAdminLogin,
      ),

      SessionStatus.mentorLogin => MentorLoginScreen(
        phone: _mentorLoginController.phone,
        pin: _mentorLoginController.pin,
        phoneFieldVersion: _mentorLoginController.phoneFieldVersion,
        phoneIsValid: _mentorLoginController.phoneIsValid,
        canSubmit: _mentorLoginController.canSubmit,
        isSubmitting: _sessionController.mentorLoginIsSubmitting,
        message: _sessionController.mentorLoginMessage,
        clearMessage: _sessionController.clearMentorLoginMessage,
        onPhoneChanged: _mentorLoginController.setPhone,
        onClearPhone: _mentorLoginController.clearPhone,
        onPinChanged: _mentorLoginController.setPin,
        onSubmit: _enterMentorArea,
        onCancel: _cancelMentorLogin,
      ),

      SessionStatus.adminSetupPassword => AdminSetupPasswordScreen(
        password: _adminSetupPasswordController.password,
        confirmPassword: _adminSetupPasswordController.confirmPassword,
        canSubmit: _adminSetupPasswordController.canSubmit,
        isSubmitting: _sessionController.adminSetupIsSubmitting,
        message: _sessionController.adminSetupMessage,
        clearMessage: _sessionController.clearAdminSetupMessage,
        onPasswordChanged: _adminSetupPasswordController.setPassword,
        onConfirmPasswordChanged:
            _adminSetupPasswordController.setConfirmPassword,
        onSubmit: _completeAdminSetup,
        onCancel: _logout,
      ),

      SessionStatus.mentorSetupPin => MentorSetupPinScreen(
        pin: _mentorSetupPinController.pin,
        confirmPin: _mentorSetupPinController.confirmPin,
        canSubmit: _mentorSetupPinController.canSubmit,
        isSubmitting: _sessionController.mentorSetupIsSubmitting,
        message: _sessionController.mentorSetupMessage,
        clearMessage: _sessionController.clearMentorSetupMessage,
        onPinChanged: _mentorSetupPinController.setPin,
        onConfirmPinChanged: _mentorSetupPinController.setConfirmPin,
        onSubmit: _completeMentorSetup,
        onCancel: _logout,
      ),

      SessionStatus.adminArea => _buildAdminArea(),

      SessionStatus.mentorArea => _buildMentorArea(),
    };
  }

  Widget _buildAdminArea() {
    return PopScope(
      canPop: _adminAreaController.screen == AdminScreen.menu,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          return;
        }

        if (_adminAreaController.screen == AdminScreen.manageMentors &&
            _adminMentorManagementController.view ==
                AdminMentorManagementView.form) {
          _adminMentorManagementController.cancelTaskScreen();
          return;
        }

        if (_adminAreaController.screen == AdminScreen.manageCourses &&
            _adminCourseManagementController.view !=
                AdminCourseManagementView.list) {
          _adminCourseManagementController.cancelTaskScreen();
          return;
        }

        if (_adminAreaController.screen == AdminScreen.manageStudents &&
            _adminStudentManagementController.view !=
                AdminStudentManagementView.list) {
          _adminStudentManagementController.cancelTaskScreen();
          return;
        }

        if (_adminAreaController.screen != AdminScreen.menu) {
          _adminAreaController.reset();
        }
      },
      child: switch (_adminAreaController.screen) {
        AdminScreen.menu => AdminMenuScreen(
          items: _adminAreaController.menuItems,
          onSelect: _selectAdminScreen,
          onLogout: _logout,
        ),

        AdminScreen.manageMentors => _buildAdminMentorManagementArea(),

        AdminScreen.manageCourses => _buildAdminCourseManagementArea(),

        AdminScreen.manageStudents => _buildAdminStudentManagementArea(),

        AdminScreen.trackStudents => PlaceholderTaskScreen(
          title: 'Track students',
          onHome: _returnToAdminMenu,
          onLogout: _logout,
        ),

        AdminScreen.reportsData => PlaceholderTaskScreen(
          title: 'Reports & data',
          onHome: _returnToAdminMenu,
          onLogout: _logout,
        ),
      },
    );
  }

  Widget _buildMentorArea() {
    return PopScope(
      canPop: _mentorAreaController.screen == MentorScreen.menu,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _mentorAreaController.screen != MentorScreen.menu) {
          _mentorAreaController.reset();
        }
      },
      child: switch (_mentorAreaController.screen) {
        MentorScreen.menu => MentorMenuScreen(
          items: _mentorAreaController.menuItems,
          onSelect: _mentorAreaController.select,
          onLogout: _logout,
        ),

        MentorScreen.myProfile => PlaceholderTaskScreen(
          title: 'My profile',
          onHome: _mentorAreaController.reset,
          onLogout: _logout,
        ),

        MentorScreen.sessionLog => PlaceholderTaskScreen(
          title: 'Session log',
          onHome: _mentorAreaController.reset,
          onLogout: _logout,
        ),

        MentorScreen.manageStudents => PlaceholderTaskScreen(
          title: 'Manage students',
          onHome: _mentorAreaController.reset,
          onLogout: _logout,
        ),

        MentorScreen.submitInvoice => PlaceholderTaskScreen(
          title: 'Submit invoice',
          onHome: _mentorAreaController.reset,
          onLogout: _logout,
        ),

        MentorScreen.uploadPhotos => PlaceholderTaskScreen(
          title: 'Upload photos',
          onHome: _mentorAreaController.reset,
          onLogout: _logout,
        ),

        MentorScreen.storyOfTheMonth => PlaceholderTaskScreen(
          title: 'Story of the month',
          onHome: _mentorAreaController.reset,
          onLogout: _logout,
        ),
      },
    );
  }

  Widget _buildAdminMentorManagementArea() {
    return switch (_adminMentorManagementController.view) {
      AdminMentorManagementView.list => AdminMentorManagementScreen(
        mentors: _adminMentorManagementController.visibleMentors,
        statusFilter: _adminMentorManagementController.statusFilter,
        selectedMentorId: _adminMentorManagementController.selectedMentorId,
        canEdit: _adminMentorManagementController.canEdit,
        isLoading: _adminMentorManagementController.isLoading,
        isSaving: _adminMentorManagementController.isSaving,
        message: _adminMentorManagementController.message,
        clearMessage: _adminMentorManagementController.clearMessage,
        onStatusFilterChanged: _setAdminMentorStatusFilter,
        onSelectMentor: _adminMentorManagementController.selectMentor,
        onAdd: _adminMentorManagementController.startAddMentor,
        onEdit: _adminMentorManagementController.startEditSelectedMentor,
        onResetPin: _adminMentorManagementController.startResetPin,
        onHome: _returnToAdminMenu,
        onLogout: _logout,
      ),

      AdminMentorManagementView.form => AdminMentorFormScreen(
        mentor: _adminMentorManagementController.formMentor,
        isSaving: _adminMentorManagementController.isSaving,
        message: _adminMentorManagementController.message,
        clearMessage: _adminMentorManagementController.clearMessage,
        onCreate: _createAdminMentor,
        onUpdate: _updateAdminMentor,
        onCancel: _adminMentorManagementController.cancelTaskScreen,
      ),

      AdminMentorManagementView.resetPin => AdminMentorResetPinScreen(
        mentor: _adminMentorManagementController.selectedMentor,
        isSaving: _adminMentorManagementController.isSaving,
        message: _adminMentorManagementController.message,
        clearMessage: _adminMentorManagementController.clearMessage,
        onResetPin: _resetAdminMentorPin,
        onCancel: _adminMentorManagementController.cancelTaskScreen,
      ),
    };
  }

  Widget _buildAdminCourseManagementArea() {
    return switch (_adminCourseManagementController.view) {
      AdminCourseManagementView.list => AdminCourseManagementScreen(
        courses: _adminCourseManagementController.visibleCourses,
        statusFilter: _adminCourseManagementController.statusFilter,
        selectedCourseId: _adminCourseManagementController.selectedCourseId,
        canEdit: _adminCourseManagementController.canEdit,
        canAssignMentors: _adminCourseManagementController.canAssignMentors,
        isLoading: _adminCourseManagementController.isLoading,
        isSaving: _adminCourseManagementController.isSaving,
        message: _adminCourseManagementController.message,
        clearMessage: _adminCourseManagementController.clearMessage,
        onStatusFilterChanged: _setAdminCourseStatusFilter,
        onSelectCourse: _adminCourseManagementController.selectCourse,
        onAdd: _adminCourseManagementController.startAddCourse,
        onEdit: _adminCourseManagementController.startEditSelectedCourse,
        onAssignMentors: _startAdminCourseMentorAssignment,
        onHome: _returnToAdminMenu,
        onLogout: _logout,
      ),

      AdminCourseManagementView.form => AdminCourseFormScreen(
        course: _adminCourseManagementController.formCourse,
        isSaving: _adminCourseManagementController.isSaving,
        message: _adminCourseManagementController.message,
        clearMessage: _adminCourseManagementController.clearMessage,
        onCreate: _createAdminCourse,
        onUpdate: _updateAdminCourse,
        onCancel: _adminCourseManagementController.cancelTaskScreen,
      ),

      AdminCourseManagementView.assignMentors =>
        AdminCourseMentorAssignmentScreen(
          course: _adminCourseManagementController.selectedCourse,
          mentors: _adminCourseManagementController.visibleMentors,
          assignedMentorIds: _adminCourseManagementController.assignedMentorIds,
          statusFilter: _adminCourseManagementController.mentorStatusFilter,
          isLoading: _adminCourseManagementController.isLoading,
          isSaving: _adminCourseManagementController.isSaving,
          message: _adminCourseManagementController.message,
          clearMessage: _adminCourseManagementController.clearMessage,
          onStatusFilterChanged: _setAdminCourseMentorStatusFilter,
          onAssignmentChanged: (mentorId, assigned) {
            _adminCourseManagementController.setMentorAssigned(
              mentorId: mentorId,
              assigned: assigned,
            );
          },
          onSave: _saveAdminCourseMentorAssignments,
          onCancel: _adminCourseManagementController.cancelTaskScreen,
        ),
    };
  }

  Widget _buildAdminStudentManagementArea() {
    return switch (_adminStudentManagementController.view) {
      AdminStudentManagementView.list => AdminStudentManagementScreen(
        students: _adminStudentManagementController.visibleStudents,
        courses: _adminStudentManagementController.courses,
        statusFilter: _adminStudentManagementController.statusFilter,
        courseIdFilter: _adminStudentManagementController.courseIdFilter,
        unassignedOnly: _adminStudentManagementController.unassignedOnly,
        selectedStudentId: _adminStudentManagementController.selectedStudentId,
        canEdit: _adminStudentManagementController.canEdit,
        canAssignCourses: _adminStudentManagementController.canAssignCourses,
        isLoading: _adminStudentManagementController.isLoading,
        isSaving: _adminStudentManagementController.isSaving,
        message: _adminStudentManagementController.message,
        clearMessage: _adminStudentManagementController.clearMessage,
        onStatusFilterChanged: _setAdminStudentStatusFilter,
        onCourseFilterChanged: _setAdminStudentCourseFilter,
        onUnassignedFilter:
            _adminStudentManagementController.setUnassignedFilter,
        onSelectStudent: _adminStudentManagementController.selectStudent,
        onAdd: _adminStudentManagementController.startAddStudent,
        onEdit: _adminStudentManagementController.startEditSelectedStudent,
        onAssignCourses: _startAdminStudentCourseAssignment,
        onHome: _returnToAdminMenu,
        onLogout: _logout,
      ),

      AdminStudentManagementView.form => AdminStudentFormScreen(
        student: _adminStudentManagementController.formStudent,
        isSaving: _adminStudentManagementController.isSaving,
        message: _adminStudentManagementController.message,
        clearMessage: _adminStudentManagementController.clearMessage,
        onCreate: _createAdminStudent,
        onUpdate: _updateAdminStudent,
        onCancel: _adminStudentManagementController.cancelTaskScreen,
      ),

      AdminStudentManagementView.assignCourses =>
        AdminStudentCourseAssignmentScreen(
          student: _adminStudentManagementController.selectedStudent,
          courses: _adminStudentManagementController.visibleCourses,
          assignedCourseIds:
              _adminStudentManagementController.assignedCourseIds,
          statusFilter: _adminStudentManagementController.courseStatusFilter,
          isLoading: _adminStudentManagementController.isLoading,
          isSaving: _adminStudentManagementController.isSaving,
          message: _adminStudentManagementController.message,
          clearMessage: _adminStudentManagementController.clearMessage,
          onStatusFilterChanged: _setAdminStudentCourseStatusFilter,
          onAssignmentChanged: (courseId, assigned) {
            _adminStudentManagementController.setCourseAssigned(
              courseId: courseId,
              assigned: assigned,
            );
          },
          onSave: _saveAdminStudentCourseAssignments,
          onCancel: _adminStudentManagementController.cancelTaskScreen,
        ),
    };
  }

  Future<void> _selectAdminScreen(AdminScreen screen) async {
    _adminAreaController.select(screen);

    if (screen == AdminScreen.manageMentors) {
      await _openAdminMentorManagement();
    }

    if (screen == AdminScreen.manageCourses) {
      await _openAdminCourseManagement();
    }

    if (screen == AdminScreen.manageStudents) {
      await _openAdminStudentManagement();
    }
  }

  Future<void> _openAdminMentorManagement() async {
    final token = _adminAccessToken();

    if (token == null) {
      return;
    }

    await _adminMentorManagementController.openList(accessToken: token);
  }

  Future<void> _setAdminMentorStatusFilter(
    MentorStatusFilter statusFilter,
  ) async {
    final token = _adminAccessToken();

    if (token == null) {
      return;
    }

    await _adminMentorManagementController.setStatusFilter(
      value: statusFilter,
      accessToken: token,
    );
  }

  Future<bool> _createAdminMentor(MentorCreateRequest request) async {
    final token = _adminAccessToken();

    if (token == null) {
      return false;
    }

    return _adminMentorManagementController.createMentor(
      accessToken: token,
      request: request,
    );
  }

  Future<bool> _updateAdminMentor(
    int mentorId,
    MentorUpdateRequest request,
  ) async {
    final token = _adminAccessToken();

    if (token == null) {
      return false;
    }

    return _adminMentorManagementController.updateMentor(
      accessToken: token,
      mentorId: mentorId,
      request: request,
    );
  }

  Future<void> _openAdminCourseManagement() async {
    final token = _adminAccessToken();

    if (token == null) {
      return;
    }

    await _adminCourseManagementController.openList(accessToken: token);
  }

  Future<void> _setAdminCourseStatusFilter(
    CourseStatusFilter statusFilter,
  ) async {
    final token = _adminAccessToken();

    if (token == null) {
      return;
    }

    await _adminCourseManagementController.setStatusFilter(
      value: statusFilter,
      accessToken: token,
    );
  }

  Future<void> _startAdminCourseMentorAssignment() async {
    final token = _adminAccessToken();

    if (token == null) {
      return;
    }

    await _adminCourseManagementController.startAssignMentors(
      accessToken: token,
    );
  }

  Future<void> _setAdminCourseMentorStatusFilter(
    CourseMentorStatusFilter statusFilter,
  ) async {
    final token = _adminAccessToken();

    if (token == null) {
      return;
    }

    await _adminCourseManagementController.setMentorStatusFilter(
      value: statusFilter,
      accessToken: token,
    );
  }

  Future<bool> _createAdminCourse(CourseCreateRequest request) async {
    final token = _adminAccessToken();

    if (token == null) {
      return false;
    }

    return _adminCourseManagementController.createCourse(
      accessToken: token,
      request: request,
    );
  }

  Future<bool> _updateAdminCourse(
    int courseId,
    CourseUpdateRequest request,
  ) async {
    final token = _adminAccessToken();

    if (token == null) {
      return false;
    }

    return _adminCourseManagementController.updateCourse(
      accessToken: token,
      courseId: courseId,
      request: request,
    );
  }

  Future<bool> _saveAdminCourseMentorAssignments() async {
    final token = _adminAccessToken();

    if (token == null) {
      return false;
    }

    return _adminCourseManagementController.saveMentorAssignments(
      accessToken: token,
    );
  }

  Future<void> _openAdminStudentManagement() async {
    final token = _adminAccessToken();

    if (token == null) {
      return;
    }

    await _adminStudentManagementController.openList(accessToken: token);
  }

  void _setAdminStudentStatusFilter(StudentStatusFilter statusFilter) {
    _adminStudentManagementController.setStatusFilter(statusFilter);
  }

  void _setAdminStudentCourseFilter(int? courseId) {
    _adminStudentManagementController.setCourseIdFilter(courseId);
  }

  Future<void> _startAdminStudentCourseAssignment() async {
    final token = _adminAccessToken();

    if (token == null) {
      return;
    }

    await _adminStudentManagementController.startAssignCourses(
      accessToken: token,
    );
  }

  Future<void> _setAdminStudentCourseStatusFilter(
    StudentCourseStatusFilter statusFilter,
  ) async {
    final token = _adminAccessToken();

    if (token == null) {
      return;
    }

    await _adminStudentManagementController.setCourseStatusFilter(
      value: statusFilter,
      accessToken: token,
    );
  }

  Future<bool> _createAdminStudent(StudentCreateRequest request) async {
    final token = _adminAccessToken();

    if (token == null) {
      return false;
    }

    return _adminStudentManagementController.createStudent(
      accessToken: token,
      request: request,
    );
  }

  Future<bool> _updateAdminStudent(
    int studentId,
    StudentUpdateRequest request,
  ) async {
    final token = _adminAccessToken();

    if (token == null) {
      return false;
    }

    return _adminStudentManagementController.updateStudent(
      accessToken: token,
      studentId: studentId,
      request: request,
    );
  }

  Future<bool> _saveAdminStudentCourseAssignments() async {
    final token = _adminAccessToken();

    if (token == null) {
      return false;
    }

    final success = await _adminStudentManagementController
        .saveCourseAssignments(accessToken: token);

    if (!success) {
      return false;
    }

    await _adminStudentManagementController.loadCourses(accessToken: token);

    return true;
  }

  String? _adminAccessToken() {
    final token = _sessionController.accessToken;

    if (_sessionController.status != SessionStatus.adminArea || token == null) {
      _logout();
      return null;
    }

    return token;
  }

  void _returnToAdminMenu() {
    _adminMentorManagementController.cancelTaskScreen();
    _adminCourseManagementController.cancelTaskScreen();
    _adminStudentManagementController.cancelTaskScreen();
    _adminAreaController.reset();
  }

  Future<void> _enterAdminArea() async {
    await _sessionController.submitAdminLogin(
      phone: _adminLoginController.phone,
      password: _adminLoginController.password,
    );

    if (_sessionController.status == SessionStatus.adminArea ||
        _sessionController.status == SessionStatus.adminSetupPassword) {
      await _adminLoginController.saveLastPhone();
      _adminLoginController.resetPassword();
      _adminAreaController.reset();
      _adminMentorManagementController.reset();
      _adminCourseManagementController.reset();
      _adminStudentManagementController.reset();
    }
  }

  Future<void> _enterMentorArea() async {
    await _sessionController.submitMentorLogin(
      phone: _mentorLoginController.phone,
      pin: _mentorLoginController.pin,
    );

    if (_sessionController.status == SessionStatus.mentorArea ||
        _sessionController.status == SessionStatus.mentorSetupPin) {
      await _mentorLoginController.saveLastPhone();
      _mentorLoginController.resetPin();
      _mentorAreaController.reset();
    }
  }

  void _cancelMentorLogin() {
    _mentorLoginController.resetPin();
    _sessionController.cancelLogin();
  }

  void _cancelAdminLogin() {
    _adminLoginController.resetPassword();
    _sessionController.cancelLogin();
  }

  Future<void> _completeAdminSetup() async {
    await _sessionController.submitAdminPasswordChange(
      newPassword: _adminSetupPasswordController.password,
    );

    if (_sessionController.status == SessionStatus.adminArea) {
      _adminSetupPasswordController.reset();
      _adminAreaController.reset();
      _adminMentorManagementController.reset();
      _adminCourseManagementController.reset();
      _adminStudentManagementController.reset();
    }
  }

  Future<void> _completeMentorSetup() async {
    await _sessionController.submitMentorPinChange(
      newPin: _mentorSetupPinController.pin,
    );

    if (_sessionController.status == SessionStatus.mentorArea) {
      _mentorSetupPinController.reset();
      _mentorAreaController.reset();
    }
  }

  Future<bool> _resetAdminMentorPin(MentorResetPinRequest request) async {
    final token = _adminAccessToken();

    if (token == null) {
      return false;
    }

    return _adminMentorManagementController.resetSelectedMentorPin(
      accessToken: token,
      request: request,
    );
  }

  Future<void> _logout() async {
    _adminAreaController.reset();
    _mentorAreaController.reset();
    _mentorLoginController.resetPin();
    _adminLoginController.resetPassword();
    _mentorSetupPinController.reset();
    _adminSetupPasswordController.reset();
    _adminMentorManagementController.reset();
    _adminCourseManagementController.reset();
    _adminStudentManagementController.reset();
    await _sessionController.logout();
  }
}
