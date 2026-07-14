import 'package:flutter/material.dart';

import '../models/models.dart';
import '../validation/credential_validation.dart' show isValidPin;

class AdminMentorResetPinScreen extends StatefulWidget {
  final Mentor? mentor;
  final bool isSaving;
  final String? message;
  final VoidCallback clearMessage;
  final Future<bool> Function(MentorResetPinRequest request) onResetPin;
  final VoidCallback onCancel;

  const AdminMentorResetPinScreen({
    required this.mentor,
    required this.isSaving,
    required this.message,
    required this.clearMessage,
    required this.onResetPin,
    required this.onCancel,
    super.key,
  });

  @override
  State<AdminMentorResetPinScreen> createState() =>
      _AdminMentorResetPinScreenState();
}

class _AdminMentorResetPinScreenState extends State<AdminMentorResetPinScreen> {
  final _formKey = GlobalKey<FormState>();
  final _temporaryPinController = TextEditingController();

  @override
  void dispose() {
    _temporaryPinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.message != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(widget.message!)));
        widget.clearMessage();
      });
    }

    final mentor = widget.mentor;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset mentor PIN'),
        leading: BackButton(onPressed: widget.onCancel),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              if (mentor != null) ...[
                Text(
                  mentor.fullName,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(mentor.phone),
                const SizedBox(height: 32),
              ],
              const Text('New temporary PIN'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _temporaryPinController,
                keyboardType: TextInputType.number,
                validator: _temporaryPinValidator,
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: widget.isSaving ? null : _submit,
                child: Text(widget.isSaving ? 'Saving...' : 'Reset PIN'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final success = await widget.onResetPin(
      MentorResetPinRequest(temporaryPin: _temporaryPinController.text.trim()),
    );

    if (!mounted || !success) {
      return;
    }
  }

  String? _temporaryPinValidator(String? value) {
    final pin = value?.trim() ?? '';

    if (pin.isEmpty) {
      return 'Required';
    }

    if (!isValidPin(pin)) {
      return 'Enter exactly 6 digits';
    }

    return null;
  }
}
