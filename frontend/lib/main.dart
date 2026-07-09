import 'package:flutter/material.dart';

import 'controllers/controllers.dart';
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
      theme: ThemeData(
        colorScheme: scheme,
        useMaterial3: true,
      ),
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

  @override
  void initState() {
    super.initState();
    _sessionController.restoreSession();
    _mentorLoginController.loadLastPhone();
    _adminLoginController.loadLastPhone();
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
        if (!didPop && _adminAreaController.screen != AdminScreen.menu) {
          _adminAreaController.reset();
        }
      },
      child: switch (_adminAreaController.screen) {
        AdminScreen.menu => AdminMenuScreen(
            items: _adminAreaController.menuItems,
            onSelect: _adminAreaController.select,
            onLogout: _logout,
          ),
        AdminScreen.manageMentors => PlaceholderTaskScreen(
            title: 'Manage mentors',
            onHome: _adminAreaController.reset,
            onLogout: _logout,
          ),
        AdminScreen.manageCourses => PlaceholderTaskScreen(
            title: 'Manage courses',
            onHome: _adminAreaController.reset,
            onLogout: _logout,
          ),
        AdminScreen.manageStudents => PlaceholderTaskScreen(
            title: 'Manage students',
            onHome: _adminAreaController.reset,
            onLogout: _logout,
          ),
        AdminScreen.trackStudents => PlaceholderTaskScreen(
            title: 'Track students',
            onHome: _adminAreaController.reset,
            onLogout: _logout,
          ),
        AdminScreen.reportsData => PlaceholderTaskScreen(
            title: 'Reports & data',
            onHome: _adminAreaController.reset,
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

  void _logout() {
    _adminAreaController.reset();
    _mentorAreaController.reset();
    _mentorLoginController.resetPin();
    _adminLoginController.resetPassword();
    _mentorSetupPinController.reset();
    _adminSetupPasswordController.reset();
    _sessionController.logout();
  }
}