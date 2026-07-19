import 'package:flutter/material.dart';

import '../controllers/controllers.dart';
import '../models/models.dart';

class AdminCourseVisitFormScreen extends StatefulWidget {
  final List<Course> courses;
  final List<Mentor> mentors;
  final List<Student> students;

  final int? initialCourseId;

  final bool isLoading;
  final bool isSaving;
  final String? message;

  final VoidCallback clearMessage;
  final Future<bool> Function(CourseVisitReportCreateRequest request) onSubmit;
  final VoidCallback onSubmitted;
  final VoidCallback onCancel;

  const AdminCourseVisitFormScreen({
    required this.courses,
    required this.mentors,
    required this.students,
    required this.initialCourseId,
    required this.isLoading,
    required this.isSaving,
    required this.message,
    required this.clearMessage,
    required this.onSubmit,
    required this.onSubmitted,
    required this.onCancel,
    super.key,
  });

  @override
  State<AdminCourseVisitFormScreen> createState() =>
      _AdminCourseVisitFormScreenState();
}

class _AdminCourseVisitFormScreenState
    extends State<AdminCourseVisitFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final AdminCourseVisitFormController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AdminCourseVisitFormController(
      courses: widget.courses,
      mentors: widget.mentors,
      students: widget.students,
      selectedCourseId: widget.initialCourseId,
    )..addListener(_rebuild);
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
        title: const Text('Submit course visit report'),
        leading: BackButton(onPressed: widget.onCancel),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              _sectionTitle('Course and date'),
              const SizedBox(height: 16),
              _buildCourseField(),
              const SizedBox(height: 20),
              _buildDateField(),
              const SizedBox(height: 32),

              _sectionTitle('Session observation'),
              const SizedBox(height: 16),
              _buildSessionObservation(),
              const SizedBox(height: 32),

              _sectionTitle('Mentors present'),
              const SizedBox(height: 12),
              _buildMentorSection(),
              const SizedBox(height: 32),

              _sectionTitle(
                'Students present '
                'and interviewed',
              ),
              const SizedBox(height: 12),
              _buildStudentSection(),
              const SizedBox(height: 32),

              _sectionTitle('Assessment and supervision'),
              const SizedBox(height: 16),
              _buildAssessmentSection(),
              const SizedBox(height: 32),

              _sectionTitle('Follow-up actions'),
              const SizedBox(height: 8),
              const Text(
                'Optional. Add each action '
                'separately.',
              ),
              const SizedBox(height: 12),
              _buildActionsSection(),
              const SizedBox(height: 32),

              _sectionTitle('Safeguarding'),
              const SizedBox(height: 8),
              _buildSafeguardingSection(),
              const SizedBox(height: 32),

              FilledButton(
                onPressed: widget.isSaving || widget.isLoading ? null : _submit,
                child: Text(
                  widget.isSaving ? 'Submitting...' : 'Submit report',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(title, style: Theme.of(context).textTheme.titleLarge);
  }

  Widget _buildCourseField() {
    if (widget.courses.isEmpty && !widget.isLoading) {
      return const Text('No courses available.');
    }

    return DropdownButtonFormField<int>(
      key: ValueKey(_controller.selectedCourseId),
      initialValue: _controller.selectedCourseId,
      decoration: const InputDecoration(labelText: 'Course'),
      items: widget.courses.map((course) {
        return DropdownMenuItem(value: course.id, child: Text(course.name));
      }).toList(),
      validator: (value) {
        return value == null ? 'Select a course' : null;
      },
      onChanged: widget.isLoading || widget.isSaving
          ? null
          : (courseId) {
              if (courseId == null) {
                return;
              }

              _controller.selectCourse(courseId);
            },
    );
  }

  Widget _buildDateField() {
    return InkWell(
      onTap: widget.isSaving ? null : _selectDate,
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Visit date',
          suffixIcon: Icon(Icons.calendar_today),
        ),
        child: Text(_formatDate(_controller.date)),
      ),
    );
  }

  Widget _buildSessionObservation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<CourseVisitSessionStatus>(
          initialValue: _controller.sessionStatus,
          decoration: const InputDecoration(labelText: 'Was the session held?'),
          items: CourseVisitSessionStatus.values.map((status) {
            return DropdownMenuItem(value: status, child: Text(status.label));
          }).toList(),
          onChanged: widget.isSaving
              ? null
              : (value) {
                  if (value == null) {
                    return;
                  }

                  _controller.setSessionStatus(value);
                },
        ),
        const SizedBox(height: 20),
        if (_controller.sessionWasHeld) ...[
          _answerField(
            label: 'Did teaching take place?',
            value: _controller.teachingTookPlace,
            onChanged: (value) {
              _controller.setTeachingTookPlace(value);
            },
          ),
          const SizedBox(height: 20),
          _answerField(
            label:
                'Did the session follow '
                'a clear plan?',
            value: _controller.sessionFollowedPlan,
            onChanged: (value) {
              _controller.setSessionFollowedPlan(value);
            },
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField<CourseVisitLearnerEngagement>(
            initialValue: _controller.learnerEngagement,
            decoration: const InputDecoration(labelText: 'Learner engagement'),
            items: CourseVisitLearnerEngagement.values.map((engagement) {
              return DropdownMenuItem(
                value: engagement,
                child: Text(engagement.label),
              );
            }).toList(),
            onChanged: widget.isSaving
                ? null
                : (value) {
                    if (value == null) {
                      return;
                    }

                    _controller.setLearnerEngagement(value);
                  },
          ),
          const SizedBox(height: 20),
          _answerField(
            label:
                'Were equipment and '
                'materials adequate?',
            value: _controller.equipmentAdequate,
            onChanged: (value) {
              _controller.setEquipmentAdequate(value);
            },
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField<CourseVisitEnvironmentStatus>(
            initialValue: _controller.environmentStatus,
            decoration: const InputDecoration(
              labelText: 'Learning environment',
            ),
            items: CourseVisitEnvironmentStatus.values.map((status) {
              return DropdownMenuItem(value: status, child: Text(status.label));
            }).toList(),
            onChanged: widget.isSaving
                ? null
                : (value) {
                    if (value == null) {
                      return;
                    }

                    _controller.setEnvironmentStatus(value);
                  },
          ),
        ] else
          const Text(
            'The remaining session '
            'observation questions '
            'do not apply.',
          ),
      ],
    );
  }

  Widget _answerField({
    required String label,
    required CourseVisitAnswer value,
    required ValueChanged<CourseVisitAnswer> onChanged,
  }) {
    return DropdownButtonFormField<CourseVisitAnswer>(
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      items: CourseVisitAnswer.values.map((answer) {
        return DropdownMenuItem(value: answer, child: Text(answer.label));
      }).toList(),
      onChanged: widget.isSaving
          ? null
          : (newValue) {
              if (newValue != null) {
                onChanged(newValue);
              }
            },
    );
  }

  Widget _buildMentorSection() {
    if (_controller.selectedCourse == null) {
      return const Text(
        'Select a course to show '
        'its mentors.',
      );
    }

    final mentors = _controller.courseMentors;

    if (mentors.isEmpty) {
      return const Text(
        'No mentors are assigned '
        'to this course.',
      );
    }

    return Column(
      children: mentors.map((mentor) {
        final state = _controller.mentorState(mentor.id);

        return Card.outlined(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mentor.fullName,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<CourseVisitMentorState>(
                  key: ValueKey((mentor.id, state)),
                  initialValue: state,
                  decoration: const InputDecoration(labelText: 'Role'),
                  items: const [
                    DropdownMenuItem(
                      value: CourseVisitMentorState.teaching,
                      child: Text('Teaching'),
                    ),
                    DropdownMenuItem(
                      value: CourseVisitMentorState.supporting,
                      child: Text('Supporting'),
                    ),
                    DropdownMenuItem(
                      value: CourseVisitMentorState.absent,
                      child: Text('Absent'),
                    ),
                  ],
                  onChanged: widget.isSaving
                      ? null
                      : (value) {
                          if (value == null) {
                            return;
                          }

                          _controller.setMentorState(mentor.id, value);
                        },
                ),
                if (state != CourseVisitMentorState.absent) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    key: ValueKey((
                      mentor.id,
                      _controller.mentorRating(mentor.id),
                    )),
                    initialValue: _controller.mentorRating(mentor.id),
                    decoration: const InputDecoration(labelText: 'Performance'),
                    items: List.generate(5, (index) {
                      final rating = index + 1;

                      return DropdownMenuItem(
                        value: rating,
                        child: Text(
                          '$rating – '
                          '${_mentorRatingLabel(rating)}',
                        ),
                      );
                    }),
                    onChanged: widget.isSaving
                        ? null
                        : (value) {
                            if (value == null) {
                              return;
                            }

                            _controller.setMentorRating(mentor.id, value);
                          },
                  ),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStudentSection() {
    if (_controller.selectedCourse == null) {
      return const Text(
        'Select a course to show '
        'its students.',
      );
    }

    final students = _controller.courseStudents;

    if (students.isEmpty) {
      return const Text(
        'No students are enrolled '
        'in this course.',
      );
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
                      _controller.selectAllStudentsPresent();
                    },
              child: const Text('Select all present'),
            ),
            TextButton(
              onPressed: widget.isSaving ? null : _controller.clearStudents,
              child: const Text('Clear'),
            ),
            const Spacer(),
            Text(
              '${_controller.presentStudentCount}'
              '/${students.length}',
            ),
          ],
        ),
        ...students.map((student) {
          final present = _controller.isStudentPresent(student.id);
          final interviewed = _controller.isStudentInterviewed(student.id);

          return Card.outlined(
            margin: const EdgeInsets.only(bottom: 10),
            child: Column(
              children: [
                CheckboxListTile(
                  value: present,
                  title: Text(student.fullName),
                  subtitle: const Text('Present'),
                  onChanged: widget.isSaving
                      ? null
                      : (value) {
                          _controller.setStudentPresent(
                            student.id,
                            value ?? false,
                          );
                        },
                ),
                if (present) ...[
                  const Divider(height: 1),
                  CheckboxListTile(
                    value: interviewed,
                    title: const Text('Interviewed'),
                    onChanged: widget.isSaving
                        ? null
                        : (value) {
                            _controller.setStudentInterviewed(
                              student.id,
                              value ?? false,
                            );
                          },
                  ),
                  if (interviewed)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: _buildInterviewFields(student.id),
                    ),
                ],
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildInterviewFields(int studentId) {
    final noteController = _controller.noteControllerFor(studentId);

    return Column(
      children: [
        DropdownButtonFormField<CourseVisitStudentEnjoyment>(
          initialValue: _controller.enjoymentFor(studentId),
          decoration: const InputDecoration(labelText: 'Enjoys the course'),
          items: CourseVisitStudentEnjoyment.values.map((answer) {
            return DropdownMenuItem(value: answer, child: Text(answer.label));
          }).toList(),
          onChanged: widget.isSaving
              ? null
              : (value) {
                  if (value != null) {
                    _controller.setStudentEnjoyment(studentId, value);
                  }
                },
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<CourseVisitStudentLearning>(
          initialValue: _controller.learningFor(studentId),
          decoration: const InputDecoration(
            labelText: 'Can explain something learned',
          ),
          items: CourseVisitStudentLearning.values.map((answer) {
            return DropdownMenuItem(value: answer, child: Text(answer.label));
          }).toList(),
          onChanged: widget.isSaving
              ? null
              : (value) {
                  if (value != null) {
                    _controller.setStudentLearning(studentId, value);
                  }
                },
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<CourseVisitStudentSafety>(
          initialValue: _controller.safetyFor(studentId),
          decoration: const InputDecoration(
            labelText: 'Feels safe and respected',
          ),
          items: CourseVisitStudentSafety.values.map((answer) {
            return DropdownMenuItem(value: answer, child: Text(answer.label));
          }).toList(),
          onChanged: widget.isSaving
              ? null
              : (value) {
                  if (value != null) {
                    _controller.setStudentSafety(studentId, value);
                  }
                },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: noteController,
          enabled: !widget.isSaving,
          decoration: const InputDecoration(labelText: 'Short interview note'),
          minLines: 2,
          maxLines: 3,
          maxLength: 500,
          textCapitalization: TextCapitalization.sentences,
        ),
      ],
    );
  }

  Widget _buildAssessmentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<int>(
          initialValue: _controller.courseHealthRating,
          decoration: const InputDecoration(labelText: 'Course health'),
          items: List.generate(5, (index) {
            final rating = index + 1;

            return DropdownMenuItem(
              value: rating,
              child: Text(
                '$rating – '
                '${_courseHealthLabel(rating)}',
              ),
            );
          }),
          onChanged: widget.isSaving
              ? null
              : (value) {
                  if (value != null) {
                    _controller.setCourseHealthRating(value);
                  }
                },
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: _controller.whatHappenedController,
          enabled: !widget.isSaving,
          decoration: const InputDecoration(labelText: 'What happened?'),
          minLines: 2,
          maxLines: 4,
          maxLength: 500,
          textCapitalization: TextCapitalization.sentences,
          validator: _controller.requiredText,
        ),
        const SizedBox(height: 20),
        _optionalTextField(
          controller: _controller.mainStrengthController,
          label: 'Main strength',
        ),
        const SizedBox(height: 20),
        _optionalTextField(
          controller: _controller.mainProblemController,
          label:
              'Main problem or '
              'improvement needed',
        ),
        const SizedBox(height: 20),
        _optionalTextField(
          controller: _controller.supportProvidedController,
          label:
              'Advice or practical '
              'help provided',
        ),
      ],
    );
  }

  Widget _optionalTextField({
    required TextEditingController controller,
    required String label,
  }) {
    return TextFormField(
      controller: controller,
      enabled: !widget.isSaving,
      decoration: InputDecoration(labelText: label),
      minLines: 2,
      maxLines: 4,
      maxLength: 500,
      textCapitalization: TextCapitalization.sentences,
    );
  }

  Widget _buildActionsSection() {
    return Column(
      children: [
        ..._controller.actions.asMap().entries.map((entry) {
          final index = entry.key;
          final action = entry.value;

          return Card.outlined(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Action ${index + 1}',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                      IconButton(
                        onPressed: widget.isSaving
                            ? null
                            : () => _controller.removeAction(index),
                        icon: const Icon(Icons.delete_outline),
                        tooltip: 'Remove action',
                      ),
                    ],
                  ),
                  DropdownButtonFormField<CourseVisitActionCategory>(
                    initialValue: action.category,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: CourseVisitActionCategory.values.map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(category.label),
                      );
                    }).toList(),
                    onChanged: widget.isSaving
                        ? null
                        : (value) {
                            if (value != null) {
                              _controller.setActionCategory(index, value);
                            }
                          },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: action.descriptionController,
                    enabled: !widget.isSaving,
                    decoration: const InputDecoration(
                      labelText: 'Specific action',
                    ),
                    maxLength: 500,
                    textCapitalization: TextCapitalization.sentences,
                    validator: _controller.requiredText,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: action.responsiblePersonController,
                    enabled: !widget.isSaving,
                    decoration: const InputDecoration(
                      labelText: 'Responsible person',
                    ),
                    maxLength: 100,
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: widget.isSaving
                        ? null
                        : () => _selectActionDate(action),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Target date',
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(
                        action.targetDate == null
                            ? 'Not set'
                            : _formatDate(action.targetDate!),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: widget.isSaving ? null : _controller.addAction,
            icon: const Icon(Icons.add),
            label: const Text('Add action'),
          ),
        ),
      ],
    );
  }

  Widget _buildSafeguardingSection() {
    return Column(
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: _controller.safeguardingConcern,
          title: const Text('Safeguarding concern'),
          onChanged: widget.isSaving
              ? null
              : (value) {
                  _controller.setSafeguardingConcern(value);
                },
        ),
        if (_controller.safeguardingConcern)
          TextFormField(
            controller: _controller.safeguardingNoteController,
            enabled: !widget.isSaving,
            decoration: const InputDecoration(
              labelText: 'Restricted safeguarding note',
            ),
            minLines: 3,
            maxLines: 5,
            maxLength: 1000,
            textCapitalization: TextCapitalization.sentences,
            validator: _controller.requiredText,
          ),
      ],
    );
  }

  Future<void> _selectDate() async {
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

  Future<void> _selectActionDate(CourseVisitActionDraft action) async {
    final initialDate =
        action.targetDate == null ||
            action.targetDate!.isBefore(_controller.date)
        ? _controller.date
        : action.targetDate!;

    final selected = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: _controller.date,
      lastDate: DateTime(_controller.date.year + 3, 12, 31),
    );

    if (selected == null || !mounted) {
      return;
    }

    _controller.setActionDate(action, selected);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final request = _controller.buildRequest();
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

  static String _mentorRatingLabel(int rating) {
    return switch (rating) {
      1 => 'Serious concern',
      2 => 'Needs substantial support',
      3 => 'Adequate',
      4 => 'Good',
      _ => 'Very strong',
    };
  }

  static String _courseHealthLabel(int rating) {
    return switch (rating) {
      1 => 'At risk',
      2 => 'Major problems',
      3 => 'Functioning',
      4 => 'Healthy',
      _ => 'Very strong',
    };
  }
}
