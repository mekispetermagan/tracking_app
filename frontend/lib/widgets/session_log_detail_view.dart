import 'package:flutter/material.dart';

import 'app_bar.dart';

import '../models/models.dart';
import 'session_log_viewer.dart';
import 'buttons.dart';

class SessionLogDetailView extends StatelessWidget {
  final SessionLog sessionLog;
  final String courseName;
  final String submittedByMentorName;
  final List<String> teachingMentorNames;
  final List<String> supportingMentorNames;
  final List<Student> students;

  final ValueChanged<int> onStudentSelected;
  final VoidCallback onViewPhotos;
  final VoidCallback onBack;
  final String photoButtonLabel;

  const SessionLogDetailView({
    required this.sessionLog,
    required this.courseName,
    required this.submittedByMentorName,
    required this.teachingMentorNames,
    required this.supportingMentorNames,
    required this.students,
    required this.onStudentSelected,
    required this.onViewPhotos,
    required this.onBack,
    required this.photoButtonLabel,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTopBar(title: const Text('Session log'), onBack: onBack),
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
              students: students,
              onStudentSelected: onStudentSelected,
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: LargeFilledButton(
            onPressed: onViewPhotos,
            icon: const Icon(Icons.photo_library_outlined),
            text: photoButtonLabel,
          ),
          // child: FilledButton.icon(
          //   onPressed: onViewPhotos,
          //   icon: const Icon(Icons.photo_library_outlined),
          //   label: Text(photoButtonLabel),
          // ),
        ),
      ),
    );
  }
}
