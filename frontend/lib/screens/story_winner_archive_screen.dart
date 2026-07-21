import 'package:flutter/material.dart';

import '../widgets/app_bar.dart';

import '../models/models.dart';
import '../widgets/story_card.dart';

class StoryWinnerArchiveScreen extends StatelessWidget {
  final List<StoryWinner> winners;
  final bool isLoading;
  final String? message;

  final VoidCallback clearMessage;
  final VoidCallback onBack;

  const StoryWinnerArchiveScreen({
    required this.winners,
    required this.isLoading,
    required this.message,
    required this.clearMessage,
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
        title: const Text('Stories of the month'),
        onBack: onBack,
      ),
      body: SafeArea(child: _buildBody(context)),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (winners.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('No stories of the month selected yet.'),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: winners.length,
      separatorBuilder: (_, _) => const SizedBox(height: 24),
      itemBuilder: (context, index) {
        final winner = winners[index];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _formatMonth(winner.month),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            StoryCard(story: winner.story),
          ],
        );
      },
    );
  }

  String _formatMonth(DateTime date) {
    const monthNames = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return '${monthNames[date.month - 1]} '
        '${date.year}';
  }
}
