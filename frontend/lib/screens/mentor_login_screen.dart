import 'package:flutter/material.dart';

import '../help/help_texts.dart';
import '../widgets/app_bar.dart';
import 'package:flutter/services.dart';
import 'package:pinput/pinput.dart';

import '../widgets/buttons.dart';

class MentorLoginScreen extends StatelessWidget {
  final String phone;
  final String pin;
  final bool phoneIsValid;
  final int phoneFieldVersion;
  final bool canSubmit;
  final ValueChanged<String> onPhoneChanged;
  final ValueChanged<String> onPinChanged;
  final VoidCallback onClearPhone;
  final VoidCallback onSubmit;
  final VoidCallback onCancel;
  final bool isSubmitting;
  final String? message;
  final VoidCallback clearMessage;

  const MentorLoginScreen({
    required this.phone,
    required this.pin,
    required this.phoneIsValid,
    required this.phoneFieldVersion,
    required this.canSubmit,
    required this.onPhoneChanged,
    required this.onPinChanged,
    required this.onClearPhone,
    required this.onSubmit,
    required this.onCancel,
    required this.isSubmitting,
    required this.message,
    required this.clearMessage,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (message != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(message!)));
        clearMessage();
      });
    }

    return Scaffold(
      appBar: AppTopBar(
        title: const Text('Mentor login'),
        onBack: onCancel,
        helpText: HelpTexts.mentorLogin,
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
            const SizedBox(height: 32),
            const Text('PIN'),
            const SizedBox(height: 16),
            Pinput(
              length: 6,
              enabled: phoneIsValid,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
