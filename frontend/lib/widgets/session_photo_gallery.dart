import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

import '../models/models.dart';

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

      if (sessionComparison != 0) {
        return sessionComparison;
      }

      final mentorComparison = a.mentorProfileId.compareTo(b.mentorProfileId);

      if (mentorComparison != 0) {
        return mentorComparison;
      }

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

            _showPhotoViewer(
              context: context,
              photos: viewerPhotos,
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
            if (loadingProgress == null) {
              return child;
            }

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

Future<void> _showPhotoViewer({
  required BuildContext context,
  required List<SessionPhoto> photos,
  required int initialIndex,
}) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black,
    builder: (context) {
      return Dialog(
        insetPadding: EdgeInsets.zero,
        backgroundColor: Colors.black,
        child: SizedBox.expand(
          child: _PhotoViewer(photos: photos, initialIndex: initialIndex),
        ),
      );
    },
  );
}

class _PhotoViewer extends StatefulWidget {
  final List<SessionPhoto> photos;
  final int initialIndex;

  const _PhotoViewer({required this.photos, required this.initialIndex});

  @override
  State<_PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<_PhotoViewer> {
  late final PageController _pageController;
  late final FocusNode _focusNode;

  late int _currentIndex;

  @override
  void initState() {
    super.initState();

    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _focusNode = FocusNode();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentPhoto = widget.photos[_currentIndex];

    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Material(
        color: Colors.black,
        child: Stack(
          children: [
            Positioned.fill(
              child: PhotoViewGallery.builder(
                itemCount: widget.photos.length,
                pageController: _pageController,
                backgroundDecoration: const BoxDecoration(color: Colors.black),
                scrollPhysics: const ClampingScrollPhysics(),
                gaplessPlayback: true,
                wantKeepAlive: true,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                loadingBuilder: (context, loadingProgress) {
                  final expectedBytes = loadingProgress?.expectedTotalBytes;

                  final progress =
                      loadingProgress == null || expectedBytes == null
                      ? null
                      : loadingProgress.cumulativeBytesLoaded / expectedBytes;

                  return Center(
                    child: CircularProgressIndicator(value: progress),
                  );
                },
                builder: (context, index) {
                  final photo = widget.photos[index];

                  return PhotoViewGalleryPageOptions(
                    imageProvider: NetworkImage(photo.url),
                    initialScale: PhotoViewComputedScale.contained,
                    minScale: PhotoViewComputedScale.contained,
                    maxScale: PhotoViewComputedScale.covered * 4,
                    filterQuality: FilterQuality.high,
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
                  );
                },
              ),
            ),
            Positioned(
              top: 16,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_currentIndex + 1} / '
                      '${widget.photos.length}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: SafeArea(
                child: _ViewerButton(
                  icon: Icons.close,
                  tooltip: 'Close',
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
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
                      '${_formatDate(currentPhoto.sessionDate)}'
                      ' · ${currentPhoto.mentorName}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ),
              ),
            ),
            if (widget.photos.length > 1) ...[
              Positioned(
                left: 12,
                top: 0,
                bottom: 0,
                child: Center(
                  child: _ViewerButton(
                    icon: Icons.chevron_left,
                    tooltip: 'Previous photo',
                    onPressed: _currentIndex > 0 ? _showPrevious : null,
                  ),
                ),
              ),
              Positioned(
                right: 12,
                top: 0,
                bottom: 0,
                child: Center(
                  child: _ViewerButton(
                    icon: Icons.chevron_right,
                    tooltip: 'Next photo',
                    onPressed: _currentIndex < widget.photos.length - 1
                        ? _showNext
                        : null,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }

    if (event.logicalKey == LogicalKeyboardKey.escape) {
      Navigator.of(context).pop();
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      _showPrevious();
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      _showNext();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  void _showPrevious() {
    if (_currentIndex <= 0) {
      return;
    }

    _pageController.previousPage(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  void _showNext() {
    if (_currentIndex >= widget.photos.length - 1) {
      return;
    }

    _pageController.nextPage(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day-$month-${date.year}';
  }
}

class _ViewerButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  const _ViewerButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54,
      shape: const CircleBorder(),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon),
        iconSize: 36,
        color: Colors.white,
        disabledColor: Colors.white24,
        tooltip: tooltip,
      ),
    );
  }
}
