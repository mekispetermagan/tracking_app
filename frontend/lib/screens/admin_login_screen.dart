import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AdminLoginScreen extends StatelessWidget {
  final String phone;
  final String password;
  final int phoneFieldVersion;
  final bool phoneIsValid;
  final bool canSubmit;
  final ValueChanged<String> onPhoneChanged;
  final ValueChanged<String> onPasswordChanged;
  final VoidCallback onClearPhone;
  final VoidCallback onSubmit;
  final VoidCallback onCancel;

  const AdminLoginScreen({
    required this.phone,
    required this.password,
    required this.phoneFieldVersion,
    required this.phoneIsValid,
    required this.canSubmit,
    required this.onPhoneChanged,
    required this.onPasswordChanged,
    required this.onClearPhone,
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
            TextFormField(
              key: ValueKey(phoneFieldVersion),
              initialValue: phone,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              decoration: InputDecoration(
                suffixIcon: phone.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: onClearPhone,
                      ),
              ),
              onChanged: onPhoneChanged,
            ),
            const SizedBox(height: 24),
            const Text('Password'),
            const SizedBox(height: 8),
            TextField(
              enabled: phoneIsValid,
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