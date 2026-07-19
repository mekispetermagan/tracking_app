import 'package:flutter/material.dart';

import '../controllers/mentor_session_log_form_controller.dart';
import '../models/models.dart';

enum _MentorRole { teaching, supporting, absent }

class MentorSessionCourseDateSection extends StatelessWidget {
  final MentorSessionLogFormController controller;
  final List<Course> courses;
  final int? selectedCourseId;
  final bool isLoading;
  final bool isSaving;
  final Future<void> Function(int courseId) onCourseSelected;
  final VoidCallback onSelectDate;

  const MentorSessionCourseDateSection({
    required this.controller,
    required this.courses,
    required this.selectedCourseId,
    required this.isLoading,
    required this.isSaving,
    required this.onCourseSelected,
    required this.onSelectDate,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle('Course and date'),
        const SizedBox(height: 16),
        if (courses.isEmpty && !isLoading)
          const Text('No active courses available.')
        else ...[
          const Text('Course'),
          const SizedBox(height: 8),
          DropdownButtonFormField<int>(
            key: ValueKey(selectedCourseId),
            initialValue: selectedCourseId,
            items: courses.map((course) {
              return DropdownMenuItem(
                value: course.id,
                child: Text(course.name),
              );
            }).toList(),
            validator: (value) => value == null ? 'Select a course' : null,
            onChanged: isLoading || isSaving
                ? null
                : (courseId) async {
                    if (courseId == null) return;
                    controller.clearParticipantErrors();
                    await onCourseSelected(courseId);
                  },
          ),
        ],
        const SizedBox(height: 20),
        const Text('Date'),
        const SizedBox(height: 8),
        InkWell(
          onTap: isSaving ? null : onSelectDate,
          child: InputDecorator(
            decoration: const InputDecoration(
              suffixIcon: Icon(Icons.calendar_today),
            ),
            child: Text(_formatDate(controller.date)),
          ),
        ),
      ],
    );
  }
}

class MentorSessionMentorsSection extends StatelessWidget {
  final MentorSessionLogFormController controller;
  final List<SharedMentor> mentors;
  final int? selectedCourseId;
  final Set<int> selectedTeachingMentorIds;
  final Set<int> selectedSupportingMentorIds;
  final bool isLoading;
  final bool isSaving;
  final void Function(int mentorId) onToggleTeachingMentor;
  final void Function(int mentorId) onToggleSupportingMentor;
  final VoidCallback onClearMentors;

  const MentorSessionMentorsSection({
    required this.controller,
    required this.mentors,
    required this.selectedCourseId,
    required this.selectedTeachingMentorIds,
    required this.selectedSupportingMentorIds,
    required this.isLoading,
    required this.isSaving,
    required this.onToggleTeachingMentor,
    required this.onToggleSupportingMentor,
    required this.onClearMentors,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Mentors'),
        const SizedBox(height: 12),
        if (selectedCourseId == null)
          const Text('Select a course to load its mentors.')
        else if (isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (mentors.isEmpty)
          const Text('No active mentors are assigned to this course.')
        else ...[
          const Text(
            'Select each present mentor’s role. '
            'At least one teaching mentor is required.',
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              TextButton(
                onPressed: isSaving
                    ? null
                    : () {
                        controller.clearMentorError();
                        onClearMentors();
                      },
                child: const Text('Mark all absent'),
              ),
              const Spacer(),
              Text(
                '${selectedTeachingMentorIds.length} teaching, '
                '${selectedSupportingMentorIds.length} supporting',
              ),
            ],
          ),
          if (controller.mentorError != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                controller.mentorError!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ...mentors.map((mentor) {
            final role = _roleFor(mentor.id);

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mentor.fullName,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<_MentorRole>(
                    key: ValueKey((mentor.id, role)),
                    initialValue: role,
                    items: const [
                      DropdownMenuItem(
                        value: _MentorRole.teaching,
                        child: Text('Teaching'),
                      ),
                      DropdownMenuItem(
                        value: _MentorRole.supporting,
                        child: Text('Supporting'),
                      ),
                      DropdownMenuItem(
                        value: _MentorRole.absent,
                        child: Text('Absent'),
                      ),
                    ],
                    onChanged: isSaving || isLoading
                        ? null
                        : (value) {
                            if (value != null) _setRole(mentor.id, value);
                          },
                  ),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }

  _MentorRole _roleFor(int mentorId) {
    if (selectedTeachingMentorIds.contains(mentorId)) {
      return _MentorRole.teaching;
    }
    if (selectedSupportingMentorIds.contains(mentorId)) {
      return _MentorRole.supporting;
    }
    return _MentorRole.absent;
  }

  void _setRole(int mentorId, _MentorRole role) {
    final currentRole = _roleFor(mentorId);
    if (currentRole == role) return;
    controller.clearMentorError();

    if (role == _MentorRole.teaching) {
      onToggleTeachingMentor(mentorId);
    } else if (role == _MentorRole.supporting) {
      onToggleSupportingMentor(mentorId);
    } else if (currentRole == _MentorRole.teaching) {
      onToggleTeachingMentor(mentorId);
    } else if (currentRole == _MentorRole.supporting) {
      onToggleSupportingMentor(mentorId);
    }
  }
}

class MentorSessionProjectSection extends StatelessWidget {
  final MentorSessionLogFormController controller;
  final bool isSaving;

  const MentorSessionProjectSection({
    required this.controller,
    required this.isSaving,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Project'),
        const SizedBox(height: 16),
        const Text('Project name'),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller.projectTitleController,
          enabled: !isSaving,
          textInputAction: TextInputAction.next,
          validator: controller.requiredText,
        ),
        const SizedBox(height: 20),
        const Text('Project type'),
        const SizedBox(height: 8),
        DropdownButtonFormField<ProjectType>(
          initialValue: controller.projectType,
          items: ProjectType.values.map((type) {
            return DropdownMenuItem(value: type, child: Text(type.label));
          }).toList(),
          onChanged: isSaving
              ? null
              : (value) {
                  if (value != null) controller.setProjectType(value);
                },
        ),
        if (controller.projectType == ProjectType.other) ...[
          const SizedBox(height: 20),
          const Text('Specify project type'),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller.otherProjectTypeController,
            enabled: !isSaving,
            textInputAction: TextInputAction.next,
            validator: controller.requiredText,
          ),
        ],
        const SizedBox(height: 24),
        Text(
          'Skill-building games played',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        const Text('Optional. Select all that were played.'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: MentorSessionLogFormController.skillGames.map((game) {
            return FilterChip(
              label: Text(game),
              selected: controller.isGameSelected(game),
              onSelected: isSaving
                  ? null
                  : (selected) {
                      controller.setGameSelected(game, selected);
                    },
            );
          }).toList(),
        ),
      ],
    );
  }
}

class MentorSessionAttendanceSection extends StatelessWidget {
  final MentorSessionLogFormController controller;
  final List<Student> students;
  final int? selectedCourseId;
  final Set<int> selectedStudentIds;
  final bool isLoading;
  final bool isSaving;
  final void Function(int studentId) onToggleStudent;
  final VoidCallback onSelectAllStudents;
  final VoidCallback onClearStudents;

  const MentorSessionAttendanceSection({
    required this.controller,
    required this.students,
    required this.selectedCourseId,
    required this.selectedStudentIds,
    required this.isLoading,
    required this.isSaving,
    required this.onToggleStudent,
    required this.onSelectAllStudents,
    required this.onClearStudents,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Attendance'),
        const SizedBox(height: 12),
        if (selectedCourseId == null)
          const Text('Select a course to load its students.')
        else if (isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (students.isEmpty)
          const Text('No active students are assigned to this course.')
        else ...[
          Row(
            children: [
              TextButton(
                onPressed: isSaving
                    ? null
                    : () {
                        controller.clearAttendanceError();
                        onSelectAllStudents();
                      },
                child: const Text('Select all'),
              ),
              TextButton(
                onPressed: isSaving ? null : onClearStudents,
                child: const Text('Clear all'),
              ),
              const Spacer(),
              Text('${selectedStudentIds.length}/${students.length}'),
            ],
          ),
          if (controller.attendanceError != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                controller.attendanceError!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ...students.map((student) {
            return CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: selectedStudentIds.contains(student.id),
              title: Text('${student.firstName} ${student.lastName}'),
              onChanged: isSaving
                  ? null
                  : (_) {
                      controller.clearAttendanceError();
                      onToggleStudent(student.id);
                    },
            );
          }),
        ],
      ],
    );
  }
}

class MentorSessionOutcomeSection extends StatelessWidget {
  final MentorSessionLogFormController controller;
  final bool isSaving;

  const MentorSessionOutcomeSection({
    required this.controller,
    required this.isSaving,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Outcome and notes'),
        const SizedBox(height: 16),
        const Text('Completion'),
        const SizedBox(height: 8),
        DropdownButtonFormField<CompletionStatus>(
          initialValue: controller.completionStatus,
          items: CompletionStatus.values.map((status) {
            return DropdownMenuItem(value: status, child: Text(status.label));
          }).toList(),
          onChanged: isSaving
              ? null
              : (value) {
                  if (value != null) controller.setCompletionStatus(value);
                },
        ),
        const SizedBox(height: 20),
        _NotesField(
          label: 'What worked?',
          controller: controller.whatWorkedController,
          enabled: !isSaving,
        ),
        const SizedBox(height: 20),
        _NotesField(
          label: 'Challenges',
          controller: controller.challengesController,
          enabled: !isSaving,
        ),
        const SizedBox(height: 20),
        _NotesField(
          label: 'Next step',
          controller: controller.nextStepController,
          enabled: !isSaving,
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(title, style: Theme.of(context).textTheme.titleLarge);
  }
}

class _NotesField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool enabled;

  const _NotesField({
    required this.label,
    required this.controller,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          enabled: enabled,
          minLines: 2,
          maxLines: 4,
          textCapitalization: TextCapitalization.sentences,
        ),
      ],
    );
  }
}

String _formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day-$month-${date.year}';
}
