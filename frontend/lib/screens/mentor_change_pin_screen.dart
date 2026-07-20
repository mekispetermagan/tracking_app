import 'package:flutter/material.dart';

import '../models/models.dart';
import '../validation/credential_validation.dart' show isValidPin;
import '../widgets/buttons.dart';

class MentorChangePinScreen extends StatefulWidget {
  final bool isChangingPin;
  final String? message;
  final VoidCallback clearMessage;
  final Future<bool> Function(MentorChangePinRequest request) onChangePin;
  final VoidCallback onCancel;

  const MentorChangePinScreen({
    required this.isChangingPin,
    required this.message,
    required this.clearMessage,
    required this.onChangePin,
    required this.onCancel,
    super.key,
  });

  @override
  State<MentorChangePinScreen> createState() => _MentorChangePinScreenState();
}

class _MentorChangePinScreenState extends State<MentorChangePinScreen> {
  final _formKey = GlobalKey<FormState>();

  final _currentPinController = TextEditingController();
  final _newPinController = TextEditingController();
  final _confirmPinController = TextEditingController();

  @override
  void dispose() {
    _currentPinController.dispose();
    _newPinController.dispose();
    _confirmPinController.dispose();
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Change PIN'),
        leading: BackButton(onPressed: widget.onCancel),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Text('Current PIN'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _currentPinController,
                enabled: !widget.isChangingPin,
                keyboardType: TextInputType.number,
                obscureText: true,
                textInputAction: TextInputAction.next,
                validator: _pinValidator,
              ),
              const SizedBox(height: 20),

              const Text('New PIN'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _newPinController,
                enabled: !widget.isChangingPin,
                keyboardType: TextInputType.number,
                obscureText: true,
                textInputAction: TextInputAction.next,
                validator: _pinValidator,
              ),
              const SizedBox(height: 20),

              const Text('Confirm new PIN'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _confirmPinController,
                enabled: !widget.isChangingPin,
                keyboardType: TextInputType.number,
                obscureText: true,
                textInputAction: TextInputAction.done,
                validator: _confirmPinValidator,
              ),
              const SizedBox(height: 32),

              LargeFilledButton(
                onPressed: widget.isChangingPin ? null : _submit,
                child: Text(widget.isChangingPin ? 'Saving...' : 'Change PIN'),
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

    final success = await widget.onChangePin(
      MentorChangePinRequest(
        currentPin: _currentPinController.text.trim(),
        newPin: _newPinController.text.trim(),
      ),
    );

    if (!mounted || !success) {
      return;
    }

    widget.onCancel();
  }

  String? _pinValidator(String? value) {
    final pin = value?.trim() ?? '';

    if (pin.isEmpty) {
      return 'Required';
    }

    if (!isValidPin(pin)) {
      return 'Enter exactly 6 digits';
    }

    return null;
  }

  String? _confirmPinValidator(String? value) {
    final validation = _pinValidator(value);

    if (validation != null) {
      return validation;
    }

    if (value!.trim() != _newPinController.text.trim()) {
      return 'PINs do not match';
    }

    return null;
  }
}
