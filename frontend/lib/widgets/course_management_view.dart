import 'package:flutter/material.dart';

import 'app_bar.dart';

import '../controllers/management_types.dart';
import '../models/models.dart';

class CourseManagementView extends StatelessWidget {
  final List<Course> courses;
  final String title;
  final String Function(Course course) subtitleFor;
  final ActiveStatusFilter? statusFilter;
  final int? selectedCourseId;
  final bool canEdit;
  final bool canAssignMentors;
  final bool isLoading;
  final bool isSaving;
  final String? message;
  final VoidCallback clearMessage;
  final ValueChanged<ActiveStatusFilter>? onStatusFilterChanged;
  final ValueChanged<int> onSelectCourse;
  final VoidCallback? onAdd;
  final VoidCallback onEdit;
  final VoidCallback? onAssignMentors;
  final VoidCallback onHome;
  final VoidCallback onLogout;

  const CourseManagementView({
    required this.courses,
    required this.title,
    required this.subtitleFor,
    this.statusFilter,
    required this.selectedCourseId,
    required this.canEdit,
    this.canAssignMentors = false,
    required this.isLoading,
    required this.isSaving,
    required this.message,
    required this.clearMessage,
    this.onStatusFilterChanged,
    required this.onSelectCourse,
    this.onAdd,
    required this.onEdit,
    this.onAssignMentors,
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
      appBar: AppTopBar(title: Text(title), onHome: onHome, onLogout: onLogout),
      body: SafeArea(
        child: Column(
          children: [
            if (statusFilter != null && onStatusFilterChanged != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: SegmentedButton<ActiveStatusFilter>(
                    segments: const [
                      ButtonSegment(
                        value: ActiveStatusFilter.active,
                        label: Text('Active'),
                      ),
                      ButtonSegment(
                        value: ActiveStatusFilter.all,
                        label: Text('All'),
                      ),
                      ButtonSegment(
                        value: ActiveStatusFilter.inactive,
                        label: Text('Inactive'),
                      ),
                    ],
                    selected: {statusFilter!},
                    onSelectionChanged: isLoading || isSaving
                        ? null
                        : (selection) {
                            onStatusFilterChanged!(selection.first);
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
              if (onAdd != null) ...[
                Expanded(
                  child: FilledButton.icon(
                    onPressed: isLoading || isSaving ? null : onAdd,
                    icon: const Icon(Icons.add),
                    label: const Text('Add'),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: FilledButton.icon(
                  onPressed: canEdit && !isLoading && !isSaving ? onEdit : null,
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit'),
                ),
              ),
              if (onAssignMentors != null) ...[
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
        final subtitle = subtitleFor(course);

        return ListTile(
          selected: selected,
          leading: Icon(
            selected ? Icons.radio_button_checked : Icons.radio_button_off,
          ),
          title: Text(course.name),
          subtitle: Text(subtitle),
          isThreeLine: subtitle.contains('\n'),
          trailing: statusFilter != null && !course.active
              ? const Icon(Icons.block, semanticLabel: 'Inactive')
              : null,
          onTap: () => onSelectCourse(course.id),
        );
      },
    );
  }
}
