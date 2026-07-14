import 'package:flutter/material.dart';

import '../models/models.dart';

class MentorStudentManagementScreen extends StatelessWidget {
  final List<Student> students;
  final List<Course> courses;
  final int? courseIdFilter;
  final int? selectedStudentId;
  final bool canEdit;
  final bool isLoading;
  final bool isSaving;
  final String? message;
  final VoidCallback clearMessage;
  final ValueChanged<int?> onCourseFilterChanged;
  final ValueChanged<int> onSelectStudent;
  final VoidCallback onAdd;
  final VoidCallback onEdit;
  final VoidCallback onHome;
  final VoidCallback onLogout;

  const MentorStudentManagementScreen({
    required this.students,
    required this.courses,
    required this.courseIdFilter,
    required this.selectedStudentId,
    required this.canEdit,
    required this.isLoading,
    required this.isSaving,
    required this.message,
    required this.clearMessage,
    required this.onCourseFilterChanged,
    required this.onSelectStudent,
    required this.onAdd,
    required this.onEdit,
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
            Padding(
              padding: const EdgeInsets.all(16),
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
            ],
          ),
        ),
      ),
    );
  }

  String get _courseFilterLabel {
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
                      courseIdFilter == null
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                    ),
                    title: const Text('All courses'),
                    onTap: () {
                      Navigator.pop(context);
                      onCourseFilterChanged(null);
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
                              final selected = courseIdFilter == course.id;

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
