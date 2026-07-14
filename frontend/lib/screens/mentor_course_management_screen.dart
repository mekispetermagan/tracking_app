import 'package:flutter/material.dart';

import '../models/models.dart';

class MentorCourseManagementScreen extends StatelessWidget {
  final List<Course> courses;
  final int? selectedCourseId;
  final bool canEdit;
  final bool isLoading;
  final bool isSaving;
  final String? message;
  final VoidCallback clearMessage;
  final ValueChanged<int> onSelectCourse;
  final VoidCallback onEdit;
  final VoidCallback onHome;
  final VoidCallback onLogout;

  const MentorCourseManagementScreen({
    required this.courses,
    required this.selectedCourseId,
    required this.canEdit,
    required this.isLoading,
    required this.isSaving,
    required this.message,
    required this.clearMessage,
    required this.onSelectCourse,
    required this.onEdit,
    required this.onHome,
    required this.onLogout,
    super.key,
  });

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
        title: const Text('My courses'),
        actions: [
          TextButton(onPressed: onHome, child: const Text('Home')),
          TextButton(onPressed: onLogout, child: const Text('Logout')),
        ],
      ),
      body: SafeArea(child: _buildList()),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            onPressed: canEdit && !isLoading && !isSaving ? onEdit : null,
            icon: const Icon(Icons.edit),
            label: const Text('Edit'),
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
            '${_dayNames[course.dayOfWeek]} · '
            '${_displayTime(course.startTime)}\n'
            '${course.studentIds.length} students',
          ),
          isThreeLine: true,
          onTap: () => onSelectCourse(course.id),
        );
      },
    );
  }

  String _displayTime(String value) {
    final parts = value.split(':');

    if (parts.length < 2) {
      return value;
    }

    return '${parts[0]}:${parts[1]}';
  }
}
