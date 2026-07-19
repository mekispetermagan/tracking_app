import 'package:flutter/material.dart';

import '../models/models.dart';

class AdminCourseVisitsScreen extends StatelessWidget {
  final List<CourseVisitReport> reports;
  final List<Course> courses;

  final int? selectedCourseId;
  final int? expandedReportId;

  final bool isLoading;
  final String? message;

  final String Function(CourseVisitReport report) courseNameFor;
  final String Function(int mentorId) mentorNameFor;
  final String Function(int studentId) studentNameFor;

  final VoidCallback clearMessage;
  final ValueChanged<int?> onCourseFilterChanged;
  final ValueChanged<int> onToggleReport;
  final Future<void> Function() onRefresh;
  final VoidCallback onSubmitReport;
  final VoidCallback onHome;
  final Future<void> Function() onLogout;

  const AdminCourseVisitsScreen({
    required this.reports,
    required this.courses,
    required this.selectedCourseId,
    required this.expandedReportId,
    required this.isLoading,
    required this.message,
    required this.courseNameFor,
    required this.mentorNameFor,
    required this.studentNameFor,
    required this.clearMessage,
    required this.onCourseFilterChanged,
    required this.onToggleReport,
    required this.onRefresh,
    required this.onSubmitReport,
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
        title: const Text('Course visits'),
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
            _buildFilter(),
            const Divider(height: 1),
            Expanded(child: _buildReports()),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: isLoading ? null : onSubmitReport,
        icon: const Icon(Icons.add),
        label: const Text('Submit report'),
      ),
    );
  }

  Widget _buildFilter() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: DropdownButtonFormField<int?>(
        key: ValueKey(selectedCourseId),
        initialValue: selectedCourseId,
        decoration: const InputDecoration(labelText: 'Course'),
        items: [
          const DropdownMenuItem<int?>(value: null, child: Text('All courses')),
          ...courses.map(
            (course) => DropdownMenuItem<int?>(
              value: course.id,
              child: Text(course.name),
            ),
          ),
        ],
        onChanged: isLoading ? null : onCourseFilterChanged,
      ),
    );
  }

  Widget _buildReports() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (reports.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 160),
            Center(child: Text('No course visit reports found.')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        itemCount: reports.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final report = reports[index];
          final expanded = report.id == expandedReportId;

          return Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                InkWell(
                  onTap: () => onToggleReport(report.id),
                  child: ListTile(
                    title: Text(courseNameFor(report)),
                    subtitle: Text(
                      '${_formatDate(report.date)} · '
                      '${report.sessionStatus.label}',
                    ),
                    leading: CircleAvatar(
                      child: Text('${report.courseHealthRating}'),
                    ),
                    trailing: Icon(
                      expanded ? Icons.expand_less : Icons.expand_more,
                    ),
                  ),
                ),
                if (expanded) ...[
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: _buildDetails(context, report),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetails(BuildContext context, CourseVisitReport report) {
    final interviewedStudents = report.students
        .where((student) => student.interviewed)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(context, 'Observation'),
        const SizedBox(height: 8),
        _detailRow('Session', report.sessionStatus.label),
        _detailRow('Teaching took place', report.teachingTookPlace.label),
        if (report.sessionFollowedPlan != null)
          _detailRow(
            'Followed a clear plan',
            report.sessionFollowedPlan!.label,
          ),
        if (report.learnerEngagement != null)
          _detailRow('Learner engagement', report.learnerEngagement!.label),
        if (report.equipmentAdequate != null)
          _detailRow('Equipment adequate', report.equipmentAdequate!.label),
        if (report.environmentStatus != null)
          _detailRow('Environment', report.environmentStatus!.label),
        _detailRow('Course health', '${report.courseHealthRating}/5'),
        const SizedBox(height: 16),
        _textSection('What happened', report.whatHappened),
        if (_hasText(report.mainStrength))
          _textSection('Main strength', report.mainStrength!),
        if (_hasText(report.mainProblem))
          _textSection('Main problem', report.mainProblem!),
        if (_hasText(report.supportProvided))
          _textSection('Support provided', report.supportProvided!),
        const SizedBox(height: 8),
        _sectionTitle(context, 'Mentors present'),
        const SizedBox(height: 8),
        if (report.mentors.isEmpty)
          const Text(
            'No assigned mentor was recorded '
            'as present.',
          )
        else
          ...report.mentors.map(
            (mentor) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                '${mentorNameFor(mentor.mentorId)} · '
                '${mentor.role?.label ?? 'Role not recorded'} · '
                '${mentor.performanceRating == null ? 'Not rated' : '${mentor.performanceRating}/5'}',
              ),
            ),
          ),
        const SizedBox(height: 16),
        _sectionTitle(
          context,
          'Students present '
          '(${report.students.length})',
        ),
        const SizedBox(height: 8),
        if (report.students.isEmpty)
          const Text(
            'No enrolled student was recorded '
            'as present.',
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: report.students.map((student) {
              return Chip(
                avatar: student.interviewed
                    ? const Icon(Icons.record_voice_over, size: 18)
                    : null,
                label: Text(studentNameFor(student.studentId)),
              );
            }).toList(),
          ),
        if (interviewedStudents.isNotEmpty) ...[
          const SizedBox(height: 20),
          _sectionTitle(context, 'Student interviews'),
          const SizedBox(height: 8),
          ...interviewedStudents.map(
            (student) => Card.outlined(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      studentNameFor(student.studentId),
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    _detailRow(
                      'Enjoys the course',
                      student.enjoyment?.label ?? 'Not recorded',
                    ),
                    _detailRow(
                      'Can explain learning',
                      student.learning?.label ?? 'Not recorded',
                    ),
                    _detailRow(
                      'Feels safe and respected',
                      student.feelsSafe?.label ?? 'Not recorded',
                    ),
                    if (_hasText(student.note)) ...[
                      const SizedBox(height: 6),
                      Text(student.note!),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),
        _sectionTitle(context, 'Follow-up actions'),
        const SizedBox(height: 8),
        if (report.actions.isEmpty)
          const Text('No follow-up action recorded.')
        else
          ...report.actions.map(
            (action) => Card.outlined(
              child: ListTile(
                leading: Icon(
                  action.completed ? Icons.check_circle : Icons.pending_actions,
                ),
                title: Text(action.category.label),
                subtitle: Text(
                  [
                    action.description,
                    if (_hasText(action.responsiblePerson))
                      'Responsible: '
                          '${action.responsiblePerson}',
                    if (action.targetDate != null)
                      'Target: '
                          '${_formatDate(action.targetDate!)}',
                  ].join('\n'),
                ),
              ),
            ),
          ),
        if (report.safeguardingConcern) ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Safeguarding concern',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                if (_hasText(report.safeguardingNote)) ...[
                  const SizedBox(height: 6),
                  Text(report.safeguardingNote!),
                ],
              ],
            ),
          ),
        ],
        const SizedBox(height: 12),
        Text(
          'Submitted '
          '${_formatDateTime(report.createdAt)}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Text(title, style: Theme.of(context).textTheme.titleMedium);
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 150, child: Text(label)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _textSection(String title, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(text),
        ],
      ),
    );
  }

  bool _hasText(String? value) {
    return value != null && value.trim().isNotEmpty;
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day-$month-${date.year}';
  }

  String _formatDateTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '${_formatDate(date)} '
        '$hour:$minute';
  }
}
