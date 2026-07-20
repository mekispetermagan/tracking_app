import 'package:flutter/material.dart';

import '../widgets/app_bar.dart';

import '../models/models.dart';
import '../widgets/course_visit_report_viewer.dart';

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
      appBar: AppTopBar(
        title: const Text('Course visits'),
        onHome: onHome,
        onLogout: onLogout,
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
                    child: CourseVisitReportViewer(
                      report: report,
                      mentorNameFor: mentorNameFor,
                      studentNameFor: studentNameFor,
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day-$month-${date.year}';
  }
}
