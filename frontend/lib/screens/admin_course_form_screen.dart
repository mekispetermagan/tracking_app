import 'package:flutter/material.dart';

import '../widgets/app_bar.dart';

import '../models/models.dart';
import '../widgets/buttons.dart';

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

  late int _dayOfWeek;
  late TimeOfDay _startTime;
  late bool _active;

  static const _dayNames = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

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

    _dayOfWeek = course?.dayOfWeek ?? 0;
    _startTime = _parseTime(course?.startTime ?? '09:00:00');
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
      appBar: AppTopBar(
        title: Text(widget.isEdit ? 'Edit course' : 'Add course'),
        onBack: widget.onCancel,
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
              const Text('Day'),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                initialValue: _dayOfWeek,
                items: List.generate(
                  _dayNames.length,
                  (index) => DropdownMenuItem(
                    value: index,
                    child: Text(_dayNames[index]),
                  ),
                ),
                onChanged: widget.isSaving
                    ? null
                    : (value) {
                        if (value != null) {
                          setState(() {
                            _dayOfWeek = value;
                          });
                        }
                      },
              ),
              const SizedBox(height: 20),
              const Text('Starting time'),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(_startTime.format(context)),
                trailing: const Icon(Icons.schedule),
                onTap: widget.isSaving ? null : _selectStartTime,
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
                      : 'Add course',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectStartTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );

    if (selected == null) {
      return;
    }

    setState(() {
      _startTime = selected;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final countryId = int.parse(_countryIdController.text.trim());
    final startTime = _formatTime(_startTime);
    final course = widget.course;

    final success = course != null
        ? await widget.onUpdate(
            course.id,
            CourseUpdateRequest(
              name: _nameController.text.trim(),
              description: _descriptionController.text.trim(),
              countryId: countryId,
              dayOfWeek: _dayOfWeek,
              startTime: startTime,
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
              dayOfWeek: _dayOfWeek,
              startTime: startTime,
              active: _active,
            ),
          );

    if (!mounted || !success) {
      return;
    }
  }

  TimeOfDay _parseTime(String value) {
    final parts = value.split(':');

    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  String _formatTime(TimeOfDay value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');

    return '$hour:$minute:00';
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
