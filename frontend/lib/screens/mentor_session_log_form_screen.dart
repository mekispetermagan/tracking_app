import 'package:flutter/material.dart';

import '../controllers/controllers.dart';
import '../models/models.dart';

enum _MentorRole { teaching, supporting, absent }

class MentorSessionLogFormScreen extends StatefulWidget {
  final List<Course> courses;
  final List<Student> students;
  final List<SharedMentor> mentors;

  final int? selectedCourseId;
  final Set<int> selectedStudentIds;
  final Set<int> selectedTeachingMentorIds;
  final Set<int> selectedSupportingMentorIds;

  final bool isLoading;
  final bool isSaving;
  final String? message;

  final VoidCallback clearMessage;
  final Future<void> Function(int courseId) onCourseSelected;

  final void Function(int studentId) onToggleStudent;
  final VoidCallback onSelectAllStudents;
  final VoidCallback onClearStudents;

  final void Function(int mentorId) onToggleTeachingMentor;
  final void Function(int mentorId) onToggleSupportingMentor;
  final VoidCallback onClearMentors;

  final Future<bool> Function(SessionLogCreateRequest request) onSubmit;

  final VoidCallback onSubmitted;
  final VoidCallback onCancel;

  const MentorSessionLogFormScreen({
    required this.courses,
    required this.students,
    required this.mentors,
    required this.selectedCourseId,
    required this.selectedStudentIds,
    required this.selectedTeachingMentorIds,
    required this.selectedSupportingMentorIds,
    required this.isLoading,
    required this.isSaving,
    required this.message,
    required this.clearMessage,
    required this.onCourseSelected,
    required this.onToggleStudent,
    required this.onSelectAllStudents,
    required this.onClearStudents,
    required this.onToggleTeachingMentor,
    required this.onToggleSupportingMentor,
    required this.onClearMentors,
    required this.onSubmit,
    required this.onSubmitted,
    required this.onCancel,
    super.key,
  });

  @override
  State<MentorSessionLogFormScreen> createState() =>
      _MentorSessionLogFormScreenState();
}

class _MentorSessionLogFormScreenState
    extends State<MentorSessionLogFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final MentorSessionLogFormController _controller;

  @override
  void initState() {
    super.initState();
    _controller = MentorSessionLogFormController()..addListener(_rebuild);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_rebuild)
      ..dispose();
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
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
      appBar: AppBar(
        title: const Text('Log a session'),
        leading: BackButton(onPressed: widget.onCancel),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              _buildSectionTitle(context, 'Course and date'),
              const SizedBox(height: 16),
              _buildCourseField(),
              const SizedBox(height: 20),
              _buildDateField(context),
              const SizedBox(height: 32),

              _buildSectionTitle(context, 'Mentors'),
              const SizedBox(height: 12),
              _buildMentorSection(),
              const SizedBox(height: 32),

              _buildSectionTitle(context, 'Project'),
              const SizedBox(height: 16),
              const Text('Project name'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _controller.projectTitleController,
                enabled: !widget.isSaving,
                textInputAction: TextInputAction.next,
                validator: _controller.requiredText,
              ),
              const SizedBox(height: 20),
              const Text('Project type'),
              const SizedBox(height: 8),
              DropdownButtonFormField<ProjectType>(
                initialValue: _controller.projectType,
                items: ProjectType.values.map((type) {
                  return DropdownMenuItem(value: type, child: Text(type.label));
                }).toList(),
                onChanged: widget.isSaving
                    ? null
                    : (value) {
                        if (value == null) {
                          return;
                        }

                        _controller.setProjectType(value);
                      },
              ),
              if (_controller.projectType == ProjectType.other) ...[
                const SizedBox(height: 20),
                const Text('Specify project type'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _controller.otherProjectTypeController,
                  enabled: !widget.isSaving,
                  textInputAction: TextInputAction.next,
                  validator: _controller.requiredText,
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
              _buildGameChips(),
              const SizedBox(height: 32),

              _buildSectionTitle(context, 'Attendance'),
              const SizedBox(height: 12),
              _buildAttendanceSection(),
              const SizedBox(height: 32),

              _buildSectionTitle(context, 'Outcome and notes'),
              const SizedBox(height: 16),
              const Text('Completion'),
              const SizedBox(height: 8),
              DropdownButtonFormField<CompletionStatus>(
                initialValue: _controller.completionStatus,
                items: CompletionStatus.values.map((status) {
                  return DropdownMenuItem(
                    value: status,
                    child: Text(status.label),
                  );
                }).toList(),
                onChanged: widget.isSaving
                    ? null
                    : (value) {
                        if (value == null) {
                          return;
                        }

                        _controller.setCompletionStatus(value);
                      },
              ),
              const SizedBox(height: 20),
              const Text('What worked?'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _controller.whatWorkedController,
                enabled: !widget.isSaving,
                minLines: 2,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 20),
              const Text('Challenges'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _controller.challengesController,
                enabled: !widget.isSaving,
                minLines: 2,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 20),
              const Text('Next step'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _controller.nextStepController,
                enabled: !widget.isSaving,
                minLines: 2,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: widget.isSaving || widget.isLoading ? null : _submit,
                child: Text(
                  widget.isSaving ? 'Submitting...' : 'Submit session log',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(title, style: Theme.of(context).textTheme.titleLarge);
  }

  Widget _buildCourseField() {
    if (widget.courses.isEmpty && !widget.isLoading) {
      return const Text('No active courses available.');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Course'),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
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
          onChanged: widget.isLoading || widget.isSaving
              ? null
              : (courseId) async {
                  if (courseId == null) {
                    return;
                  }

                  _controller.clearParticipantErrors();

                  await widget.onCourseSelected(courseId);
                },
        ),
      ],
    );
  }

  Widget _buildDateField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Date'),
        const SizedBox(height: 8),
        InkWell(
          onTap: widget.isSaving ? null : () => _selectDate(context),
          child: InputDecorator(
            decoration: const InputDecoration(
              suffixIcon: Icon(Icons.calendar_today),
            ),
            child: Text(_formatDate(_controller.date)),
          ),
        ),
      ],
    );
  }

  Widget _buildMentorSection() {
    if (widget.selectedCourseId == null) {
      return const Text('Select a course to load its mentors.');
    }

    if (widget.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (widget.mentors.isEmpty) {
      return const Text('No active mentors are assigned to this course.');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select each present mentor’s role. '
          'At least one teaching mentor is required.',
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            TextButton(
              onPressed: widget.isSaving
                  ? null
                  : () {
                      _controller.clearMentorError();
                      widget.onClearMentors();
                    },
              child: const Text('Mark all absent'),
            ),
            const Spacer(),
            Text(
              '${widget.selectedTeachingMentorIds.length} '
              'teaching, '
              '${widget.selectedSupportingMentorIds.length} '
              'supporting',
            ),
          ],
        ),
        if (_controller.mentorError != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              _controller.mentorError!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ...widget.mentors.map((mentor) {
          final role = _mentorRoleFor(mentor.id);

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
                  onChanged: widget.isSaving || widget.isLoading
                      ? null
                      : (value) {
                          if (value == null) {
                            return;
                          }

                          _setMentorRole(mentor.id, value);
                        },
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  _MentorRole _mentorRoleFor(int mentorId) {
    if (widget.selectedTeachingMentorIds.contains(mentorId)) {
      return _MentorRole.teaching;
    }

    if (widget.selectedSupportingMentorIds.contains(mentorId)) {
      return _MentorRole.supporting;
    }

    return _MentorRole.absent;
  }

  void _setMentorRole(int mentorId, _MentorRole role) {
    final currentRole = _mentorRoleFor(mentorId);

    if (currentRole == role) {
      return;
    }

    _controller.clearMentorError();

    if (role == _MentorRole.teaching) {
      widget.onToggleTeachingMentor(mentorId);
      return;
    }

    if (role == _MentorRole.supporting) {
      widget.onToggleSupportingMentor(mentorId);
      return;
    }

    if (currentRole == _MentorRole.teaching) {
      widget.onToggleTeachingMentor(mentorId);
    } else if (currentRole == _MentorRole.supporting) {
      widget.onToggleSupportingMentor(mentorId);
    }
  }

  Widget _buildGameChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: MentorSessionLogFormController.skillGames.map((game) {
        return FilterChip(
          label: Text(game),
          selected: _controller.isGameSelected(game),
          onSelected: widget.isSaving
              ? null
              : (selected) {
                  _controller.setGameSelected(game, selected);
                },
        );
      }).toList(),
    );
  }

  Widget _buildAttendanceSection() {
    if (widget.selectedCourseId == null) {
      return const Text('Select a course to load its students.');
    }

    if (widget.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (widget.students.isEmpty) {
      return const Text('No active students are assigned to this course.');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            TextButton(
              onPressed: widget.isSaving
                  ? null
                  : () {
                      _controller.clearAttendanceError();
                      widget.onSelectAllStudents();
                    },
              child: const Text('Select all'),
            ),
            TextButton(
              onPressed: widget.isSaving ? null : widget.onClearStudents,
              child: const Text('Clear all'),
            ),
            const Spacer(),
            Text(
              '${widget.selectedStudentIds.length}'
              '/${widget.students.length}',
            ),
          ],
        ),
        if (_controller.attendanceError != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              _controller.attendanceError!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ...widget.students.map((student) {
          final selected = widget.selectedStudentIds.contains(student.id);

          return CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: selected,
            title: Text(
              '${student.firstName} '
              '${student.lastName}',
            ),
            onChanged: widget.isSaving
                ? null
                : (_) {
                    _controller.clearAttendanceError();
                    widget.onToggleStudent(student.id);
                  },
          );
        }),
      ],
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _controller.date,
      firstDate: DateTime(2020),
      lastDate: DateUtils.dateOnly(DateTime.now()),
    );

    if (selected == null || !mounted) {
      return;
    }

    _controller.setDate(selected);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final request = _controller.buildRequest(
      courseId: widget.selectedCourseId,
      teachingMentorIds: widget.selectedTeachingMentorIds,
      supportingMentorIds: widget.selectedSupportingMentorIds,
      studentIds: widget.selectedStudentIds,
    );
    if (request == null) return;
    final submitted = await widget.onSubmit(request);

    if (submitted && mounted) {
      widget.onSubmitted();
    }
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day-$month-${date.year}';
  }
}
