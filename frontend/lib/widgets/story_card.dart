import 'package:flutter/material.dart';

import '../models/models.dart';
import 'photo_viewer.dart';

class StoryCard extends StatelessWidget {
  final Story story;
  final bool inactive;
  final Widget? footer;

  const StoryCard({
    required this.story,
    this.inactive = false,
    this.footer,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 3 / 2,
            child: InkWell(
              onTap: () {
                showPhotoViewer(
                  context: context,
                  items: [
                    PhotoViewerItem(
                      imageUrl: story.photo.url,
                      caption:
                          '${story.submitterName} · '
                          '${story.courseName} · '
                          '${_formatDate(story.createdAt)}',
                    ),
                  ],
                  showCounter: false,
                  controlIconSize: 32,
                  captionStyle: const TextStyle(color: Colors.white),
                );
              },
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    story.photo.url,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;

                      final expectedBytes = loadingProgress.expectedTotalBytes;
                      final progress = expectedBytes == null
                          ? null
                          : loadingProgress.cumulativeBytesLoaded /
                                expectedBytes;

                      return Center(
                        child: CircularProgressIndicator(value: progress),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.broken_image_outlined, size: 40),
                            SizedBox(height: 8),
                            Text('Photo unavailable'),
                          ],
                        ),
                      );
                    },
                  ),
                  if (inactive)
                    Container(
                      color: Colors.black45,
                      alignment: Alignment.center,
                      child: const Text(
                        'Inactive',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  if (story.isWinner)
                    const Positioned(top: 12, left: 12, child: _WinnerBadge()),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(story.text, style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: 16),
                _MetadataRow(
                  icon: Icons.person_outline,
                  text: story.submitterName,
                ),
                const SizedBox(height: 6),
                _MetadataRow(
                  icon: Icons.school_outlined,
                  text: story.courseName,
                ),
                const SizedBox(height: 6),
                _MetadataRow(
                  icon: Icons.calendar_today_outlined,
                  text: _formatDate(story.createdAt),
                ),
              ],
            ),
          ),
          if (footer != null) ...[
            const Divider(height: 1),
            Padding(padding: const EdgeInsets.all(12), child: footer!),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day-$month-${date.year}';
  }
}

class _WinnerBadge extends StatelessWidget {
  const _WinnerBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.emoji_events, color: Colors.amber, size: 20),
          SizedBox(width: 6),
          Text(
            'Story of the month',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _MetadataRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MetadataRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(text)),
      ],
    );
  }
}
