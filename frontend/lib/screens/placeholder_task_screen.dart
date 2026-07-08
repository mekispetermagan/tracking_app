import 'package:flutter/material.dart';

class PlaceholderTaskScreen extends StatelessWidget {
  final String title;
  final VoidCallback onHome;
  final VoidCallback onLogout;

  const PlaceholderTaskScreen({
    required this.title,
    required this.onHome,
    required this.onLogout,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          TextButton(
            onPressed: onHome,
            child: const Text('Home'),
          ),
          TextButton(
            onPressed: onLogout,
            child: const Text('Logout'),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: Text('$title placeholder'),
        ),
      ),
    );
  }
}