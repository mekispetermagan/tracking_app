import 'package:flutter/material.dart';

import '../models/models.dart';

enum _VisitMentorState { teaching, supporting, absent }

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

  final _whatHappenedController = TextEditingController();
  final _mainStrengthController = TextEditingController();
  final _mainProblemController = TextEditingController();
  final _supportProvidedController = TextEditingController();
  final _safeguardingNoteController = TextEditingController();

  int? _selectedCourseId;

  DateTime _date = DateUtils.dateOnly(DateTime.now());

  CourseVisitSessionStatus _sessionStatus = CourseVisitSessionStatus.fullyHeld;

  CourseVisitAnswer _teachingTookPlace = CourseVisitAnswer.yes;

  CourseVisitAnswer _sessionFollowedPlan = CourseVisitAnswer.yes;

  CourseVisitLearnerEngagement _learnerEngagement =
      CourseVisitLearnerEngagement.most;

  CourseVisitAnswer _equipmentAdequate = CourseVisitAnswer.yes;

  CourseVisitEnvironmentStatus _environmentStatus =
      CourseVisitEnvironmentStatus.safeAndRespectful;

  int _courseHealthRating = 3;
  bool _safeguardingConcern = false;

  final Map<int, _VisitMentorState> _mentorStates = {};

  final Map<int, int> _mentorRatings = {};

  final Set<int> _presentStudentIds = {};
  final Set<int> _interviewedStudentIds = {};

  final Map<int, CourseVisitStudentEnjoyment> _studentEnjoyment = {};

  final Map<int, CourseVisitStudentLearning> _studentLearning = {};

  final Map<int, CourseVisitStudentSafety> _studentSafety = {};

  final Map<int, TextEditingController> _studentNoteControllers = {};

  final List<_ActionDraft> _actions = [];

  @override
  void initState() {
    super.initState();
    _selectedCourseId = widget.initialCourseId;
  }

  @override
  void dispose() {
    _whatHappenedController.dispose();
    _mainStrengthController.dispose();
    _mainProblemController.dispose();
    _supportProvidedController.dispose();
    _safeguardingNoteController.dispose();

    for (final controller in _studentNoteControllers.values) {
      controller.dispose();
    }

    for (final action in _actions) {
      action.dispose();
    }

    super.dispose();
  }

  Course? get _selectedCourse {
    final courseId = _selectedCourseId;

    if (courseId == null) {
      return null;
    }

    for (final course in widget.courses) {
      if (course.id == courseId) {
        return course;
      }
    }

    return null;
  }

  List<Mentor> get _courseMentors {
    final course = _selectedCourse;

    if (course == null) {
      return [];
    }

    final mentorIds = course.mentorIds.toSet();

    final mentors = widget.mentors
        .where((mentor) => mentorIds.contains(mentor.id))
        .toList();

    mentors.sort((first, second) => first.fullName.compareTo(second.fullName));

    return mentors;
  }

  List<Student> get _courseStudents {
    final course = _selectedCourse;

    if (course == null) {
      return [];
    }

    final studentIds = course.studentIds.toSet();

    final students = widget.students
        .where((student) => studentIds.contains(student.id))
        .toList();

    students.sort((first, second) => first.fullName.compareTo(second.fullName));

    return students;
  }

  bool get _sessionWasHeld {
    return _sessionStatus != CourseVisitSessionStatus.notHeld;
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
      key: ValueKey(_selectedCourseId),
      initialValue: _selectedCourseId,
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

              setState(() {
                _selectedCourseId = courseId;
                _clearParticipantState();
              });
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
        child: Text(_formatDate(_date)),
      ),
    );
  }

  Widget _buildSessionObservation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<CourseVisitSessionStatus>(
          initialValue: _sessionStatus,
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

                  setState(() {
                    _sessionStatus = value;

                    if (!_sessionWasHeld) {
                      _teachingTookPlace = CourseVisitAnswer.no;
                    }
                  });
                },
        ),
        const SizedBox(height: 20),
        if (_sessionWasHeld) ...[
          _answerField(
            label: 'Did teaching take place?',
            value: _teachingTookPlace,
            onChanged: (value) {
              setState(() {
                _teachingTookPlace = value;
              });
            },
          ),
          const SizedBox(height: 20),
          _answerField(
            label:
                'Did the session follow '
                'a clear plan?',
            value: _sessionFollowedPlan,
            onChanged: (value) {
              setState(() {
                _sessionFollowedPlan = value;
              });
            },
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField<CourseVisitLearnerEngagement>(
            initialValue: _learnerEngagement,
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

                    setState(() {
                      _learnerEngagement = value;
                    });
                  },
          ),
          const SizedBox(height: 20),
          _answerField(
            label:
                'Were equipment and '
                'materials adequate?',
            value: _equipmentAdequate,
            onChanged: (value) {
              setState(() {
                _equipmentAdequate = value;
              });
            },
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField<CourseVisitEnvironmentStatus>(
            initialValue: _environmentStatus,
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

                    setState(() {
                      _environmentStatus = value;
                    });
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
    if (_selectedCourse == null) {
      return const Text(
        'Select a course to show '
        'its mentors.',
      );
    }

    final mentors = _courseMentors;

    if (mentors.isEmpty) {
      return const Text(
        'No mentors are assigned '
        'to this course.',
      );
    }

    return Column(
      children: mentors.map((mentor) {
        final state = _mentorStates[mentor.id] ?? _VisitMentorState.absent;

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
                DropdownButtonFormField<_VisitMentorState>(
                  key: ValueKey((mentor.id, state)),
                  initialValue: state,
                  decoration: const InputDecoration(labelText: 'Role'),
                  items: const [
                    DropdownMenuItem(
                      value: _VisitMentorState.teaching,
                      child: Text('Teaching'),
                    ),
                    DropdownMenuItem(
                      value: _VisitMentorState.supporting,
                      child: Text('Supporting'),
                    ),
                    DropdownMenuItem(
                      value: _VisitMentorState.absent,
                      child: Text('Absent'),
                    ),
                  ],
                  onChanged: widget.isSaving
                      ? null
                      : (value) {
                          if (value == null) {
                            return;
                          }

                          setState(() {
                            _mentorStates[mentor.id] = value;

                            if (value == _VisitMentorState.absent) {
                              _mentorRatings.remove(mentor.id);
                            } else {
                              _mentorRatings.putIfAbsent(mentor.id, () => 3);
                            }
                          });
                        },
                ),
                if (state != _VisitMentorState.absent) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    key: ValueKey((mentor.id, _mentorRatings[mentor.id])),
                    initialValue: _mentorRatings[mentor.id] ?? 3,
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

                            setState(() {
                              _mentorRatings[mentor.id] = value;
                            });
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
    if (_selectedCourse == null) {
      return const Text(
        'Select a course to show '
        'its students.',
      );
    }

    final students = _courseStudents;

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
                      setState(() {
                        _presentStudentIds.addAll(
                          students.map((student) => student.id),
                        );
                      });
                    },
              child: const Text('Select all present'),
            ),
            TextButton(
              onPressed: widget.isSaving ? null : _clearStudents,
              child: const Text('Clear'),
            ),
            const Spacer(),
            Text(
              '${_presentStudentIds.length}'
              '/${students.length}',
            ),
          ],
        ),
        ...students.map((student) {
          final present = _presentStudentIds.contains(student.id);

          final interviewed = _interviewedStudentIds.contains(student.id);

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
                          _setStudentPresent(student.id, value ?? false);
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
                            _setStudentInterviewed(student.id, value ?? false);
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
    final noteController = _studentNoteControllers.putIfAbsent(
      studentId,
      TextEditingController.new,
    );

    return Column(
      children: [
        DropdownButtonFormField<CourseVisitStudentEnjoyment>(
          initialValue:
              _studentEnjoyment[studentId] ?? CourseVisitStudentEnjoyment.yes,
          decoration: const InputDecoration(labelText: 'Enjoys the course'),
          items: CourseVisitStudentEnjoyment.values.map((answer) {
            return DropdownMenuItem(value: answer, child: Text(answer.label));
          }).toList(),
          onChanged: widget.isSaving
              ? null
              : (value) {
                  if (value != null) {
                    setState(() {
                      _studentEnjoyment[studentId] = value;
                    });
                  }
                },
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<CourseVisitStudentLearning>(
          initialValue:
              _studentLearning[studentId] ?? CourseVisitStudentLearning.clearly,
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
                    setState(() {
                      _studentLearning[studentId] = value;
                    });
                  }
                },
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<CourseVisitStudentSafety>(
          initialValue:
              _studentSafety[studentId] ?? CourseVisitStudentSafety.yes,
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
                    setState(() {
                      _studentSafety[studentId] = value;
                    });
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
          initialValue: _courseHealthRating,
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
                    setState(() {
                      _courseHealthRating = value;
                    });
                  }
                },
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: _whatHappenedController,
          enabled: !widget.isSaving,
          decoration: const InputDecoration(labelText: 'What happened?'),
          minLines: 2,
          maxLines: 4,
          maxLength: 500,
          textCapitalization: TextCapitalization.sentences,
          validator: _required,
        ),
        const SizedBox(height: 20),
        _optionalTextField(
          controller: _mainStrengthController,
          label: 'Main strength',
        ),
        const SizedBox(height: 20),
        _optionalTextField(
          controller: _mainProblemController,
          label:
              'Main problem or '
              'improvement needed',
        ),
        const SizedBox(height: 20),
        _optionalTextField(
          controller: _supportProvidedController,
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
        ..._actions.asMap().entries.map((entry) {
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
                            : () => _removeAction(index),
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
                              setState(() {
                                action.category = value;
                              });
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
                    validator: _required,
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
            onPressed: widget.isSaving ? null : _addAction,
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
          value: _safeguardingConcern,
          title: const Text('Safeguarding concern'),
          onChanged: widget.isSaving
              ? null
              : (value) {
                  setState(() {
                    _safeguardingConcern = value;

                    if (!value) {
                      _safeguardingNoteController.clear();
                    }
                  });
                },
        ),
        if (_safeguardingConcern)
          TextFormField(
            controller: _safeguardingNoteController,
            enabled: !widget.isSaving,
            decoration: const InputDecoration(
              labelText: 'Restricted safeguarding note',
            ),
            minLines: 3,
            maxLines: 5,
            maxLength: 1000,
            textCapitalization: TextCapitalization.sentences,
            validator: _required,
          ),
      ],
    );
  }

  Future<void> _selectDate() async {
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

      for (final action in _actions) {
        if (action.targetDate?.isBefore(_date) ?? false) {
          action.targetDate = null;
        }
      }
    });
  }

  Future<void> _selectActionDate(_ActionDraft action) async {
    final initialDate =
        action.targetDate == null || action.targetDate!.isBefore(_date)
        ? _date
        : action.targetDate!;

    final selected = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: _date,
      lastDate: DateTime(_date.year + 3, 12, 31),
    );

    if (selected == null || !mounted) {
      return;
    }

    setState(() {
      action.targetDate = DateUtils.dateOnly(selected);
    });
  }

  void _setStudentPresent(int studentId, bool present) {
    setState(() {
      if (present) {
        _presentStudentIds.add(studentId);
        return;
      }

      _presentStudentIds.remove(studentId);
      _clearStudentInterview(studentId);
    });
  }

  void _setStudentInterviewed(int studentId, bool interviewed) {
    setState(() {
      if (interviewed) {
        _interviewedStudentIds.add(studentId);

        _studentEnjoyment[studentId] = CourseVisitStudentEnjoyment.yes;

        _studentLearning[studentId] = CourseVisitStudentLearning.clearly;

        _studentSafety[studentId] = CourseVisitStudentSafety.yes;

        return;
      }

      _clearStudentInterview(studentId);
    });
  }

  void _clearStudentInterview(int studentId) {
    _interviewedStudentIds.remove(studentId);

    _studentEnjoyment.remove(studentId);
    _studentLearning.remove(studentId);
    _studentSafety.remove(studentId);

    _studentNoteControllers.remove(studentId)?.dispose();
  }

  void _clearStudents() {
    setState(() {
      _presentStudentIds.clear();

      for (final controller in _studentNoteControllers.values) {
        controller.dispose();
      }

      _interviewedStudentIds.clear();
      _studentEnjoyment.clear();
      _studentLearning.clear();
      _studentSafety.clear();
      _studentNoteControllers.clear();
    });
  }

  void _clearParticipantState() {
    _mentorStates.clear();
    _mentorRatings.clear();
    _presentStudentIds.clear();
    _interviewedStudentIds.clear();
    _studentEnjoyment.clear();
    _studentLearning.clear();
    _studentSafety.clear();

    for (final controller in _studentNoteControllers.values) {
      controller.dispose();
    }

    _studentNoteControllers.clear();
  }

  void _addAction() {
    setState(() {
      _actions.add(_ActionDraft());
    });
  }

  void _removeAction(int index) {
    setState(() {
      _actions.removeAt(index).dispose();
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final courseId = _selectedCourseId;

    if (courseId == null) {
      return;
    }

    final mentors = _courseMentors
        .where((mentor) {
          final state = _mentorStates[mentor.id] ?? _VisitMentorState.absent;

          return state != _VisitMentorState.absent;
        })
        .map((mentor) {
          final state = _mentorStates[mentor.id]!;

          return CourseVisitMentor(
            mentorId: mentor.id,
            role: state == _VisitMentorState.teaching
                ? CourseVisitMentorRole.teaching
                : CourseVisitMentorRole.supporting,
            performanceRating: _mentorRatings[mentor.id] ?? 3,
          );
        })
        .toList();

    final studentIds = _presentStudentIds.toList()..sort();

    final students = studentIds.map((studentId) {
      final interviewed = _interviewedStudentIds.contains(studentId);

      return CourseVisitStudent(
        studentId: studentId,
        interviewed: interviewed,
        enjoyment: interviewed ? _studentEnjoyment[studentId] : null,
        learning: interviewed ? _studentLearning[studentId] : null,
        feelsSafe: interviewed ? _studentSafety[studentId] : null,
        note: interviewed
            ? _optionalText(_studentNoteControllers[studentId]?.text ?? '')
            : null,
      );
    }).toList();

    final actions = _actions.map((action) {
      return CourseVisitActionCreateRequest(
        category: action.category,
        description: action.descriptionController.text.trim(),
        responsiblePerson: _optionalText(
          action.responsiblePersonController.text,
        ),
        targetDate: action.targetDate,
      );
    }).toList();

    final submitted = await widget.onSubmit(
      CourseVisitReportCreateRequest(
        courseId: courseId,
        date: _date,
        sessionStatus: _sessionStatus,
        teachingTookPlace: _sessionWasHeld
            ? _teachingTookPlace
            : CourseVisitAnswer.no,
        sessionFollowedPlan: _sessionWasHeld ? _sessionFollowedPlan : null,
        learnerEngagement: _sessionWasHeld ? _learnerEngagement : null,
        equipmentAdequate: _sessionWasHeld ? _equipmentAdequate : null,
        environmentStatus: _sessionWasHeld ? _environmentStatus : null,
        whatHappened: _whatHappenedController.text.trim(),
        mainStrength: _optionalText(_mainStrengthController.text),
        mainProblem: _optionalText(_mainProblemController.text),
        supportProvided: _optionalText(_supportProvidedController.text),
        courseHealthRating: _courseHealthRating,
        safeguardingConcern: _safeguardingConcern,
        safeguardingNote: _safeguardingConcern
            ? _optionalText(_safeguardingNoteController.text)
            : null,
        mentors: mentors,
        students: students,
        actions: actions,
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

class _ActionDraft {
  CourseVisitActionCategory category = CourseVisitActionCategory.mentorCoaching;

  final descriptionController = TextEditingController();

  final responsiblePersonController = TextEditingController();

  DateTime? targetDate;

  void dispose() {
    descriptionController.dispose();
    responsiblePersonController.dispose();
  }
}
