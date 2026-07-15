import 'package:flutter/material.dart';

import '../models/models.dart';
import '../widgets/session_log_viewer.dart';

class MentorViewSessionLogScreen extends StatelessWidget {
  final SessionLog sessionLog;
  final String courseName;
  final String submittedByMentorName;
  final List<String> teachingMentorNames;
  final List<String> supportingMentorNames;
  final List<String> studentNames;
  final VoidCallback onBack;

  const MentorViewSessionLogScreen({
    required this.sessionLog,
    required this.courseName,
    required this.submittedByMentorName,
    required this.teachingMentorNames,
    required this.supportingMentorNames,
    required this.studentNames,
    required this.onBack,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Session log'),
        leading: BackButton(onPressed: onBack),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            SessionLogViewer(
              sessionLog: sessionLog,
              courseName: courseName,
              submittedByMentorName: submittedByMentorName,
              teachingMentorNames: teachingMentorNames,
              supportingMentorNames: supportingMentorNames,
              studentNames: studentNames,
            ),
          ],
        ),
      ),
    );
  }
}
