import 'package:flutter/material.dart';

import '../models/models.dart';

class MentorSessionLogFormScreen extends StatefulWidget {
  final List<Course> courses;
  final List<Student> students;
  final int? selectedCourseId;
  final Set<int> selectedStudentIds;

  final bool isLoading;
  final bool isSaving;
  final String? message;

  final VoidCallback clearMessage;
  final Future<void> Function(int courseId) onCourseSelected;
  final void Function(int studentId) onToggleStudent;
  final VoidCallback onSelectAllStudents;
  final VoidCallback onClearStudents;

  final Future<bool> Function(SessionLogCreateRequest request) onSubmit;
  final VoidCallback onSubmitted;
  final VoidCallback onCancel;

  const MentorSessionLogFormScreen({
    required this.courses,
    required this.students,
    required this.selectedCourseId,
    required this.selectedStudentIds,
    required this.isLoading,
    required this.isSaving,
    required this.message,
    required this.clearMessage,
    required this.onCourseSelected,
    required this.onToggleStudent,
    required this.onSelectAllStudents,
    required this.onClearStudents,
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
  static const _skillGames = [
    'Mixed letters',
    'Missing letters',
    'Reading game',
    'Bible game',
    'Shopping game',
    'Logic game',
    'Math train',
    'Number swarm',
    'Guess the operator',
    'Even odd game',
    'Balance game',
    'Word card memory',
    'Number card memory',
  ];

  final _formKey = GlobalKey<FormState>();

  final _projectTitleController = TextEditingController();
  final _otherProjectTypeController = TextEditingController();
  final _whatWorkedController = TextEditingController();
  final _challengesController = TextEditingController();
  final _nextStepController = TextEditingController();

  DateTime _date = DateUtils.dateOnly(DateTime.now());
  ProjectType _projectType = ProjectType.scratch;
  CompletionStatus _completionStatus = CompletionStatus.completed;

  final Set<String> _selectedGames = {};

  String? _attendanceError;

  @override
  void dispose() {
    _projectTitleController.dispose();
    _otherProjectTypeController.dispose();
    _whatWorkedController.dispose();
    _challengesController.dispose();
    _nextStepController.dispose();
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

              _buildSectionTitle(context, 'Project'),
              const SizedBox(height: 16),
              const Text('Project name'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _projectTitleController,
                enabled: !widget.isSaving,
                textInputAction: TextInputAction.next,
                validator: _required,
              ),
              const SizedBox(height: 20),
              const Text('Project type'),
              const SizedBox(height: 8),
              DropdownButtonFormField<ProjectType>(
                initialValue: _projectType,
                items: ProjectType.values.map((type) {
                  return DropdownMenuItem(value: type, child: Text(type.label));
                }).toList(),
                onChanged: widget.isSaving
                    ? null
                    : (value) {
                        if (value == null) {
                          return;
                        }

                        setState(() {
                          _projectType = value;

                          if (value != ProjectType.other) {
                            _otherProjectTypeController.clear();
                          }
                        });
                      },
              ),
              if (_projectType == ProjectType.other) ...[
                const SizedBox(height: 20),
                const Text('Specify project type'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _otherProjectTypeController,
                  enabled: !widget.isSaving,
                  textInputAction: TextInputAction.next,
                  validator: _required,
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
                initialValue: _completionStatus,
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

                        setState(() {
                          _completionStatus = value;
                        });
                      },
              ),
              const SizedBox(height: 20),
              const Text('What worked?'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _whatWorkedController,
                enabled: !widget.isSaving,
                minLines: 2,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 20),
              const Text('Challenges'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _challengesController,
                enabled: !widget.isSaving,
                minLines: 2,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 20),
              const Text('Next step'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nextStepController,
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

                  setState(() {
                    _attendanceError = null;
                  });

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
            child: Text(_formatDate(_date)),
          ),
        ),
      ],
    );
  }

  Widget _buildGameChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _skillGames.map((game) {
        return FilterChip(
          label: Text(game),
          selected: _selectedGames.contains(game),
          onSelected: widget.isSaving
              ? null
              : (selected) {
                  setState(() {
                    if (selected) {
                      _selectedGames.add(game);
                    } else {
                      _selectedGames.remove(game);
                    }
                  });
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
                      setState(() {
                        _attendanceError = null;
                      });
                      widget.onSelectAllStudents();
                    },
              child: const Text('Select all'),
            ),
            TextButton(
              onPressed: widget.isSaving
                  ? null
                  : () {
                      widget.onClearStudents();
                    },
              child: const Text('Clear all'),
            ),
            const Spacer(),
            Text(
              '${widget.selectedStudentIds.length}'
              '/${widget.students.length}',
            ),
          ],
        ),
        if (_attendanceError != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              _attendanceError!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ...widget.students.map((student) {
          final selected = widget.selectedStudentIds.contains(student.id);

          return CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: selected,
            title: Text('${student.firstName} ${student.lastName}'),
            onChanged: widget.isSaving
                ? null
                : (_) {
                    setState(() {
                      _attendanceError = null;
                    });
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
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateUtils.dateOnly(DateTime.now()),
    );

    if (selected == null || !mounted) {
      return;
    }

    setState(() {
      _date = DateUtils.dateOnly(selected);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final courseId = widget.selectedCourseId;

    if (courseId == null) {
      return;
    }

    if (widget.selectedStudentIds.isEmpty) {
      setState(() {
        _attendanceError = 'Select at least one student.';
      });
      return;
    }

    final studentIds = widget.selectedStudentIds.toList()..sort();
    final games = _selectedGames.toList()..sort();

    final submitted = await widget.onSubmit(
      SessionLogCreateRequest(
        courseId: courseId,
        date: _date,
        projectTitle: _projectTitleController.text.trim(),
        projectType: _projectType,
        otherProjectType: _projectType == ProjectType.other
            ? _otherProjectTypeController.text.trim()
            : null,
        gamesPlayed: games.isEmpty ? null : games.join(', '),
        completionStatus: _completionStatus,
        whatWorked: _optionalText(_whatWorkedController.text),
        challenges: _optionalText(_challengesController.text),
        nextStep: _optionalText(_nextStepController.text),
        studentIds: studentIds,
      ),
    );

    if (submitted && mounted) {
      widget.onSubmitted();
    }
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Required';
    }

    return null;
  }

  String? _optionalText(String value) {
    final text = value.trim();
    return text.isEmpty ? null : text;
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day-$month-${date.year}';
  }
}
