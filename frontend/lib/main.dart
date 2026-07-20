import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'areas/areas.dart';
import 'controllers/controllers.dart';
import 'screens/screens.dart';
import 'theme/app_theme.dart';
import 'theme/font_licenses.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  registerFontLicenses();
  runApp(const ProgressTrackingApp());
}

class ProgressTrackingApp extends StatelessWidget {
  const ProgressTrackingApp({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF3F7CAC),
      brightness: Brightness.dark,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(scheme),
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

      SessionStatus.adminArea => AdminArea(
        accessToken: _sessionController.accessToken!,
        onLogout: _logout,
      ),

      SessionStatus.mentorArea => MentorArea(
        accessToken: _sessionController.accessToken!,
        onLogout: _logout,
      ),
    };
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
    }
  }

  Future<void> _completeMentorSetup() async {
    await _sessionController.submitMentorPinChange(
      newPin: _mentorSetupPinController.pin,
    );

    if (_sessionController.status == SessionStatus.mentorArea) {
      _mentorSetupPinController.reset();
    }
  }

  Future<void> _logout() async {
    _mentorLoginController.resetPin();
    _adminLoginController.resetPassword();
    _mentorSetupPinController.reset();
    _adminSetupPasswordController.reset();
    await _sessionController.logout();
  }
}
