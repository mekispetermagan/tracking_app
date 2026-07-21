import 'dart:io';

import 'package:flutter/material.dart';

import '../widgets/app_bar.dart';
import 'package:image_picker/image_picker.dart';

import '../models/models.dart';
import '../widgets/buttons.dart';

class MentorStoryFormScreen extends StatefulWidget {
  final List<Course> courses;
  final int? selectedCourseId;
  final XFile? selectedPhoto;

  final bool isLoading;
  final bool isSelectingPhoto;
  final bool isSubmitting;
  final String? message;

  final VoidCallback clearMessage;
  final ValueChanged<int> onCourseSelected;
  final Future<void> Function() onSelectPhoto;
  final VoidCallback onClearPhoto;
  final Future<bool> Function(String text) onSubmit;

  final VoidCallback onSubmitted;
  final VoidCallback onCancel;

  const MentorStoryFormScreen({
    required this.courses,
    required this.selectedCourseId,
    required this.selectedPhoto,
    required this.isLoading,
    required this.isSelectingPhoto,
    required this.isSubmitting,
    required this.message,
    required this.clearMessage,
    required this.onCourseSelected,
    required this.onSelectPhoto,
    required this.onClearPhoto,
    required this.onSubmit,
    required this.onSubmitted,
    required this.onCancel,
    super.key,
  });

  @override
  State<MentorStoryFormScreen> createState() => _MentorStoryFormScreenState();
}

class _MentorStoryFormScreenState extends State<MentorStoryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.message != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }

        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(widget.message!)));

        widget.clearMessage();
      });
    }

    return Scaffold(
      appBar: AppTopBar(
        title: const Text('Submit story'),
        showBack: true,
        onBack: widget.isSubmitting ? null : widget.onCancel,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text('Course', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              _buildCourseField(),
              const SizedBox(height: 32),
              Text('Story', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              TextFormField(
                controller: _textController,
                enabled: !widget.isSubmitting,
                minLines: 6,
                maxLines: 12,
                textCapitalization: TextCapitalization.sentences,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Story text is required';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 32),
              Text('Photo', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              _buildPhotoSection(),
              const SizedBox(height: 32),
              LargeFilledButton(
                onPressed:
                    widget.isLoading ||
                        widget.isSelectingPhoto ||
                        widget.isSubmitting
                    ? null
                    : _submit,
                child: Text(
                  widget.isSubmitting ? 'Submitting...' : 'Submit story',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCourseField() {
    if (widget.courses.isEmpty && !widget.isLoading) {
      return const Text('No active courses available.');
    }

    return DropdownButtonFormField<int>(
      key: ValueKey(widget.selectedCourseId),
      initialValue: widget.selectedCourseId,
      items: widget.courses.map((course) {
        return DropdownMenuItem(value: course.id, child: Text(course.name));
      }).toList(),
      validator: (value) {
        if (value == null) {
          return 'Select a course';
        }

        return null;
      },
      onChanged: widget.isLoading || widget.isSubmitting
          ? null
          : (courseId) {
              if (courseId != null) {
                widget.onCourseSelected(courseId);
              }
            },
    );
  }

  Widget _buildPhotoSection() {
    final photo = widget.selectedPhoto;

    if (photo == null) {
      return OutlinedButton.icon(
        onPressed: widget.isSelectingPhoto || widget.isSubmitting
            ? null
            : widget.onSelectPhoto,
        icon: widget.isSelectingPhoto
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.add_photo_alternate_outlined),
        label: Text(widget.isSelectingPhoto ? 'Selecting...' : 'Select photo'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(
            File(photo.path),
            height: 240,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return const SizedBox(
                height: 180,
                child: Center(child: Text('Photo preview unavailable')),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: Text(photo.name, overflow: TextOverflow.ellipsis)),
            TextButton(
              onPressed: widget.isSubmitting ? null : widget.onSelectPhoto,
              child: const Text('Replace'),
            ),
            TextButton(
              onPressed: widget.isSubmitting ? null : widget.onClearPhoto,
              child: const Text('Remove'),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (widget.selectedPhoto == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Select a photo.')));
      return;
    }

    final submitted = await widget.onSubmit(_textController.text.trim());

    if (submitted && mounted) {
      widget.onSubmitted();
    }
  }
}
