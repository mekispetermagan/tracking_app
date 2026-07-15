import 'package:flutter/material.dart';

import '../models/models.dart';

class AdminViewSessionLogsScreen extends StatelessWidget {
  final List<SessionLog> sessionLogs;
  final List<Course> courses;
  final List<Mentor> mentors;

  final int? selectedSessionLogId;
  final int? courseIdFilter;
  final int? mentorIdFilter;
  final ProjectType? projectTypeFilter;

  final bool canView;
  final bool isLoading;
  final String? message;

  final String Function(SessionLog sessionLog) courseNameFor;

  final List<String> Function(SessionLog sessionLog) teachingMentorNamesFor;

  final VoidCallback clearMessage;
  final ValueChanged<int?> onCourseFilterChanged;
  final ValueChanged<int?> onMentorFilterChanged;
  final ValueChanged<ProjectType?> onProjectTypeFilterChanged;
  final VoidCallback onClearFilters;
  final ValueChanged<int> onSelectSessionLog;
  final VoidCallback onView;
  final VoidCallback onHome;
  final Future<void> Function() onLogout;

  const AdminViewSessionLogsScreen({
    required this.sessionLogs,
    required this.courses,
    required this.mentors,
    required this.selectedSessionLogId,
    required this.courseIdFilter,
    required this.mentorIdFilter,
    required this.projectTypeFilter,
    required this.canView,
    required this.isLoading,
    required this.message,
    required this.courseNameFor,
    required this.teachingMentorNamesFor,
    required this.clearMessage,
    required this.onCourseFilterChanged,
    required this.onMentorFilterChanged,
    required this.onProjectTypeFilterChanged,
    required this.onClearFilters,
    required this.onSelectSessionLog,
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
      appBar: AppBar(
        title: const Text('View session logs'),
        leading: IconButton(
          onPressed: onHome,
          icon: const Icon(Icons.home),
          tooltip: 'Home',
        ),
        actions: [
          IconButton(
            onPressed: onLogout,
            icon: const Icon(Icons.logout),
            tooltip: 'Log out',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildFilters(),
            const Divider(height: 1),
            Expanded(child: _buildList()),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            onPressed: canView ? onView : null,
            icon: const Icon(Icons.visibility),
            label: const Text('View selected log'),
          ),
        ),
      ),
    );
  }

  Widget _buildFilters() {
    final filtersActive =
        courseIdFilter != null ||
        mentorIdFilter != null ||
        projectTypeFilter != null;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          DropdownButtonFormField<int?>(
            key: ValueKey(('course', courseIdFilter)),
            initialValue: courseIdFilter,
            decoration: const InputDecoration(labelText: 'Course'),
            items: [
              const DropdownMenuItem<int?>(
                value: null,
                child: Text('All courses'),
              ),
              ...courses.map(
                (course) => DropdownMenuItem<int?>(
                  value: course.id,
                  child: Text(course.name),
                ),
              ),
            ],
            onChanged: isLoading ? null : onCourseFilterChanged,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int?>(
            key: ValueKey(('mentor', mentorIdFilter)),
            initialValue: mentorIdFilter,
            decoration: const InputDecoration(
              labelText: 'Participating mentor',
            ),
            items: [
              const DropdownMenuItem<int?>(
                value: null,
                child: Text('All mentors'),
              ),
              ...mentors.map(
                (mentor) => DropdownMenuItem<int?>(
                  value: mentor.id,
                  child: Text(
                    '${mentor.firstName} '
                    '${mentor.lastName}',
                  ),
                ),
              ),
            ],
            onChanged: isLoading ? null : onMentorFilterChanged,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<ProjectType?>(
            key: ValueKey(('projectType', projectTypeFilter)),
            initialValue: projectTypeFilter,
            decoration: const InputDecoration(labelText: 'Project type'),
            items: [
              const DropdownMenuItem<ProjectType?>(
                value: null,
                child: Text('All project types'),
              ),
              ...ProjectType.values.map(
                (type) => DropdownMenuItem<ProjectType?>(
                  value: type,
                  child: Text(type.label),
                ),
              ),
            ],
            onChanged: isLoading ? null : onProjectTypeFilterChanged,
          ),
          if (filtersActive) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onClearFilters,
                icon: const Icon(Icons.filter_alt_off),
                label: const Text('Clear filters'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildList() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (sessionLogs.isEmpty) {
      return const Center(child: Text('No session logs found.'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: sessionLogs.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final sessionLog = sessionLogs[index];
        final selected = sessionLog.id == selectedSessionLogId;

        final teachingNames = teachingMentorNamesFor(sessionLog);

        return Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => onSelectSessionLog(sessionLog.id),
            child: ListTile(
              selected: selected,
              leading: Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
              ),
              title: Text(sessionLog.projectTitle),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_formatDate(sessionLog.date)} · '
                    '${courseNameFor(sessionLog)}',
                  ),
                  Text(
                    'Teaching: '
                    '${teachingNames.join(', ')}',
                  ),
                  Text(
                    '${sessionLog.projectType.label} · '
                    '${sessionLog.completionStatus.label}',
                  ),
                ],
              ),
              trailing: Text(
                '${sessionLog.studentIds.length}\n'
                'students',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day-$month-${date.year}';
  }
}
