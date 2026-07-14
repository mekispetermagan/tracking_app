import 'package:flutter/material.dart';

import '../models/models.dart';
import '../validation/credential_validation.dart' show isValidPhone, isValidPin;

class AdminMentorFormScreen extends StatefulWidget {
  final Mentor? mentor;
  final bool isSaving;
  final String? message;
  final VoidCallback clearMessage;
  final Future<bool> Function(MentorCreateRequest request) onCreate;
  final Future<bool> Function(int mentorId, MentorUpdateRequest request)
  onUpdate;
  final VoidCallback onCancel;

  const AdminMentorFormScreen({
    required this.mentor,
    required this.isSaving,
    required this.message,
    required this.clearMessage,
    required this.onCreate,
    required this.onUpdate,
    required this.onCancel,
    super.key,
  });

  bool get isEdit => mentor != null;

  @override
  State<AdminMentorFormScreen> createState() => _AdminMentorFormScreenState();
}

class _AdminMentorFormScreenState extends State<AdminMentorFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _countryIdController;
  late final TextEditingController _temporaryPinController;

  late String _preferredLanguage;
  late bool _active;

  static const _languageValues = ['en', 'hu', 'ua'];

  @override
  void initState() {
    super.initState();

    final mentor = widget.mentor;
    final initialLanguage = mentor?.preferredLanguage ?? 'en';

    _firstNameController = TextEditingController(text: mentor?.firstName ?? '');
    _lastNameController = TextEditingController(text: mentor?.lastName ?? '');
    _phoneController = TextEditingController(text: mentor?.phone ?? '');
    _countryIdController = TextEditingController(
      text: mentor?.countryId?.toString() ?? '',
    );
    _temporaryPinController = TextEditingController();

    _preferredLanguage = _languageValues.contains(initialLanguage)
        ? initialLanguage
        : 'en';
    _active = mentor?.active ?? true;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _countryIdController.dispose();
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

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEdit ? 'Edit mentor' : 'Add mentor'),
        leading: BackButton(onPressed: widget.onCancel),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Text('First name'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _firstNameController,
                textInputAction: TextInputAction.next,
                validator: _required,
              ),
              const SizedBox(height: 20),

              const Text('Last name'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _lastNameController,
                textInputAction: TextInputAction.next,
                validator: _required,
              ),
              const SizedBox(height: 20),

              const Text('Phone'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                validator: _phoneValidator,
              ),
              const SizedBox(height: 20),

              const Text('Country ID'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _countryIdController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                validator: _optionalInt,
              ),
              const SizedBox(height: 20),

              const Text('Preferred language'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _preferredLanguage,
                items: const [
                  DropdownMenuItem(value: 'en', child: Text('English')),
                  DropdownMenuItem(value: 'hu', child: Text('Hungarian')),
                  DropdownMenuItem(value: 'ua', child: Text('Ukrainian')),
                ],
                onChanged: widget.isSaving
                    ? null
                    : (value) {
                        if (value == null) return;

                        setState(() {
                          _preferredLanguage = value;
                        });
                      },
              ),
              const SizedBox(height: 20),

              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Active'),
                value: _active,
                onChanged: widget.isSaving
                    ? null
                    : (value) {
                        setState(() {
                          _active = value;
                        });
                      },
              ),

              if (!widget.isEdit) ...[
                const SizedBox(height: 20),
                const Text('Temporary PIN'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _temporaryPinController,
                  keyboardType: TextInputType.number,
                  validator: _temporaryPinValidator,
                ),
              ],

              const SizedBox(height: 32),
              FilledButton(
                onPressed: widget.isSaving ? null : _submit,
                child: Text(
                  widget.isSaving
                      ? 'Saving...'
                      : widget.isEdit
                      ? 'Save changes'
                      : 'Add mentor',
                ),
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

    final countryId = _parseCountryId();

    final success = widget.isEdit
        ? await widget.onUpdate(
            widget.mentor!.id,
            MentorUpdateRequest(
              firstName: _firstNameController.text.trim(),
              lastName: _lastNameController.text.trim(),
              phone: _phoneController.text.trim(),
              countryId: countryId,
              preferredLanguage: _preferredLanguage,
              active: _active,
              courseIds: widget.mentor!.courseIds,
            ),
          )
        : await widget.onCreate(
            MentorCreateRequest(
              firstName: _firstNameController.text.trim(),
              lastName: _lastNameController.text.trim(),
              phone: _phoneController.text.trim(),
              countryId: countryId,
              preferredLanguage: _preferredLanguage,
              temporaryPin: _temporaryPinController.text.trim(),
              active: _active,
            ),
          );

    if (!mounted || !success) {
      return;
    }
  }

  int? _parseCountryId() {
    final text = _countryIdController.text.trim();

    if (text.isEmpty) {
      return null;
    }

    return int.parse(text);
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Required';
    }

    return null;
  }

  String? _optionalInt(String? value) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return null;
    }

    if (int.tryParse(text) == null) {
      return 'Must be a number';
    }

    return null;
  }

  String? _phoneValidator(String? value) {
    final phone = value?.trim() ?? '';

    if (phone.isEmpty) {
      return 'Required';
    }

    if (!isValidPhone(phone)) {
      return '10 digits starting with 0';
    }

    return null;
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
