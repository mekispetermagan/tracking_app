import 'package:flutter/material.dart';

import '../widgets/app_bar.dart';

import '../models/models.dart';
import '../widgets/buttons.dart';

class MentorCourseFormScreen extends StatefulWidget {
  final Course course;
  final bool isSaving;
  final String? message;
  final VoidCallback clearMessage;
  final Future<bool> Function({
    required String description,
    required int dayOfWeek,
    required String startTime,
  })
  onSave;
  final VoidCallback onCancel;

  const MentorCourseFormScreen({
    required this.course,
    required this.isSaving,
    required this.message,
    required this.clearMessage,
    required this.onSave,
    required this.onCancel,
    super.key,
  });

  @override
  State<MentorCourseFormScreen> createState() => _MentorCourseFormScreenState();
}

class _MentorCourseFormScreenState extends State<MentorCourseFormScreen> {
  late final TextEditingController _descriptionController;

  late int _dayOfWeek;
  late TimeOfDay _startTime;

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

    _descriptionController = TextEditingController(
      text: widget.course.description,
    );
    _dayOfWeek = widget.course.dayOfWeek;
    _startTime = _parseTime(widget.course.startTime);
  }

  @override
  void dispose() {
    _descriptionController.dispose();
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
        title: const Text('Edit course'),
        onBack: widget.onCancel,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Text('Name'),
            const SizedBox(height: 8),
            TextFormField(initialValue: widget.course.name, readOnly: true),
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
            const Text('Country ID'),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: widget.course.countryId.toString(),
              readOnly: true,
            ),
            const SizedBox(height: 20),
            const Text('Status'),
            const SizedBox(height: 8),
            Text(widget.course.active ? 'Active' : 'Inactive'),
            const SizedBox(height: 32),
            LargeFilledButton(
              onPressed: widget.isSaving ? null : _submit,
              child: Text(widget.isSaving ? 'Saving...' : 'Save changes'),
            ),
          ],
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
    final success = await widget.onSave(
      description: _descriptionController.text.trim(),
      dayOfWeek: _dayOfWeek,
      startTime: _formatTime(_startTime),
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
}
