import 'package:flutter/material.dart';

import '../controllers/controllers.dart';
import '../models/models.dart';
import '../widgets/mentor_session_log_form_sections.dart';

class MentorSessionLogFormScreen extends StatefulWidget {
  final List<Course> courses;
  final List<Student> students;
  final List<SharedMentor> mentors;

  final int? selectedCourseId;
  final Set<int> selectedStudentIds;
  final Set<int> selectedTeachingMentorIds;
  final Set<int> selectedSupportingMentorIds;

  final bool isLoading;
  final bool isSaving;
  final String? message;

  final VoidCallback clearMessage;
  final Future<void> Function(int courseId) onCourseSelected;

  final void Function(int studentId) onToggleStudent;
  final VoidCallback onSelectAllStudents;
  final VoidCallback onClearStudents;

  final void Function(int mentorId) onToggleTeachingMentor;
  final void Function(int mentorId) onToggleSupportingMentor;
  final VoidCallback onClearMentors;

  final Future<bool> Function(SessionLogCreateRequest request) onSubmit;

  final VoidCallback onSubmitted;
  final VoidCallback onCancel;

  const MentorSessionLogFormScreen({
    required this.courses,
    required this.students,
    required this.mentors,
    required this.selectedCourseId,
    required this.selectedStudentIds,
    required this.selectedTeachingMentorIds,
    required this.selectedSupportingMentorIds,
    required this.isLoading,
    required this.isSaving,
    required this.message,
    required this.clearMessage,
    required this.onCourseSelected,
    required this.onToggleStudent,
    required this.onSelectAllStudents,
    required this.onClearStudents,
    required this.onToggleTeachingMentor,
    required this.onToggleSupportingMentor,
    required this.onClearMentors,
    required this.onSubmit,
    required this.onSubmitted,
    required this.onCancel,
    super.key,
  });

  @override
  State<MentorSessionLogFormScreen> createState() =>
      _MentorSessionLogFormScreenState();
}

class _MentorSessionLogFormScreenState
    extends State<MentorSessionLogFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final MentorSessionLogFormController _controller;

  @override
  void initState() {
    super.initState();
    _controller = MentorSessionLogFormController()..addListener(_rebuild);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_rebuild)
      ..dispose();
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (widget.message != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }

        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(widget.message!)));

        widget.clearMessage();
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Log a session'),
        leading: BackButton(onPressed: widget.onCancel),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              MentorSessionCourseDateSection(
                controller: _controller,
                courses: widget.courses,
                selectedCourseId: widget.selectedCourseId,
                isLoading: widget.isLoading,
                isSaving: widget.isSaving,
                onCourseSelected: widget.onCourseSelected,
                onSelectDate: _selectDate,
              ),
              const SizedBox(height: 32),
              MentorSessionMentorsSection(
                controller: _controller,
                mentors: widget.mentors,
                selectedCourseId: widget.selectedCourseId,
                selectedTeachingMentorIds: widget.selectedTeachingMentorIds,
                selectedSupportingMentorIds: widget.selectedSupportingMentorIds,
                isLoading: widget.isLoading,
                isSaving: widget.isSaving,
                onToggleTeachingMentor: widget.onToggleTeachingMentor,
                onToggleSupportingMentor: widget.onToggleSupportingMentor,
                onClearMentors: widget.onClearMentors,
              ),
              const SizedBox(height: 32),
              MentorSessionProjectSection(
                controller: _controller,
                isSaving: widget.isSaving,
              ),
              const SizedBox(height: 32),
              MentorSessionAttendanceSection(
                controller: _controller,
                students: widget.students,
                selectedCourseId: widget.selectedCourseId,
                selectedStudentIds: widget.selectedStudentIds,
                isLoading: widget.isLoading,
                isSaving: widget.isSaving,
                onToggleStudent: widget.onToggleStudent,
                onSelectAllStudents: widget.onSelectAllStudents,
                onClearStudents: widget.onClearStudents,
              ),
              const SizedBox(height: 32),
              MentorSessionOutcomeSection(
                controller: _controller,
                isSaving: widget.isSaving,
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: widget.isSaving || widget.isLoading ? null : _submit,
                child: Text(
                  widget.isSaving ? 'Submitting...' : 'Submit session log',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _controller.date,
      firstDate: DateTime(2020),
      lastDate: DateUtils.dateOnly(DateTime.now()),
    );

    if (selected == null || !mounted) {
      return;
    }

    _controller.setDate(selected);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final request = _controller.buildRequest(
      courseId: widget.selectedCourseId,
      teachingMentorIds: widget.selectedTeachingMentorIds,
      supportingMentorIds: widget.selectedSupportingMentorIds,
      studentIds: widget.selectedStudentIds,
    );
    if (request == null) return;
    final submitted = await widget.onSubmit(request);

    if (submitted && mounted) {
      widget.onSubmitted();
    }
  }
}
