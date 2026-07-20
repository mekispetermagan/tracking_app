import 'package:flutter/material.dart';

import '../widgets/app_bar.dart';

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
      appBar: AppTopBar(title: Text(title), onHome: onHome, onLogout: onLogout),
      body: SafeArea(child: Center(child: Text('$title placeholder'))),
    );
  }
}
