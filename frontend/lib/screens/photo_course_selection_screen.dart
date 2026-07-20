import 'package:flutter/material.dart';

import '../widgets/app_bar.dart';

import '../models/models.dart';

class PhotoCourseSelectionScreen extends StatelessWidget {
  final List<Course> courses;
  final int? selectedCourseId;
  final bool canView;
  final bool isLoading;
  final String? message;

  final VoidCallback clearMessage;
  final ValueChanged<int> onSelectCourse;
  final VoidCallback onView;
  final VoidCallback onHome;
  final Future<void> Function() onLogout;

  const PhotoCourseSelectionScreen({
    required this.courses,
    required this.selectedCourseId,
    required this.canView,
    required this.isLoading,
    required this.message,
    required this.clearMessage,
    required this.onSelectCourse,
    required this.onView,
    required this.onHome,
    required this.onLogout,
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
        title: const Text('View photos'),
        onHome: onHome,
        onLogout: onLogout,
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : courses.isEmpty
            ? const Center(child: Text('No courses available.'))
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: courses.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final course = courses[index];
                  final selected = course.id == selectedCourseId;

                  return Card(
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => onSelectCourse(course.id),
                      child: ListTile(
                        selected: selected,
                        leading: Icon(
                          selected
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                        ),
                        title: Text(course.name),
                        subtitle: course.description.isEmpty
                            ? null
                            : Text(course.description),
                      ),
                    ),
                  );
                },
              ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            onPressed: canView ? onView : null,
            icon: const Icon(Icons.photo_library_outlined),
            label: const Text('View course photos'),
          ),
        ),
      ),
    );
  }
}
