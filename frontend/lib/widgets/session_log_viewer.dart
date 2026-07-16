import 'package:flutter/material.dart';

import '../models/models.dart';

class SessionLogViewer extends StatelessWidget {
  final SessionLog sessionLog;
  final String courseName;
  final String submittedByMentorName;
  final List<String> teachingMentorNames;
  final List<String> supportingMentorNames;
  final List<Student> students;
  final ValueChanged<int> onStudentSelected;

  const SessionLogViewer({
    required this.sessionLog,
    required this.courseName,
    required this.submittedByMentorName,
    required this.teachingMentorNames,
    required this.supportingMentorNames,
    required this.students,
    required this.onStudentSelected,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final projectType = sessionLog.projectType == ProjectType.other
        ? sessionLog.otherProjectType ?? 'Other'
        : sessionLog.projectType.label;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          sessionLog.projectTitle,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 24),
        _Section(
          title: 'Session',
          children: [
            _Field(label: 'Course', value: courseName),
            _Field(label: 'Date', value: _formatDate(sessionLog.date)),
            _Field(label: 'Project type', value: projectType),
            _Field(
              label: 'Completion',
              value: sessionLog.completionStatus.label,
            ),
            _Field(label: 'Submitted by', value: submittedByMentorName),
          ],
        ),
        const SizedBox(height: 16),
        _Section(
          title: 'Mentors',
          children: [
            _Field(
              label: 'Teaching',
              value: teachingMentorNames.isEmpty
                  ? 'None'
                  : teachingMentorNames.join(', '),
            ),
            _Field(
              label: 'Supporting',
              value: supportingMentorNames.isEmpty
                  ? 'None'
                  : supportingMentorNames.join(', '),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _Section(
          title: 'Students (${students.length})',
          children: [
            if (students.isEmpty)
              const Text('None')
            else
              for (final student in students)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.person_outline),
                  title: Text(
                    '${student.firstName} '
                    '${student.lastName}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => onStudentSelected(student.id),
                ),
          ],
        ),
        if (_hasText(sessionLog.gamesPlayed)) ...[
          const SizedBox(height: 16),
          _Section(
            title: 'Skill-building games',
            children: [Text(sessionLog.gamesPlayed!)],
          ),
        ],
        const SizedBox(height: 16),
        _Section(
          title: 'Outcome and notes',
          children: [
            _Field(
              label: 'What worked?',
              value: _textOrDash(sessionLog.whatWorked),
            ),
            _Field(
              label: 'Challenges',
              value: _textOrDash(sessionLog.challenges),
            ),
            _Field(label: 'Next step', value: _textOrDash(sessionLog.nextStep)),
          ],
        ),
      ],
    );
  }

  bool _hasText(String? value) {
    return value != null && value.trim().isNotEmpty;
  }

  String _textOrDash(String? value) {
    if (!_hasText(value)) {
      return '—';
    }

    return value!.trim();
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day-$month-${date.year}';
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final String value;

  const _Field({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 2),
          Text(value),
        ],
      ),
    );
  }
}
