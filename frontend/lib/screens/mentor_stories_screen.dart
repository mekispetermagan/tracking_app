import 'package:flutter/material.dart';

import '../widgets/app_bar.dart';

import '../models/models.dart';
import '../widgets/month_selector.dart';
import '../widgets/story_card.dart';

class MentorStoriesScreen extends StatelessWidget {
  final List<MentorStory> stories;
  final DateTime selectedMonth;
  final int mentorProfileId;

  final bool isCurrentMonth;
  final bool hasSubmittedThisMonth;
  final bool isLoading;
  final int? ratingStoryId;
  final String? message;

  final VoidCallback clearMessage;
  final Future<void> Function(DateTime month) onMonthChanged;
  final Future<bool> Function(int storyId, int rating) onRateStory;

  final VoidCallback onSubmitStory;
  final VoidCallback onViewWinners;
  final VoidCallback onBack;

  const MentorStoriesScreen({
    required this.stories,
    required this.selectedMonth,
    required this.mentorProfileId,
    required this.isCurrentMonth,
    required this.hasSubmittedThisMonth,
    required this.isLoading,
    required this.ratingStoryId,
    required this.message,
    required this.clearMessage,
    required this.onMonthChanged,
    required this.onRateStory,
    required this.onSubmitStory,
    required this.onViewWinners,
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
      appBar: AppTopBar(
        title: const Text('Stories'),
        onBack: onBack,
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
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: MonthSelector(
                month: selectedMonth,
                enabled: !isLoading && ratingStoryId == null,
                onChanged: onMonthChanged,
              ),
            ),
            const Divider(height: 1),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            onPressed: isCurrentMonth && !hasSubmittedThisMonth && !isLoading
                ? onSubmitStory
                : null,
            icon: const Icon(Icons.add),
            label: Text(_submitButtonText()),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (stories.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('No stories submitted for this month.'),
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
          footer: _buildRatingFooter(context, story),
        );
      },
    );
  }

  Widget _buildRatingFooter(BuildContext context, MentorStory story) {
    final isOwnStory = story.submittedByMentorProfileId == mentorProfileId;

    if (isOwnStory) {
      return const Row(
        children: [
          Icon(Icons.person_outline),
          SizedBox(width: 8),
          Text('Your story'),
        ],
      );
    }

    final rating = story.myRating ?? 0;
    final isSaving = ratingStoryId == story.id;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          story.canRate
              ? 'Your rating'
              : story.myRating == null
              ? 'Not rated'
              : 'Your rating',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            for (var value = 1; value <= 5; value++)
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: '$value',
                onPressed: story.canRate && !isSaving
                    ? () {
                        onRateStory(story.id, value);
                      }
                    : null,
                icon: Icon(value <= rating ? Icons.star : Icons.star_border),
              ),
            if (isSaving) ...[
              const SizedBox(width: 8),
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ],
          ],
        ),
      ],
    );
  }

  String _submitButtonText() {
    if (!isCurrentMonth) {
      return 'Submission closed';
    }

    if (hasSubmittedThisMonth) {
      return 'Story submitted';
    }

    return 'Submit story';
  }
}
