import 'package:flutter/material.dart';

import '../widgets/app_bar.dart';
import 'package:flutter/services.dart';

import '../widgets/buttons.dart';

class AdminLoginScreen extends StatelessWidget {
  final String phone;
  final String password;
  final int phoneFieldVersion;
  final bool phoneIsValid;
  final bool canSubmit;
  final bool isSubmitting;
  final String? message;
  final VoidCallback clearMessage;
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
    required this.isSubmitting,
    required this.message,
    required this.clearMessage,
    required this.onPhoneChanged,
    required this.onPasswordChanged,
    required this.onClearPhone,
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
          ..showSnackBar(SnackBar(content: Text(message!)));
        clearMessage();
      });
    }

    return Scaffold(
      appBar: AppTopBar(title: const Text('Admin login'), onBack: onCancel),
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
            LargeFilledButton(
              onPressed: canSubmit && !isSubmitting ? onSubmit : null,
              child: Text(isSubmitting ? 'Logging in...' : 'Login'),
            ),
          ],
        ),
      ),
    );
  }
}
