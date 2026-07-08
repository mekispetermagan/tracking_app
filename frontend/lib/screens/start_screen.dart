import 'package:flutter/material.dart';

class StartScreen extends StatelessWidget {
  final VoidCallback onAdminLogin;
  final VoidCallback onMentorLogin;

  const StartScreen({
    required this.onAdminLogin,
    required this.onMentorLogin,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FilledButton(
                  onPressed: onMentorLogin,
                  child: const Text('Mentor login'),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: onAdminLogin,
                  child: const Text('Admin login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}