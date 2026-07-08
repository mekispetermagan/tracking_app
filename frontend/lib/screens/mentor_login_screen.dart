import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';

class MentorLoginScreen extends StatelessWidget {
  final String phone;
  final String pin;
  final bool numberIsValid;
  final bool canSubmit;
  final ValueChanged<String> onPhoneChanged;
  final ValueChanged<String> onPinChanged;
  final VoidCallback onSubmit;
  final VoidCallback onCancel;

  const MentorLoginScreen({
    required this.phone,
    required this.pin,
    required this.numberIsValid,
    required this.canSubmit,
    required this.onPhoneChanged,
    required this.onPinChanged,
    required this.onSubmit,
    required this.onCancel,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mentor login'),
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
            const SizedBox(height: 32),
            const Text('PIN'),
            const SizedBox(height: 16),
            Pinput(
              length: 6,
              enabled: numberIsValid,
              onChanged: onPinChanged,
              defaultPinTheme: PinTheme(
                width: 56,
                height: 64,
                textStyle: TextStyle(
                  fontSize: 36,
                  color: cs.onSecondaryContainer,
                ),
                decoration: BoxDecoration(
                  color: cs.secondaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
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