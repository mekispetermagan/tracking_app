import 'package:flutter/material.dart';

import '../models/models.dart';
import '../widgets/month_selector.dart';
import '../widgets/story_card.dart';

class AdminStoriesScreen extends StatelessWidget {
  final List<AdminStory> stories;
  final DateTime selectedMonth;
  final bool activeOnly;

  final bool isLoading;
  final int? savingStoryId;
  final bool isSelectingWinner;
  final String? message;

  final VoidCallback clearMessage;

  final Future<void> Function(DateTime month) onMonthChanged;
  final ValueChanged<bool> onActiveOnlyChanged;

  final ValueChanged<AdminStory> onEditStory;

  final Future<bool> Function(int storyId) onDeactivateStory;
  final Future<bool> Function(int storyId) onActivateStory;
  final Future<bool> Function(int storyId) onSelectWinner;

  final VoidCallback onViewWinners;
  final VoidCallback onBack;

  const AdminStoriesScreen({
    required this.stories,
    required this.selectedMonth,
    required this.activeOnly,
    required this.isLoading,
    required this.savingStoryId,
    required this.isSelectingWinner,
    required this.message,
    required this.clearMessage,
    required this.onMonthChanged,
    required this.onActiveOnlyChanged,
    required this.onEditStory,
    required this.onDeactivateStory,
    required this.onActivateStory,
    required this.onSelectWinner,
    required this.onViewWinners,
    required this.onBack,
    super.key,
  });

  bool get _isPastMonth {
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month);

    return selectedMonth.isBefore(currentMonth);
  }

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

    final busy = isLoading || savingStoryId != null || isSelectingWinner;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stories'),
        leading: BackButton(onPressed: onBack),
        actions: [
          IconButton(
            onPressed: onViewWinners,
            icon: const Icon(Icons.emoji_events),
            tooltip: 'Story of the month archive',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: MonthSelector(
                month: selectedMonth,
                enabled: !busy,
                onChanged: onMonthChanged,
              ),
            ),
            SwitchListTile(
              value: activeOnly,
              title: const Text('Show active stories only'),
              onChanged: busy ? null : onActiveOnlyChanged,
            ),
            const Divider(height: 1),
            Expanded(child: _buildBody(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (stories.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('No stories found for this month.'),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: stories.length,
      separatorBuilder: (_, _) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final story = stories[index];

        return StoryCard(
          story: story,
          inactive: !story.active,
          footer: _buildAdminFooter(context, story),
        );
      },
    );
  }

  Widget _buildAdminFooter(BuildContext context, AdminStory story) {
    final isSaving = savingStoryId == story.id;

    final ratingText = story.ratingCount == 0
        ? 'No ratings'
        : '${story.averageRating!.toStringAsFixed(2)} / 5'
              ' · ${story.ratingCount} '
              '${story.ratingCount == 1 ? 'rating' : 'ratings'}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              story.active
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(story.active ? 'Active' : 'Inactive'),
            const Spacer(),
            const Icon(Icons.star_outline, size: 18),
            const SizedBox(width: 6),
            Text(ratingText),
          ],
        ),
        const SizedBox(height: 12),
        if (isSaving)
          const Center(child: CircularProgressIndicator())
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  onEditStory(story);
                },
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit'),
              ),
              if (story.active)
                OutlinedButton.icon(
                  onPressed: () async {
                    final confirmed = await _confirmDeactivate(context, story);

                    if (confirmed) {
                      await onDeactivateStory(story.id);
                    }
                  },
                  icon: const Icon(Icons.visibility_off_outlined),
                  label: const Text('Deactivate'),
                )
              else
                OutlinedButton.icon(
                  onPressed: () {
                    onActivateStory(story.id);
                  },
                  icon: const Icon(Icons.visibility_outlined),
                  label: const Text('Activate'),
                ),
              if (_isPastMonth && story.active)
                FilledButton.icon(
                  onPressed: isSelectingWinner || story.isWinner
                      ? null
                      : () async {
                          final confirmed = await _confirmWinner(
                            context,
                            story,
                          );

                          if (confirmed) {
                            await onSelectWinner(story.id);
                          }
                        },
                  icon: const Icon(Icons.emoji_events),
                  label: Text(story.isWinner ? 'Winner' : 'Select winner'),
                ),
            ],
          ),
      ],
    );
  }

  Future<bool> _confirmDeactivate(
    BuildContext context,
    AdminStory story,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Deactivate story?'),
          content: Text(
            story.isWinner
                ? 'The story will be hidden and its '
                      'winner status will be removed.'
                : 'The story will be hidden from '
                      'mentors and the normal admin list.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: const Text('Deactivate'),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  Future<bool> _confirmWinner(BuildContext context, AdminStory story) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select story of the month?'),
          content: Text(
            '${story.submitterName} will become '
            'the winner for this month. Any existing '
            'winner will be replaced.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: const Text('Select winner'),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }
}
