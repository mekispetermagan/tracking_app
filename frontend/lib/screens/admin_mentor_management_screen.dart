import 'package:flutter/material.dart';

import '../widgets/app_bar.dart';

import '../controllers/admin_mentor_management_controller.dart'
    show MentorStatusFilter;
import '../models/models.dart';

class AdminMentorManagementScreen extends StatelessWidget {
  final List<Mentor> mentors;
  final MentorStatusFilter statusFilter;
  final int? selectedMentorId;
  final bool canEdit;
  final bool isLoading;
  final bool isSaving;
  final String? message;
  final VoidCallback clearMessage;
  final ValueChanged<MentorStatusFilter> onStatusFilterChanged;
  final ValueChanged<int> onSelectMentor;
  final VoidCallback onAdd;
  final VoidCallback onEdit;
  final VoidCallback onResetPin;
  final VoidCallback onHome;
  final VoidCallback onLogout;

  const AdminMentorManagementScreen({
    required this.mentors,
    required this.statusFilter,
    required this.selectedMentorId,
    required this.canEdit,
    required this.isLoading,
    required this.isSaving,
    required this.message,
    required this.clearMessage,
    required this.onStatusFilterChanged,
    required this.onSelectMentor,
    required this.onAdd,
    required this.onEdit,
    required this.onResetPin,
    required this.onHome,
    required this.onLogout,
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
      appBar: AppTopBar(
        title: const Text('Manage mentors'),
        onHome: onHome,
        onLogout: onLogout,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: SegmentedButton<MentorStatusFilter>(
                  segments: const [
                    ButtonSegment(
                      value: MentorStatusFilter.active,
                      label: Text('Active'),
                    ),
                    ButtonSegment(
                      value: MentorStatusFilter.all,
                      label: Text('All'),
                    ),
                    ButtonSegment(
                      value: MentorStatusFilter.inactive,
                      label: Text('Inactive'),
                    ),
                  ],
                  selected: {statusFilter},
                  onSelectionChanged: isLoading || isSaving
                      ? null
                      : (selection) {
                          onStatusFilterChanged(selection.first);
                        },
                ),
              ),
            ),
            Expanded(child: _buildList()),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: isLoading || isSaving ? null : onAdd,
                  icon: const Icon(Icons.person_add),
                  label: const Text('Add'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: canEdit && !isLoading && !isSaving ? onEdit : null,
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: canEdit && !isLoading && !isSaving
                      ? onResetPin
                      : null,
                  icon: const Icon(Icons.lock_reset),
                  label: const Text('PIN'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildList() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (mentors.isEmpty) {
      return const Center(child: Text('No mentors'));
    }

    return ListView.separated(
      itemCount: mentors.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final mentor = mentors[index];
        final selected = mentor.id == selectedMentorId;

        return ListTile(
          selected: selected,
          leading: Icon(
            selected ? Icons.radio_button_checked : Icons.radio_button_off,
          ),
          title: Text(mentor.fullName),
          subtitle: Text(mentor.phone),
          trailing: mentor.active
              ? null
              : const Icon(Icons.block, semanticLabel: 'Inactive'),
          onTap: () => onSelectMentor(mentor.id),
        );
      },
    );
  }
}
