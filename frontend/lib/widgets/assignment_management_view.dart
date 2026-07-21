import 'package:flutter/material.dart';

import 'app_bar.dart';

import 'buttons.dart';

class AssignmentManagementView<TSubject, TItem, TFilter>
    extends StatefulWidget {
  final String title;
  final TSubject? subject;
  final Object Function(TSubject subject) subjectIdFor;
  final String Function(TSubject subject) subjectNameFor;
  final List<TItem> items;
  final Set<int> assignedItemIds;
  final TFilter statusFilter;
  final TFilter activeFilter;
  final TFilter allFilter;
  final TFilter inactiveFilter;
  final String emptyMessage;
  final int Function(TItem item) idFor;
  final String Function(TItem item) titleFor;
  final String Function(TItem item) subtitleFor;
  final bool Function(TItem item) isActiveFor;
  final bool isLoading;
  final bool isSaving;
  final String? message;
  final VoidCallback clearMessage;
  final ValueChanged<TFilter> onStatusFilterChanged;
  final void Function(int itemId, bool assigned) onAssignmentChanged;
  final Future<bool> Function() onSave;
  final VoidCallback onCancel;

  const AssignmentManagementView({
    required this.title,
    required this.subject,
    required this.subjectIdFor,
    required this.subjectNameFor,
    required this.items,
    required this.assignedItemIds,
    required this.statusFilter,
    required this.activeFilter,
    required this.allFilter,
    required this.inactiveFilter,
    required this.emptyMessage,
    required this.idFor,
    required this.titleFor,
    required this.subtitleFor,
    required this.isActiveFor,
    required this.isLoading,
    required this.isSaving,
    required this.message,
    required this.clearMessage,
    required this.onStatusFilterChanged,
    required this.onAssignmentChanged,
    required this.onSave,
    required this.onCancel,
    super.key,
  });

  @override
  State<AssignmentManagementView<TSubject, TItem, TFilter>> createState() =>
      _AssignmentManagementViewState<TSubject, TItem, TFilter>();
}

class _AssignmentManagementViewState<TSubject, TItem, TFilter>
    extends State<AssignmentManagementView<TSubject, TItem, TFilter>> {
  late Set<int> _assignedItemIds;

  @override
  void initState() {
    super.initState();
    _assignedItemIds = widget.assignedItemIds.toSet();
  }

  @override
  void didUpdateWidget(
    AssignmentManagementView<TSubject, TItem, TFilter> oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);

    final oldSubject = oldWidget.subject;
    final subject = widget.subject;
    final oldSubjectId = oldSubject == null
        ? null
        : oldWidget.subjectIdFor(oldSubject);
    final subjectId = subject == null ? null : widget.subjectIdFor(subject);

    if (oldSubjectId != subjectId) {
      _assignedItemIds = widget.assignedItemIds.toSet();
    }
  }

  @override
  Widget build(BuildContext context) {
    final subject = widget.subject;

    if (widget.message != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(widget.message!)));
        widget.clearMessage();
      });
    }

    return Scaffold(
      appBar: AppTopBar(title: Text(widget.title), onBack: widget.onCancel),
      body: SafeArea(
        child: Column(
          children: [
            if (subject != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    widget.subjectNameFor(subject),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: SegmentedButton<TFilter>(
                  segments: [
                    ButtonSegment(
                      value: widget.activeFilter,
                      label: const Text('Active'),
                    ),
                    ButtonSegment(
                      value: widget.allFilter,
                      label: const Text('All'),
                    ),
                    ButtonSegment(
                      value: widget.inactiveFilter,
                      label: const Text('Inactive'),
                    ),
                  ],
                  selected: {widget.statusFilter},
                  onSelectionChanged: widget.isLoading || widget.isSaving
                      ? null
                      : (selection) {
                          widget.onStatusFilterChanged(selection.first);
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
          child: LargeFilledButton(
            onPressed: widget.isLoading || widget.isSaving
                ? null
                : widget.onSave,
            child: Text(widget.isSaving ? 'Saving...' : 'Save assignments'),
          ),
        ),
      ),
    );
  }

  Widget _buildList() {
    if (widget.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (widget.items.isEmpty) {
      return Center(child: Text(widget.emptyMessage));
    }

    return ListView.separated(
      itemCount: widget.items.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = widget.items[index];
        final itemId = widget.idFor(item);
        final assigned = _assignedItemIds.contains(itemId);

        return CheckboxListTile(
          value: assigned,
          title: Text(widget.titleFor(item)),
          subtitle: Text(widget.subtitleFor(item)),
          secondary: widget.isActiveFor(item)
              ? null
              : const Icon(Icons.block, semanticLabel: 'Inactive'),
          onChanged: widget.isSaving
              ? null
              : (value) {
                  final newValue = value ?? false;

                  setState(() {
                    if (newValue) {
                      _assignedItemIds.add(itemId);
                    } else {
                      _assignedItemIds.remove(itemId);
                    }
                  });

                  widget.onAssignmentChanged(itemId, newValue);
                },
        );
      },
    );
  }
}
