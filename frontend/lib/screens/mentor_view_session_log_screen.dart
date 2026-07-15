import 'package:flutter/material.dart';

import '../models/models.dart';
import '../widgets/session_log_viewer.dart';

class MentorViewSessionLogScreen extends StatelessWidget {
  final SessionLog sessionLog;
  final String courseName;
  final List<String> studentNames;
  final VoidCallback onBack;

  const MentorViewSessionLogScreen({
    required this.sessionLog,
    required this.courseName,
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
              studentNames: studentNames,
            ),
          ],
        ),
      ),
    );
  }
}
