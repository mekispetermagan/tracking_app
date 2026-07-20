import 'package:flutter/material.dart';

import '../widgets/app_bar.dart';

import '../controllers/mentor_area_controller.dart';
import '../widgets/buttons.dart';

class MentorMenuScreen extends StatelessWidget {
  final List<MentorMenuItem> items;
  final ValueChanged<MentorScreen> onSelect;
  final VoidCallback onLogout;

  const MentorMenuScreen({
    required this.items,
    required this.onSelect,
    required this.onLogout,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTopBar(title: const Text('Mentor menu'), onLogout: onLogout),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.all(24),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final item = items[index];

            return LargeFilledButton(
              text: item.label,
              onPressed: () => onSelect(item.screen),
            );
          },
        ),
      ),
    );
  }
}
