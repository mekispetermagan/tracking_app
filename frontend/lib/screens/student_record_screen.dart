import 'package:flutter/material.dart';

import '../widgets/app_bar.dart';

import '../models/models.dart';
import '../widgets/student_record_viewer.dart';

class StudentRecordScreen extends StatelessWidget {
  final StudentRecord? studentRecord;
  final bool isLoading;
  final String? message;

  final VoidCallback clearMessage;
  final VoidCallback onBack;

  const StudentRecordScreen({
    required this.studentRecord,
    required this.isLoading,
    required this.message,
    required this.clearMessage,
    required this.onBack,
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
      appBar: AppTopBar(title: const Text('Student record'), onBack: onBack),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final record = studentRecord;

    if (record == null) {
      return const Center(child: Text('Student record unavailable.'));
    }

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [StudentRecordViewer(studentRecord: record)],
    );
  }
}
