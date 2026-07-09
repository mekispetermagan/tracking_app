import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';

class MentorSetupPinScreen extends StatelessWidget {
  final String pin;
  final String confirmPin;
  final bool canSubmit;
  final bool isSubmitting;
  final String? message;
  final VoidCallback clearMessage;
  final ValueChanged<String> onPinChanged;
  final ValueChanged<String> onConfirmPinChanged;
  final VoidCallback onSubmit;
  final VoidCallback onCancel;
  const MentorSetupPinScreen({
    required this.pin,
    required this.confirmPin,
    required this.canSubmit,
    required this.isSubmitting,
    required this.message,
    required this.clearMessage,    required this.onPinChanged,
    required this.onConfirmPinChanged,
    required this.onSubmit,
    required this.onCancel,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final pinTheme = PinTheme(
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
    );

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
        title: const Text('Set new PIN'),
        leading: BackButton(onPressed: onCancel),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(32),
          children: [
            const Text('New PIN'),
            const SizedBox(height: 16),
            Pinput(
              length: 6,
              onChanged: onPinChanged,
              defaultPinTheme: pinTheme,
            ),
            const SizedBox(height: 32),
            const Text('Confirm new PIN'),
            const SizedBox(height: 16),
            Pinput(
              length: 6,
              onChanged: onConfirmPinChanged,
              defaultPinTheme: pinTheme,
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: canSubmit && !isSubmitting ? onSubmit : null,
              child: Text(isSubmitting ? 'Saving...' : 'Save PIN'),
            ),
          ],
        ),
      ),
    );
  }
}