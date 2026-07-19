import 'package:flutter/material.dart';

import '../models/models.dart';
import 'photo_viewer.dart';

typedef MentorNameResolver = String Function(int mentorProfileId);
typedef SessionPhotoTapCallback = void Function(SessionPhoto photo);

class SessionPhotoGallery extends StatelessWidget {
  final List<SessionPhoto> photos;
  final String emptyText;
  final MentorNameResolver? mentorNameFor;
  final SessionPhotoTapCallback? onPhotoTap;

  const SessionPhotoGallery({
    required this.photos,
    this.emptyText = 'No photos submitted.',
    this.mentorNameFor,
    this.onPhotoTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (photos.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(emptyText),
        ),
      );
    }

    final resolver = mentorNameFor;

    if (resolver == null) {
      final orderedPhotos = _sortedPhotos(photos);

      return _PhotoGrid(
        photos: orderedPhotos,
        viewerPhotos: orderedPhotos,
        onPhotoTap: onPhotoTap,
      );
    }

    final photosByMentor = <int, List<SessionPhoto>>{};

    for (final photo in photos) {
      photosByMentor.putIfAbsent(photo.mentorProfileId, () => []).add(photo);
    }

    final mentorIds = photosByMentor.keys.toList()
      ..sort((a, b) => resolver(a).compareTo(resolver(b)));

    final sortedPhotosByMentor = {
      for (final mentorId in mentorIds)
        mentorId: _sortedPhotos(photosByMentor[mentorId]!),
    };

    final orderedPhotos = [
      for (final mentorId in mentorIds) ...sortedPhotosByMentor[mentorId]!,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var index = 0; index < mentorIds.length; index++) ...[
          if (index > 0) const SizedBox(height: 24),
          Text(
            resolver(mentorIds[index]),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          _PhotoGrid(
            photos: sortedPhotosByMentor[mentorIds[index]]!,
            viewerPhotos: orderedPhotos,
            onPhotoTap: onPhotoTap,
          ),
        ],
      ],
    );
  }

  List<SessionPhoto> _sortedPhotos(List<SessionPhoto> source) {
    final result = List<SessionPhoto>.from(source);

    result.sort((a, b) {
      final sessionComparison = a.sessionLogId.compareTo(b.sessionLogId);
      if (sessionComparison != 0) return sessionComparison;

      final mentorComparison = a.mentorProfileId.compareTo(b.mentorProfileId);
      if (mentorComparison != 0) return mentorComparison;

      return a.photoNumber.compareTo(b.photoNumber);
    });

    return result;
  }
}

class _PhotoGrid extends StatelessWidget {
  final List<SessionPhoto> photos;
  final List<SessionPhoto> viewerPhotos;
  final SessionPhotoTapCallback? onPhotoTap;

  const _PhotoGrid({
    required this.photos,
    required this.viewerPhotos,
    required this.onPhotoTap,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: photos.length,
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 320,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 3 / 2,
      ),
      itemBuilder: (context, index) {
        final photo = photos[index];
        final viewerIndex = viewerPhotos.indexWhere(
          (candidate) => candidate.id == photo.id,
        );

        return _PhotoTile(
          photo: photo,
          onTap: () {
            onPhotoTap?.call(photo);
            showPhotoViewer(
              context: context,
              items: viewerPhotos.map(_viewerItemFor).toList(),
              initialIndex: viewerIndex < 0 ? 0 : viewerIndex,
            );
          },
        );
      },
    );
  }
}

class _PhotoTile extends StatelessWidget {
  final SessionPhoto photo;
  final VoidCallback onTap;

  const _PhotoTile({required this.photo, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        child: Image.network(
          photo.url,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;

            final expectedBytes = loadingProgress.expectedTotalBytes;
            final progress = expectedBytes == null
                ? null
                : loadingProgress.cumulativeBytesLoaded / expectedBytes;

            return Center(child: CircularProgressIndicator(value: progress));
          },
          errorBuilder: (context, error, stackTrace) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.broken_image_outlined),
                  SizedBox(height: 8),
                  Text('Photo unavailable'),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

PhotoViewerItem _viewerItemFor(SessionPhoto photo) {
  return PhotoViewerItem(
    imageUrl: photo.url,
    caption: '${_formatDate(photo.sessionDate)} · ${photo.mentorName}',
  );
}

String _formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day-$month-${date.year}';
}
