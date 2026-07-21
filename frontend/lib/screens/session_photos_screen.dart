import 'dart:io';

import 'package:flutter/material.dart';

import '../widgets/app_bar.dart';
import 'package:image_picker/image_picker.dart';

import '../models/models.dart';
import '../widgets/session_photo_gallery.dart';

class SessionPhotosScreen extends StatelessWidget {
  final String title;
  final List<SessionPhoto> photos;
  final List<XFile> selectedPhotos;

  final bool isLoading;
  final bool isSelecting;
  final bool isUploading;
  final bool showUploadControls;
  final bool alreadySubmitted;
  final bool canUpload;
  final String? message;

  final MentorNameResolver? mentorNameFor;
  final SessionPhotoTapCallback? onPhotoTap;

  final VoidCallback clearMessage;
  final Future<void> Function() onSelectPhotos;
  final VoidCallback onClearSelection;
  final Future<void> Function() onUpload;
  final VoidCallback onBack;

  const SessionPhotosScreen({
    required this.title,
    required this.photos,
    required this.selectedPhotos,
    required this.isLoading,
    required this.isSelecting,
    required this.isUploading,
    required this.showUploadControls,
    required this.alreadySubmitted,
    required this.canUpload,
    required this.message,
    required this.clearMessage,
    required this.onSelectPhotos,
    required this.onClearSelection,
    required this.onUpload,
    required this.onBack,
    this.mentorNameFor,
    this.onPhotoTap,
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
      appBar: AppTopBar(title: Text(title), onBack: onBack),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Text(
                    'Submitted photos',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  SessionPhotoGallery(
                    photos: photos,
                    mentorNameFor: mentorNameFor,
                    onPhotoTap: onPhotoTap,
                  ),
                  if (showUploadControls) ...[
                    const SizedBox(height: 32),
                    const Divider(),
                    const SizedBox(height: 24),
                    _UploadSection(
                      selectedPhotos: selectedPhotos,
                      isSelecting: isSelecting,
                      isUploading: isUploading,
                      alreadySubmitted: alreadySubmitted,
                      onSelectPhotos: onSelectPhotos,
                      onClearSelection: onClearSelection,
                    ),
                  ],
                ],
              ),
      ),
      bottomNavigationBar: showUploadControls && !alreadySubmitted
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton.icon(
                  onPressed: canUpload ? () => onUpload() : null,
                  icon: isUploading
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.cloud_upload),
                  label: Text(
                    isUploading ? 'Uploading...' : 'Upload three photos',
                  ),
                ),
              ),
            )
          : null,
    );
  }
}

class _UploadSection extends StatelessWidget {
  final List<XFile> selectedPhotos;
  final bool isSelecting;
  final bool isUploading;
  final bool alreadySubmitted;

  final Future<void> Function() onSelectPhotos;
  final VoidCallback onClearSelection;

  const _UploadSection({
    required this.selectedPhotos,
    required this.isSelecting,
    required this.isUploading,
    required this.alreadySubmitted,
    required this.onSelectPhotos,
    required this.onClearSelection,
  });

  @override
  Widget build(BuildContext context) {
    if (alreadySubmitted) {
      return const Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.check_circle_outline),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'You have already submitted three '
                  'photos for this session.',
                ),
              ),
            ],
          ),
        ),
      );
    }

    final busy = isSelecting || isUploading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Your photo submission',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        const Text('Select exactly three unedited photos.'),
        const SizedBox(height: 16),
        if (selectedPhotos.isNotEmpty) ...[
          _SelectedPhotoGrid(photos: selectedPhotos),
          const SizedBox(height: 16),
        ],
        OutlinedButton.icon(
          onPressed: busy ? null : () => onSelectPhotos(),
          icon: isSelecting
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.photo_library_outlined),
          label: Text(
            selectedPhotos.isEmpty
                ? 'Select three photos'
                : 'Replace selected photos',
          ),
        ),
        if (selectedPhotos.isNotEmpty)
          TextButton.icon(
            onPressed: busy ? null : onClearSelection,
            icon: const Icon(Icons.clear),
            label: const Text('Clear selection'),
          ),
      ],
    );
  }
}

class _SelectedPhotoGrid extends StatelessWidget {
  final List<XFile> photos;

  const _SelectedPhotoGrid({required this.photos});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: photos.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 3 / 2,
      ),
      itemBuilder: (context, index) {
        return Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                File(photos[index].path),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const ColoredBox(
                    color: Colors.black12,
                    child: Center(child: Icon(Icons.broken_image_outlined)),
                  );
                },
              ),
            ),
            Positioned(
              top: 6,
              left: 6,
              child: CircleAvatar(
                radius: 12,
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
