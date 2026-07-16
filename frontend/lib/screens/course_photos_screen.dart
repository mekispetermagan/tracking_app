import 'package:flutter/material.dart';

import '../models/models.dart';
import '../widgets/session_photo_gallery.dart';

class CoursePhotosScreen extends StatelessWidget {
  final String courseName;
  final List<SessionPhoto> photos;
  final bool isLoading;
  final String? message;

  final MentorNameResolver? mentorNameFor;
  final SessionPhotoTapCallback? onPhotoTap;

  final VoidCallback clearMessage;
  final VoidCallback onBack;

  const CoursePhotosScreen({
    required this.courseName,
    required this.photos,
    required this.isLoading,
    required this.message,
    required this.clearMessage,
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
      appBar: AppBar(
        title: Text('$courseName photos'),
        leading: BackButton(onPressed: onBack),
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  SessionPhotoGallery(
                    photos: photos,
                    emptyText: 'No photos submitted for this course.',
                    mentorNameFor: mentorNameFor,
                    onPhotoTap: onPhotoTap,
                  ),
                ],
              ),
      ),
    );
  }
}
