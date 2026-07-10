import 'package:flutter/material.dart';

import '../models/models.dart';

class AdminCourseFormScreen extends StatefulWidget {
  final Course? course;
  final bool isSaving;
  final String? message;
  final VoidCallback clearMessage;
  final Future<bool> Function(CourseCreateRequest request) onCreate;
  final Future<bool> Function(int courseId, CourseUpdateRequest request)
  onUpdate;
  final VoidCallback onCancel;

  const AdminCourseFormScreen({
    required this.course,
    required this.isSaving,
    required this.message,
    required this.clearMessage,
    required this.onCreate,
    required this.onUpdate,
    required this.onCancel,
    super.key,
  });

  bool get isEdit => course != null;

  @override
  State<AdminCourseFormScreen> createState() => _AdminCourseFormScreenState();
}

class _AdminCourseFormScreenState extends State<AdminCourseFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _countryIdController;

  late bool _active;

  @override
  void initState() {
    super.initState();

    final course = widget.course;

    _nameController = TextEditingController(text: course?.name ?? '');
    _descriptionController = TextEditingController(
      text: course?.description ?? '',
    );
    _countryIdController = TextEditingController(
      text: course?.countryId.toString() ?? '',
    );
    _active = course?.active ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _countryIdController.dispose();
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
        title: Text(widget.isEdit ? 'Edit course' : 'Add course'),
        leading: BackButton(onPressed: widget.onCancel),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Text('Name'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                textInputAction: TextInputAction.next,
                validator: _required,
              ),
              const SizedBox(height: 20),
              const Text('Description'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                minLines: 3,
                maxLines: 8,
                textInputAction: TextInputAction.newline,
              ),
              const SizedBox(height: 20),
              const Text('Country ID'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _countryIdController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                validator: _requiredInt,
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
              FilledButton(
                onPressed: widget.isSaving ? null : _submit,
                child: Text(
                  widget.isSaving
                      ? 'Saving...'
                      : widget.isEdit
                      ? 'Save changes'
                      : 'Add course',
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

    final countryId = int.parse(_countryIdController.text.trim());
    final course = widget.course;

    final success = course != null
        ? await widget.onUpdate(
            course.id,
            CourseUpdateRequest(
              name: _nameController.text.trim(),
              description: _descriptionController.text.trim(),
              countryId: countryId,
              active: _active,
              mentorIds: course.mentorIds,
              studentIds: course.studentIds,
            ),
          )
        : await widget.onCreate(
            CourseCreateRequest(
              name: _nameController.text.trim(),
              description: _descriptionController.text.trim(),
              countryId: countryId,
              active: _active,
            ),
          );

    if (!mounted || !success) {
      return;
    }
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Required';
    }

    return null;
  }

  String? _requiredInt(String? value) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return 'Required';
    }

    if (int.tryParse(text) == null) {
      return 'Must be a number';
    }

    return null;
  }
}
