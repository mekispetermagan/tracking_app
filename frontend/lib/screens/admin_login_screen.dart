import 'package:flutter/material.dart';

class AdminLoginScreen extends StatelessWidget {
  final String phone;
  final String password;
  final bool canSubmit;
  final ValueChanged<String> onPhoneChanged;
  final ValueChanged<String> onPasswordChanged;
  final VoidCallback onSubmit;
  final VoidCallback onCancel;

  const AdminLoginScreen({
    required this.phone,
    required this.password,
    required this.canSubmit,
    required this.onPhoneChanged,
    required this.onPasswordChanged,
    required this.onSubmit,
    required this.onCancel,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin login'),
        leading: BackButton(onPressed: onCancel),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(32),
          children: [
            const Text('Phone number'),
            const SizedBox(height: 8),
            TextField(
              keyboardType: TextInputType.phone,
              onChanged: onPhoneChanged,
            ),
            const SizedBox(height: 24),
            const Text('Password'),
            const SizedBox(height: 8),
            TextField(
              obscureText: true,
              onChanged: onPasswordChanged,
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: canSubmit ? onSubmit : null,
              child: const Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}