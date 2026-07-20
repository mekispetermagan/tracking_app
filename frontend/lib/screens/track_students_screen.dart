import 'package:flutter/material.dart';

import '../widgets/app_bar.dart';

import '../models/models.dart';

class TrackStudentsScreen extends StatelessWidget {
  final List<Student> students;
  final int? selectedStudentId;

  final bool canView;
  final bool isLoading;
  final String? message;

  final VoidCallback clearMessage;
  final ValueChanged<int> onSelectStudent;
  final VoidCallback onView;
  final VoidCallback onHome;
  final Future<void> Function() onLogout;

  const TrackStudentsScreen({
    required this.students,
    required this.selectedStudentId,
    required this.canView,
    required this.isLoading,
    required this.message,
    required this.clearMessage,
    required this.onSelectStudent,
    required this.onView,
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
      appBar: AppTopBar(
        title: const Text('Student records'),
        onHome: onHome,
        onLogout: onLogout,
      ),
      body: SafeArea(child: _buildBody()),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            onPressed: canView ? onView : null,
            icon: const Icon(Icons.assignment_outlined),
            label: const Text('View selected record'),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (students.isEmpty) {
      return const Center(child: Text('No students found.'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: students.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final student = students[index];
        final selected = student.id == selectedStudentId;

        return Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => onSelectStudent(student.id),
            child: ListTile(
              selected: selected,
              leading: Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
              ),
              title: Text(
                '${student.firstName} '
                '${student.lastName}',
              ),
            ),
          ),
        );
      },
    );
  }
}
