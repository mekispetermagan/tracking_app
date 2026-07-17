import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

import '../models/models.dart';

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
                _showPhotoViewer(context);
              },
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    story.photo.url,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) {
                        return child;
                      }

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

  Future<void> _showPhotoViewer(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black,
      builder: (context) {
        return Dialog(
          insetPadding: EdgeInsets.zero,
          backgroundColor: Colors.black,
          child: SizedBox.expand(
            child: Stack(
              children: [
                Positioned.fill(
                  child: PhotoView(
                    imageProvider: NetworkImage(story.photo.url),
                    backgroundDecoration: const BoxDecoration(
                      color: Colors.black,
                    ),
                    initialScale: PhotoViewComputedScale.contained,
                    minScale: PhotoViewComputedScale.contained,
                    maxScale: PhotoViewComputedScale.covered * 4,
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.broken_image_outlined,
                              color: Colors.white,
                              size: 48,
                            ),
                            SizedBox(height: 12),
                            Text(
                              'Photo unavailable',
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: SafeArea(
                    child: Material(
                      color: Colors.black54,
                      shape: const CircleBorder(),
                      child: IconButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        icon: const Icon(Icons.close),
                        color: Colors.white,
                        iconSize: 32,
                        tooltip: 'Close',
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 16,
                  child: SafeArea(
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${story.submitterName} · '
                          '${story.courseName} · '
                          '${_formatDate(story.createdAt)}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
