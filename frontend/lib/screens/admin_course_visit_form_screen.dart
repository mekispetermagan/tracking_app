import 'package:flutter/material.dart';

import '../controllers/controllers.dart';
import '../models/models.dart';
import '../widgets/admin_course_visit_form_sections.dart';
import '../widgets/buttons.dart';

class AdminCourseVisitFormScreen extends StatefulWidget {
  final List<Course> courses;
  final List<Mentor> mentors;
  final List<Student> students;

  final int? initialCourseId;

  final bool isLoading;
  final bool isSaving;
  final String? message;

  final VoidCallback clearMessage;
  final Future<bool> Function(CourseVisitReportCreateRequest request) onSubmit;
  final VoidCallback onSubmitted;
  final VoidCallback onCancel;

  const AdminCourseVisitFormScreen({
    required this.courses,
    required this.mentors,
    required this.students,
    required this.initialCourseId,
    required this.isLoading,
    required this.isSaving,
    required this.message,
    required this.clearMessage,
    required this.onSubmit,
    required this.onSubmitted,
    required this.onCancel,
    super.key,
  });

  @override
  State<AdminCourseVisitFormScreen> createState() =>
      _AdminCourseVisitFormScreenState();
}

class _AdminCourseVisitFormScreenState
    extends State<AdminCourseVisitFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final AdminCourseVisitFormController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AdminCourseVisitFormController(
      courses: widget.courses,
      mentors: widget.mentors,
      students: widget.students,
      selectedCourseId: widget.initialCourseId,
    )..addListener(_rebuild);
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
        title: const Text('Submit course visit report'),
        leading: BackButton(onPressed: widget.onCancel),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              CourseVisitCourseDateSection(
                controller: _controller,
                courses: widget.courses,
                isLoading: widget.isLoading,
                isSaving: widget.isSaving,
                onSelectDate: _selectDate,
              ),
              const SizedBox(height: 32),
              CourseVisitSessionObservationSection(
                controller: _controller,
                isSaving: widget.isSaving,
              ),
              const SizedBox(height: 32),
              CourseVisitMentorsSection(
                controller: _controller,
                isSaving: widget.isSaving,
              ),
              const SizedBox(height: 32),
              CourseVisitStudentsSection(
                controller: _controller,
                isSaving: widget.isSaving,
              ),
              const SizedBox(height: 32),
              CourseVisitAssessmentSection(
                controller: _controller,
                isSaving: widget.isSaving,
              ),
              const SizedBox(height: 32),
              CourseVisitActionsSection(
                controller: _controller,
                isSaving: widget.isSaving,
                onSelectActionDate: _selectActionDate,
              ),
              const SizedBox(height: 32),
              CourseVisitSafeguardingSection(
                controller: _controller,
                isSaving: widget.isSaving,
              ),
              const SizedBox(height: 32),

              LargeFilledButton(
                onPressed: widget.isSaving || widget.isLoading ? null : _submit,
                child: Text(
                  widget.isSaving ? 'Submitting...' : 'Submit report',
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

  Future<void> _selectActionDate(CourseVisitActionDraft action) async {
    final initialDate =
        action.targetDate == null ||
            action.targetDate!.isBefore(_controller.date)
        ? _controller.date
        : action.targetDate!;

    final selected = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: _controller.date,
      lastDate: DateTime(_controller.date.year + 3, 12, 31),
    );

    if (selected == null || !mounted) {
      return;
    }

    _controller.setActionDate(action, selected);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final request = _controller.buildRequest();
    if (request == null) return;
    final submitted = await widget.onSubmit(request);

    if (submitted && mounted) {
      widget.onSubmitted();
    }
  }
}
