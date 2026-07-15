import 'package:flutter/material.dart';

import '../models/models.dart';

class SessionLogViewer extends StatelessWidget {
  final SessionLog sessionLog;
  final String courseName;
  final String? mentorName;
  final List<String> studentNames;

  const SessionLogViewer({
    required this.sessionLog,
    required this.courseName,
    required this.studentNames,
    this.mentorName,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _section(
          context,
          title: 'Session',
          children: [
            _valueRow('Course', courseName),
            _valueRow('Date', _formatDate(sessionLog.date)),
            if (mentorName != null) _valueRow('Mentor', mentorName!),
          ],
        ),
        const SizedBox(height: 24),
        _section(
          context,
          title: 'Project',
          children: [
            _valueRow('Project', sessionLog.projectTitle),
            _valueRow(
              'Type',
              sessionLog.projectType == ProjectType.other
                  ? sessionLog.otherProjectType ?? 'Other'
                  : sessionLog.projectType.label,
            ),
            _valueRow('Completion', sessionLog.completionStatus.label),
            if (_hasText(sessionLog.gamesPlayed))
              _valueRow('Skill-building games', sessionLog.gamesPlayed!),
          ],
        ),
        const SizedBox(height: 24),
        _buildAttendance(context),
        if (_hasAnyNotes) ...[
          const SizedBox(height: 24),
          _section(
            context,
            title: 'Outcome and notes',
            children: [
              if (_hasText(sessionLog.whatWorked))
                _textBlock(context, 'What worked', sessionLog.whatWorked!),
              if (_hasText(sessionLog.challenges))
                _textBlock(context, 'Challenges', sessionLog.challenges!),
              if (_hasText(sessionLog.nextStep))
                _textBlock(context, 'Next step', sessionLog.nextStep!),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildAttendance(BuildContext context) {
    return _section(
      context,
      title: 'Attendance (${studentNames.length})',
      children: [
        if (studentNames.isEmpty)
          const Text('No students recorded.')
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: studentNames
                .map((name) => Chip(label: Text(name)))
                .toList(),
          ),
      ],
    );
  }

  Widget _section(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _valueRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _textBlock(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 6),
          Text(value),
        ],
      ),
    );
  }

  bool get _hasAnyNotes =>
      _hasText(sessionLog.whatWorked) ||
      _hasText(sessionLog.challenges) ||
      _hasText(sessionLog.nextStep);

  bool _hasText(String? value) {
    return value != null && value.trim().isNotEmpty;
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day-$month-${date.year}';
  }
}
