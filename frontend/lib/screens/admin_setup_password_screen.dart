import 'package:flutter/material.dart';

class AdminSetupPasswordScreen extends StatelessWidget {
  final String password;
  final String confirmPassword;
  final bool canSubmit;
  final bool isSubmitting;
  final String? message;
  final VoidCallback clearMessage;
  final ValueChanged<String> onPasswordChanged;
  final ValueChanged<String> onConfirmPasswordChanged;
  final VoidCallback onSubmit;
  final VoidCallback onCancel;

  const AdminSetupPasswordScreen({
    required this.password,
    required this.confirmPassword,
    required this.canSubmit,
    required this.isSubmitting,
    required this.message,
    required this.clearMessage,
    required this.onPasswordChanged,
    required this.onConfirmPasswordChanged,
    required this.onSubmit,
    required this.onCancel,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (message != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text(message!)),
          );
        clearMessage();
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Set new password'),
        leading: BackButton(onPressed: onCancel),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(32),
          children: [
            const Text('New password'),
            const SizedBox(height: 8),
            TextField(
              obscureText: true,
              onChanged: onPasswordChanged,
            ),
            const SizedBox(height: 24),
            const Text('Confirm new password'),
            const SizedBox(height: 8),
            TextField(
              obscureText: true,
              onChanged: onConfirmPasswordChanged,
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: canSubmit && !isSubmitting ? onSubmit : null,
              child: Text(isSubmitting ? 'Saving...' : 'Save password'),
            ),
          ],
        ),
      ),
    );
  }
}