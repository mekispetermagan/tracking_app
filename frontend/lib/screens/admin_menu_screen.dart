import 'package:flutter/material.dart';

import '../widgets/app_bar.dart';
import '../controllers/area_controller.dart';
import '../controllers/admin_area_controller.dart';
import '../widgets/buttons.dart';

class AdminMenuScreen extends StatelessWidget {
  final List<AreaMenuItem<AdminScreen>> items;
  final ValueChanged<AdminScreen> onSelect;
  final VoidCallback onLogout;

  const AdminMenuScreen({
    required this.items,
    required this.onSelect,
    required this.onLogout,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTopBar(title: const Text('Admin menu'), onLogout: onLogout),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.all(24),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final item = items[index];

            return LargeFilledButton(
              onPressed: () => onSelect(item.screen),
              text: item.label,
            );
          },
        ),
      ),
    );
  }
}
