import 'package:flutter/material.dart';

import '../controllers/admin_course_management_controller.dart'
    show CourseStatusFilter;
import '../models/models.dart';

class AdminCourseManagementScreen extends StatelessWidget {
  final List<Course> courses;
  final CourseStatusFilter statusFilter;
  final int? selectedCourseId;
  final bool canEdit;
  final bool canAssignMentors;
  final bool isLoading;
  final bool isSaving;
  final String? message;
  final VoidCallback clearMessage;
  final ValueChanged<CourseStatusFilter> onStatusFilterChanged;
  final ValueChanged<int> onSelectCourse;
  final VoidCallback onAdd;
  final VoidCallback onEdit;
  final VoidCallback onAssignMentors;
  final VoidCallback onHome;
  final VoidCallback onLogout;

  const AdminCourseManagementScreen({
    required this.courses,
    required this.statusFilter,
    required this.selectedCourseId,
    required this.canEdit,
    required this.canAssignMentors,
    required this.isLoading,
    required this.isSaving,
    required this.message,
    required this.clearMessage,
    required this.onStatusFilterChanged,
    required this.onSelectCourse,
    required this.onAdd,
    required this.onEdit,
    required this.onAssignMentors,
    required this.onHome,
    required this.onLogout,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (message != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(message!)));
        clearMessage();
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage courses'),
        actions: [
          TextButton(onPressed: onHome, child: const Text('Home')),
          TextButton(onPressed: onLogout, child: const Text('Logout')),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: SegmentedButton<CourseStatusFilter>(
                  segments: const [
                    ButtonSegment(
                      value: CourseStatusFilter.active,
                      label: Text('Active'),
                    ),
                    ButtonSegment(
                      value: CourseStatusFilter.all,
                      label: Text('All'),
                    ),
                    ButtonSegment(
                      value: CourseStatusFilter.inactive,
                      label: Text('Inactive'),
                    ),
                  ],
                  selected: {statusFilter},
                  onSelectionChanged: isLoading || isSaving
                      ? null
                      : (selection) {
                          onStatusFilterChanged(selection.first);
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
          child: Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: isLoading || isSaving ? null : onAdd,
                  icon: const Icon(Icons.add),
                  label: const Text('Add'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: canEdit && !isLoading && !isSaving ? onEdit : null,
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: canAssignMentors && !isLoading && !isSaving
                      ? onAssignMentors
                      : null,
                  icon: const Icon(Icons.group),
                  label: const Text('Mentors'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildList() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (courses.isEmpty) {
      return const Center(child: Text('No courses'));
    }

    return ListView.separated(
      itemCount: courses.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final course = courses[index];
        final selected = course.id == selectedCourseId;

        return ListTile(
          selected: selected,
          leading: Icon(
            selected ? Icons.radio_button_checked : Icons.radio_button_off,
          ),
          title: Text(course.name),
          subtitle: Text(
            '${course.mentorIds.length} mentors · '
            '${course.studentIds.length} students',
          ),
          trailing: course.active
              ? null
              : const Icon(Icons.block, semanticLabel: 'Inactive'),
          onTap: () => onSelectCourse(course.id),
        );
      },
    );
  }
}
