import 'package:flutter/material.dart';

import 'controllers/admin_area_controller.dart';
import 'controllers/mentor_area_controller.dart';
import 'controllers/session_controller.dart';
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
  final _mentorAreaController = MentorAreaController();
  final _adminAreaController = AdminAreaController();

  @override
  void initState() {
    super.initState();
    _sessionController.restoreSession();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        _sessionController,
        _mentorAreaController,
        _adminAreaController,
      ]),
      builder: (_, __) => _buildCurrentScreen(),
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
          phone: '',
          password: '',
          canSubmit: true,
          onPhoneChanged: (_) {},
          onPasswordChanged: (_) {},
          onSubmit: _enterAdminArea,
          onCancel: _sessionController.cancelLogin,
        ),

      SessionStatus.mentorLogin => MentorLoginScreen(
          phone: '',
          pin: '',
          numberIsValid: true,
          canSubmit: true,
          onPhoneChanged: (_) {},
          onPinChanged: (_) {},
          onSubmit: _enterMentorArea,
          onCancel: _sessionController.cancelLogin,
        ),

      SessionStatus.adminSetupPassword => AdminSetupPasswordScreen(
          password: '',
          confirmPassword: '',
          canSubmit: true,
          onPasswordChanged: (_) {},
          onConfirmPasswordChanged: (_) {},
          onSubmit: _completeAdminSetup,
          onCancel: _sessionController.logout,
        ),

      SessionStatus.mentorSetupPin => MentorSetupPinScreen(
          pin: '',
          confirmPin: '',
          canSubmit: true,
          onPinChanged: (_) {},
          onConfirmPinChanged: (_) {},
          onSubmit: _completeMentorSetup,
          onCancel: _sessionController.logout,
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

  void _enterAdminArea() {
    _adminAreaController.reset();
    _sessionController.fakeAdminLogin();
  }

  void _enterMentorArea() {
    _mentorAreaController.reset();
    _sessionController.fakeMentorLogin();
  }

  void _completeAdminSetup() {
    _adminAreaController.reset();
    _sessionController.completeAdminSetup();
  }

  void _completeMentorSetup() {
    _mentorAreaController.reset();
    _sessionController.completeMentorSetup();
  }

  void _logout() {
    _adminAreaController.reset();
    _mentorAreaController.reset();
    _sessionController.logout();
  }
}