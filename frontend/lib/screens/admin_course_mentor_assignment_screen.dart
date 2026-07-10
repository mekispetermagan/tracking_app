import 'package:flutter/material.dart';

import '../controllers/admin_course_management_controller.dart'
    show CourseMentorStatusFilter;
import '../models/models.dart';

class AdminCourseMentorAssignmentScreen extends StatefulWidget {
  final Course? course;
  final List<Mentor> mentors;
  final Set<int> assignedMentorIds;
  final CourseMentorStatusFilter statusFilter;
  final bool isLoading;
  final bool isSaving;
  final String? message;
  final VoidCallback clearMessage;
  final ValueChanged<CourseMentorStatusFilter> onStatusFilterChanged;
  final void Function(int mentorId, bool assigned) onAssignmentChanged;
  final Future<bool> Function() onSave;
  final VoidCallback onCancel;

  const AdminCourseMentorAssignmentScreen({
    required this.course,
    required this.mentors,
    required this.assignedMentorIds,
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
  State<AdminCourseMentorAssignmentScreen> createState() =>
      _AdminCourseMentorAssignmentScreenState();
}

class _AdminCourseMentorAssignmentScreenState
    extends State<AdminCourseMentorAssignmentScreen> {
  late Set<int> _assignedMentorIds;

  @override
  void initState() {
    super.initState();
    _assignedMentorIds = widget.assignedMentorIds.toSet();
  }

  @override
  void didUpdateWidget(AdminCourseMentorAssignmentScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.course?.id != widget.course?.id) {
      _assignedMentorIds = widget.assignedMentorIds.toSet();
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
        title: const Text('Assign mentors'),
        leading: BackButton(onPressed: widget.onCancel),
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (widget.course != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    widget.course!.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: SegmentedButton<CourseMentorStatusFilter>(
                  segments: const [
                    ButtonSegment(
                      value: CourseMentorStatusFilter.active,
                      label: Text('Active'),
                    ),
                    ButtonSegment(
                      value: CourseMentorStatusFilter.all,
                      label: Text('All'),
                    ),
                    ButtonSegment(
                      value: CourseMentorStatusFilter.inactive,
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
            onPressed: widget.isLoading || widget.isSaving ? null : _save,
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

    if (widget.mentors.isEmpty) {
      return const Center(child: Text('No mentors'));
    }

    return ListView.separated(
      itemCount: widget.mentors.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final mentor = widget.mentors[index];
        final assigned = _assignedMentorIds.contains(mentor.id);

        return CheckboxListTile(
          value: assigned,
          title: Text(mentor.fullName),
          subtitle: Text(mentor.phone),
          secondary: mentor.active
              ? null
              : const Icon(Icons.block, semanticLabel: 'Inactive'),
          onChanged: widget.isSaving
              ? null
              : (value) {
                  final newValue = value ?? false;

                  setState(() {
                    if (newValue) {
                      _assignedMentorIds.add(mentor.id);
                    } else {
                      _assignedMentorIds.remove(mentor.id);
                    }
                  });

                  widget.onAssignmentChanged(mentor.id, newValue);
                },
        );
      },
    );
  }

  Future<void> _save() async {
    final success = await widget.onSave();

    if (!mounted || !success) {
      return;
    }
  }
}
