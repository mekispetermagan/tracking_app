import 'package:flutter/material.dart';

import '../controllers/admin_student_management_controller.dart'
    show StudentCourseStatusFilter;
import '../models/models.dart';

class AdminStudentCourseAssignmentScreen extends StatefulWidget {
  final Student? student;
  final List<Course> courses;
  final Set<int> assignedCourseIds;
  final StudentCourseStatusFilter statusFilter;
  final bool isLoading;
  final bool isSaving;
  final String? message;
  final VoidCallback clearMessage;
  final ValueChanged<StudentCourseStatusFilter> onStatusFilterChanged;
  final void Function(int courseId, bool assigned) onAssignmentChanged;
  final Future<bool> Function() onSave;
  final VoidCallback onCancel;

  const AdminStudentCourseAssignmentScreen({
    required this.student,
    required this.courses,
    required this.assignedCourseIds,
    required this.statusFilter,
    required this.isLoading,
    required this.isSaving,
    required this.message,
    required this.clearMessage,
    required this.onStatusFilterChanged,
    required this.onAssignmentChanged,
    required this.onSave,
    required this.onCancel,
    super.key,
  });

  @override
  State<AdminStudentCourseAssignmentScreen> createState() =>
      _AdminStudentCourseAssignmentScreenState();
}

class _AdminStudentCourseAssignmentScreenState
    extends State<AdminStudentCourseAssignmentScreen> {
  late Set<int> _assignedCourseIds;

  @override
  void initState() {
    super.initState();
    _assignedCourseIds = widget.assignedCourseIds.toSet();
  }

  @override
  void didUpdateWidget(AdminStudentCourseAssignmentScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.student?.id != widget.student?.id) {
      _assignedCourseIds = widget.assignedCourseIds.toSet();
    }
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
        title: const Text('Assign courses'),
        leading: BackButton(onPressed: widget.onCancel),
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (widget.student != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    widget.student!.fullName,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: SegmentedButton<StudentCourseStatusFilter>(
                  segments: const [
                    ButtonSegment(
                      value: StudentCourseStatusFilter.active,
                      label: Text('Active'),
                    ),
                    ButtonSegment(
                      value: StudentCourseStatusFilter.all,
                      label: Text('All'),
                    ),
                    ButtonSegment(
                      value: StudentCourseStatusFilter.inactive,
                      label: Text('Inactive'),
                    ),
                  ],
                  selected: {widget.statusFilter},
                  onSelectionChanged: widget.isLoading || widget.isSaving
                      ? null
                      : (selection) {
                          widget.onStatusFilterChanged(selection.first);
                        },
                ),
              ),
            ),
            Expanded(child: _buildList()),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            onPressed: widget.isLoading || widget.isSaving
                ? null
                : widget.onSave,
            child: Text(widget.isSaving ? 'Saving...' : 'Save assignments'),
          ),
        ),
      ),
    );
  }

  Widget _buildList() {
    if (widget.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (widget.courses.isEmpty) {
      return const Center(child: Text('No courses'));
    }

    return ListView.separated(
      itemCount: widget.courses.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final course = widget.courses[index];
        final assigned = _assignedCourseIds.contains(course.id);

        return CheckboxListTile(
          value: assigned,
          title: Text(course.name),
          subtitle: Text(
            '${course.mentorIds.length} mentors · '
            '${course.studentIds.length} students',
          ),
          secondary: course.active
              ? null
              : const Icon(Icons.block, semanticLabel: 'Inactive'),
          onChanged: widget.isSaving
              ? null
              : (value) {
                  final newValue = value ?? false;

                  setState(() {
                    if (newValue) {
                      _assignedCourseIds.add(course.id);
                    } else {
                      _assignedCourseIds.remove(course.id);
                    }
                  });

                  widget.onAssignmentChanged(course.id, newValue);
                },
        );
      },
    );
  }
}
