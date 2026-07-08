import 'package:flutter/material.dart';
import '../controllers/admin_area_controller.dart';

class AdminMenuScreen extends StatelessWidget {
  final List<AdminMenuItem> items;
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
      appBar: AppBar(
        title: const Text('Admin menu'),
        actions: [
          TextButton(
            onPressed: onLogout,
            child: const Text('Logout'),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.all(24),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final item = items[index];

            return FilledButton(
              onPressed: () => onSelect(item.screen),
              child: Text(item.label),
            );
          },
        ),
      ),
    );
  }
}