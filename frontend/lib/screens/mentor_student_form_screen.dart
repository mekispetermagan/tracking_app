import 'package:flutter/material.dart';

import '../models/models.dart';

class MentorStudentFormScreen extends StatefulWidget {
  final Student? student;
  final List<Course> courses;
  final bool isSaving;
  final String? message;
  final VoidCallback clearMessage;
  final Future<bool> Function(MentorStudentCreateRequest request) onCreate;
  final Future<bool> Function(int studentId, MentorStudentUpdateRequest request)
  onUpdate;
  final VoidCallback onCancel;

  const MentorStudentFormScreen({
    required this.student,
    required this.courses,
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
  State<MentorStudentFormScreen> createState() =>
      _MentorStudentFormScreenState();
}

class _MentorStudentFormScreenState extends State<MentorStudentFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _countryIdController;
  late final TextEditingController _birthYearController;

  late String? _gender;
  late Set<int> _selectedCourseIds;

  String? _courseError;

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
    _selectedCourseIds = student?.courseIds.toSet() ?? {};
  }

  @override
  void didUpdateWidget(MentorStudentFormScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.student?.id != widget.student?.id) {
      _selectedCourseIds = widget.student?.courseIds.toSet() ?? {};
    }
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
              const SizedBox(height: 32),
              Text('Courses', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              const Text('Select the courses attended by this student.'),
              if (_courseError != null) ...[
                const SizedBox(height: 8),
                Text(
                  _courseError!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 8),
              _buildCourseList(),
              const SizedBox(height: 32),
              FilledButton(
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

  Widget _buildCourseList() {
    if (widget.courses.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Text('No courses available'),
      );
    }

    return Column(
      children: widget.courses.map((course) {
        final selected = _selectedCourseIds.contains(course.id);

        final originallyAssigned =
            widget.student?.courseIds.contains(course.id) ?? false;

        final enabled =
            !widget.isSaving && (course.active || originallyAssigned);

        return CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          value: selected,
          title: Text(course.name),
          subtitle: course.active ? null : const Text('Inactive course'),
          secondary: course.active
              ? null
              : const Icon(Icons.block, semanticLabel: 'Inactive'),
          onChanged: enabled
              ? (value) {
                  setState(() {
                    if (value ?? false) {
                      _selectedCourseIds.add(course.id);
                    } else {
                      _selectedCourseIds.remove(course.id);
                    }

                    _courseError = null;
                  });
                }
              : null,
        );
      }).toList(),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!widget.isEdit && _selectedCourseIds.isEmpty) {
      setState(() {
        _courseError = 'Assign the student to at least one course.';
      });
      return;
    }

    final student = widget.student;

    if (student != null &&
        student.courseIds.isNotEmpty &&
        _selectedCourseIds.isEmpty) {
      final confirmed = await _confirmCompleteUnassignment();

      if (!confirmed) {
        return;
      }
    }

    final courseIds = _selectedCourseIds.toList()..sort();

    if (student == null) {
      await widget.onCreate(
        MentorStudentCreateRequest(
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          originCountryId: _parseOptionalInt(_countryIdController.text),
          birthYear: _parseOptionalInt(_birthYearController.text),
          gender: _gender,
          courseIds: courseIds,
        ),
      );

      return;
    }

    await widget.onUpdate(
      student.id,
      MentorStudentUpdateRequest(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        originCountryId: _parseOptionalInt(_countryIdController.text),
        birthYear: _parseOptionalInt(_birthYearController.text),
        gender: _gender,
        courseIds: courseIds,
      ),
    );
  }

  Future<bool> _confirmCompleteUnassignment() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Remove all courses?'),
          content: const Text(
            'The student will no longer be visible or '
            'accessible to you. An administrator can restore '
            'the course assignment.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );

    return result ?? false;
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
