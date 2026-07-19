import 'package:flutter/material.dart';

import '../controllers/admin_student_management_controller.dart'
    show StudentStatusFilter;
import '../models/models.dart';

class StudentManagementView extends StatelessWidget {
  final List<Student> students;
  final List<Course> courses;
  final StudentStatusFilter? statusFilter;
  final int? courseIdFilter;
  final bool unassignedOnly;
  final int? selectedStudentId;
  final bool canEdit;
  final bool canAssignCourses;
  final bool isLoading;
  final bool isSaving;
  final String? message;
  final VoidCallback clearMessage;
  final ValueChanged<StudentStatusFilter>? onStatusFilterChanged;
  final ValueChanged<int?> onCourseFilterChanged;
  final VoidCallback? onUnassignedFilter;
  final ValueChanged<int> onSelectStudent;
  final VoidCallback onAdd;
  final VoidCallback onEdit;
  final VoidCallback? onAssignCourses;
  final VoidCallback onHome;
  final VoidCallback onLogout;

  const StudentManagementView({
    required this.students,
    required this.courses,
    this.statusFilter,
    required this.courseIdFilter,
    this.unassignedOnly = false,
    required this.selectedStudentId,
    required this.canEdit,
    this.canAssignCourses = false,
    required this.isLoading,
    required this.isSaving,
    required this.message,
    required this.clearMessage,
    this.onStatusFilterChanged,
    required this.onCourseFilterChanged,
    this.onUnassignedFilter,
    required this.onSelectStudent,
    required this.onAdd,
    required this.onEdit,
    this.onAssignCourses,
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
        title: const Text('Manage students'),
        actions: [
          TextButton(onPressed: onHome, child: const Text('Home')),
          TextButton(onPressed: onLogout, child: const Text('Logout')),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (statusFilter != null && onStatusFilterChanged != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: SegmentedButton<StudentStatusFilter>(
                    segments: const [
                      ButtonSegment(
                        value: StudentStatusFilter.active,
                        label: Text('Active'),
                      ),
                      ButtonSegment(
                        value: StudentStatusFilter.all,
                        label: Text('All'),
                      ),
                      ButtonSegment(
                        value: StudentStatusFilter.inactive,
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
            Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                statusFilter == null ? 16 : 0,
                16,
                16,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: isLoading || isSaving
                      ? null
                      : () => _showCourseFilter(context),
                  icon: const Icon(Icons.filter_list),
                  label: Text(_courseFilterLabel),
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
                  icon: const Icon(Icons.person_add),
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
              if (onAssignCourses != null) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: canAssignCourses && !isLoading && !isSaving
                        ? onAssignCourses
                        : null,
                    icon: const Icon(Icons.school),
                    label: const Text('Courses'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String get _courseFilterLabel {
    if (unassignedOnly) {
      return 'Unassigned';
    }

    final selectedId = courseIdFilter;

    if (selectedId == null) {
      return 'All courses';
    }

    for (final course in courses) {
      if (course.id == selectedId) {
        return course.name;
      }
    }

    return 'Course';
  }

  Widget _buildList() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (students.isEmpty) {
      return const Center(child: Text('No students'));
    }

    return ListView.separated(
      itemCount: students.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final student = students[index];
        final selected = student.id == selectedStudentId;

        final details = <String>[
          if (student.birthYear != null) student.birthYear.toString(),
          if (student.gender != null) _genderLabel(student.gender!),
          _courseLabel(student),
        ];

        return ListTile(
          selected: selected,
          leading: Icon(
            selected ? Icons.radio_button_checked : Icons.radio_button_off,
          ),
          title: Text(student.fullName),
          subtitle: Text(details.join(' · ')),
          trailing: student.active
              ? null
              : const Icon(Icons.block, semanticLabel: 'Inactive'),
          onTap: () => onSelectStudent(student.id),
        );
      },
    );
  }

  Future<void> _showCourseFilter(BuildContext context) async {
    var searchText = '';

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final query = searchText.trim().toLowerCase();

            final visibleCourses = courses.where((course) {
              return query.isEmpty || course.name.toLowerCase().contains(query);
            }).toList();

            return FractionallySizedBox(
              heightFactor: 0.9,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Filter by course',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: TextField(
                      autofocus: courses.length > 8,
                      decoration: const InputDecoration(
                        labelText: 'Search courses',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (value) {
                        setState(() {
                          searchText = value;
                        });
                      },
                    ),
                  ),
                  ListTile(
                    leading: Icon(
                      !unassignedOnly && courseIdFilter == null
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                    ),
                    title: const Text('All courses'),
                    onTap: () {
                      Navigator.pop(context);
                      onCourseFilterChanged(null);
                    },
                  ),
                  if (onUnassignedFilter != null)
                    ListTile(
                      leading: Icon(
                        unassignedOnly
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                      ),
                      title: const Text('Unassigned'),
                      onTap: () {
                        Navigator.pop(context);
                        onUnassignedFilter!();
                      },
                    ),
                  const Divider(height: 1),
                  Expanded(
                    child: visibleCourses.isEmpty
                        ? const Center(child: Text('No courses'))
                        : ListView.builder(
                            itemCount: visibleCourses.length,
                            itemBuilder: (context, index) {
                              final course = visibleCourses[index];
                              final selected =
                                  !unassignedOnly &&
                                  courseIdFilter == course.id;

                              return ListTile(
                                leading: Icon(
                                  selected
                                      ? Icons.radio_button_checked
                                      : Icons.radio_button_off,
                                ),
                                title: Text(course.name),
                                trailing: course.active
                                    ? null
                                    : const Icon(
                                        Icons.block,
                                        semanticLabel: 'Inactive',
                                      ),
                                onTap: () {
                                  Navigator.pop(context);
                                  onCourseFilterChanged(course.id);
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _genderLabel(String gender) {
    return switch (gender) {
      'M' => 'Male',
      'F' => 'Female',
      'N' => 'Other',
      _ => gender,
    };
  }

  String _courseLabel(Student student) {
    return switch (student.courseIds.length) {
      0 => 'no course',
      1 => _courseName(student.courseIds.first),
      final count => '$count courses',
    };
  }

  String _courseName(int courseId) {
    for (final course in courses) {
      if (course.id == courseId) {
        return course.name;
      }
    }

    return 'unknown course';
  }
}
