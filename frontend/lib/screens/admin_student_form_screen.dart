import 'package:flutter/material.dart';

import '../models/models.dart';
import '../widgets/buttons.dart';

class AdminStudentFormScreen extends StatefulWidget {
  final Student? student;
  final bool isSaving;
  final String? message;
  final VoidCallback clearMessage;
  final Future<bool> Function(StudentCreateRequest request) onCreate;
  final Future<bool> Function(int studentId, StudentUpdateRequest request)
  onUpdate;
  final VoidCallback onCancel;

  const AdminStudentFormScreen({
    required this.student,
    required this.isSaving,
    required this.message,
    required this.clearMessage,
    required this.onCreate,
    required this.onUpdate,
    required this.onCancel,
    super.key,
  });

  bool get isEdit => student != null;

  @override
  State<AdminStudentFormScreen> createState() => _AdminStudentFormScreenState();
}

class _AdminStudentFormScreenState extends State<AdminStudentFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _countryIdController;
  late final TextEditingController _birthYearController;

  late String? _gender;
  late bool _active;

  @override
  void initState() {
    super.initState();

    final student = widget.student;

    _firstNameController = TextEditingController(
      text: student?.firstName ?? '',
    );
    _lastNameController = TextEditingController(text: student?.lastName ?? '');
    _countryIdController = TextEditingController(
      text: student?.originCountryId?.toString() ?? '',
    );
    _birthYearController = TextEditingController(
      text: student?.birthYear?.toString() ?? '',
    );

    _gender = student?.gender;
    _active = student?.active ?? true;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _countryIdController.dispose();
    _birthYearController.dispose();
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
        title: Text(widget.isEdit ? 'Edit student' : 'Add student'),
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
              const Text('Country ID'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _countryIdController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                validator: _optionalInt,
              ),
              const SizedBox(height: 20),
              const Text('Birth year'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _birthYearController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                validator: _birthYearValidator,
              ),
              const SizedBox(height: 20),
              const Text('Gender'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String?>(
                initialValue: _gender,
                items: const [
                  DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Not specified'),
                  ),
                  DropdownMenuItem(value: 'M', child: Text('Male')),
                  DropdownMenuItem(value: 'F', child: Text('Female')),
                  DropdownMenuItem(value: 'N', child: Text('Other')),
                ],
                onChanged: widget.isSaving
                    ? null
                    : (value) {
                        setState(() {
                          _gender = value;
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
              const SizedBox(height: 32),
              LargeFilledButton(
                onPressed: widget.isSaving ? null : _submit,
                child: Text(
                  widget.isSaving
                      ? 'Saving...'
                      : widget.isEdit
                      ? 'Save changes'
                      : 'Add student',
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

    final student = widget.student;

    final success = student != null
        ? await widget.onUpdate(
            student.id,
            StudentUpdateRequest(
              firstName: _firstNameController.text.trim(),
              lastName: _lastNameController.text.trim(),
              originCountryId: _parseOptionalInt(_countryIdController.text),
              birthYear: _parseOptionalInt(_birthYearController.text),
              gender: _gender,
              active: _active,
              courseIds: student.courseIds,
            ),
          )
        : await widget.onCreate(
            StudentCreateRequest(
              firstName: _firstNameController.text.trim(),
              lastName: _lastNameController.text.trim(),
              originCountryId: _parseOptionalInt(_countryIdController.text),
              birthYear: _parseOptionalInt(_birthYearController.text),
              gender: _gender,
              active: _active,
            ),
          );

    if (!mounted || !success) {
      return;
    }
  }

  int? _parseOptionalInt(String value) {
    final text = value.trim();

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

  String? _birthYearValidator(String? value) {
    final error = _optionalInt(value);

    if (error != null) {
      return error;
    }

    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return null;
    }

    final year = int.parse(text);

    if (year < 1900 || year > DateTime.now().year) {
      return 'Invalid birth year';
    }

    return null;
  }
}
