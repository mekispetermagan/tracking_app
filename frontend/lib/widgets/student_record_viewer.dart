import 'package:flutter/material.dart';

import '../models/models.dart';

class StudentRecordViewer extends StatelessWidget {
  final StudentRecord studentRecord;

  const StudentRecordViewer({required this.studentRecord, super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          studentRecord.fullName,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                label: 'Attended sessions',
                value: studentRecord.attendedSessions.toString(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryCard(
                label: 'Activity score',
                value: _formatScore(studentRecord.overallActivityScore),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text('Project work', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        if (studentRecord.projectGroups.isEmpty)
          const _Section(child: Text('No project activity recorded.'))
        else
          ...studentRecord.projectGroups.map(
            (group) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ProjectGroupCard(group: group),
            ),
          ),
        const SizedBox(height: 12),
        Text(
          'Skill-building games',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        _Section(
          child: studentRecord.skillGames.isEmpty
              ? const Text('No skill-building games recorded.')
              : Column(
                  children: [
                    for (
                      var index = 0;
                      index < studentRecord.skillGames.length;
                      index++
                    ) ...[
                      _SkillGameRow(skillGame: studentRecord.skillGames[index]),
                      if (index < studentRecord.skillGames.length - 1)
                        const Divider(),
                    ],
                  ],
                ),
        ),
      ],
    );
  }

  static String _formatScore(double score) {
    if (score == score.roundToDouble()) {
      return score.toInt().toString();
    }

    return score.toStringAsFixed(1);
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
        child: Column(
          children: [
            Text(value, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 4),
            Text(label, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _ProjectGroupCard extends StatelessWidget {
  final StudentRecordProjectGroup group;

  const _ProjectGroupCard({required this.group});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    group.projectType.label,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Text(
                  'Score: ${StudentRecordViewer._formatScore(group.activityScore)}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${group.completedCount} completed · '
              '${group.partlyCompletedCount} partial · '
              '${group.notCompletedCount} not completed',
            ),
            const SizedBox(height: 12),
            const Divider(),
            for (var index = 0; index < group.projects.length; index++) ...[
              _ProjectRow(project: group.projects[index]),
              if (index < group.projects.length - 1) const Divider(),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProjectRow extends StatelessWidget {
  final StudentRecordProject project;

  const _ProjectRow({required this.project});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(project.projectTitle),
      subtitle: Text(_formatDate(project.date)),
      trailing: Text(
        project.completionStatus.label,
        textAlign: TextAlign.right,
      ),
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day-$month-${date.year}';
  }
}

class _SkillGameRow extends StatelessWidget {
  final StudentRecordSkillGame skillGame;

  const _SkillGameRow({required this.skillGame});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(skillGame.name),
      trailing: Text(
        skillGame.practiceCount.toString(),
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final Widget child;

  const _Section({required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    );
  }
}
