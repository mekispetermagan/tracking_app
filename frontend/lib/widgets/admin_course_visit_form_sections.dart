import 'package:flutter/material.dart';

import '../controllers/admin_course_visit_form_controller.dart';
import '../models/models.dart';

class CourseVisitCourseDateSection extends StatelessWidget {
  final AdminCourseVisitFormController controller;
  final List<Course> courses;
  final bool isLoading;
  final bool isSaving;
  final VoidCallback onSelectDate;

  const CourseVisitCourseDateSection({
    required this.controller,
    required this.courses,
    required this.isLoading,
    required this.isSaving,
    required this.onSelectDate,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Course and date'),
        const SizedBox(height: 16),
        if (courses.isEmpty && !isLoading)
          const Text('No courses available.')
        else
          DropdownButtonFormField<int>(
            key: ValueKey(controller.selectedCourseId),
            initialValue: controller.selectedCourseId,
            decoration: const InputDecoration(labelText: 'Course'),
            items: courses.map((course) {
              return DropdownMenuItem(
                value: course.id,
                child: Text(course.name),
              );
            }).toList(),
            validator: (value) => value == null ? 'Select a course' : null,
            onChanged: isLoading || isSaving
                ? null
                : (courseId) {
                    if (courseId != null) controller.selectCourse(courseId);
                  },
          ),
        const SizedBox(height: 20),
        InkWell(
          onTap: isSaving ? null : onSelectDate,
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Visit date',
              suffixIcon: Icon(Icons.calendar_today),
            ),
            child: Text(_formatDate(controller.date)),
          ),
        ),
      ],
    );
  }
}

class CourseVisitSessionObservationSection extends StatelessWidget {
  final AdminCourseVisitFormController controller;
  final bool isSaving;

  const CourseVisitSessionObservationSection({
    required this.controller,
    required this.isSaving,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Session observation'),
        const SizedBox(height: 16),
        DropdownButtonFormField<CourseVisitSessionStatus>(
          initialValue: controller.sessionStatus,
          decoration: const InputDecoration(labelText: 'Was the session held?'),
          items: CourseVisitSessionStatus.values.map((status) {
            return DropdownMenuItem(value: status, child: Text(status.label));
          }).toList(),
          onChanged: isSaving
              ? null
              : (value) {
                  if (value != null) controller.setSessionStatus(value);
                },
        ),
        const SizedBox(height: 20),
        if (controller.sessionWasHeld) ...[
          _AnswerField(
            label: 'Did teaching take place?',
            value: controller.teachingTookPlace,
            isSaving: isSaving,
            onChanged: controller.setTeachingTookPlace,
          ),
          const SizedBox(height: 20),
          _AnswerField(
            label: 'Did the session follow a clear plan?',
            value: controller.sessionFollowedPlan,
            isSaving: isSaving,
            onChanged: controller.setSessionFollowedPlan,
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField<CourseVisitLearnerEngagement>(
            initialValue: controller.learnerEngagement,
            decoration: const InputDecoration(labelText: 'Learner engagement'),
            items: CourseVisitLearnerEngagement.values.map((engagement) {
              return DropdownMenuItem(
                value: engagement,
                child: Text(engagement.label),
              );
            }).toList(),
            onChanged: isSaving
                ? null
                : (value) {
                    if (value != null) controller.setLearnerEngagement(value);
                  },
          ),
          const SizedBox(height: 20),
          _AnswerField(
            label: 'Were equipment and materials adequate?',
            value: controller.equipmentAdequate,
            isSaving: isSaving,
            onChanged: controller.setEquipmentAdequate,
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField<CourseVisitEnvironmentStatus>(
            initialValue: controller.environmentStatus,
            decoration: const InputDecoration(
              labelText: 'Learning environment',
            ),
            items: CourseVisitEnvironmentStatus.values.map((status) {
              return DropdownMenuItem(value: status, child: Text(status.label));
            }).toList(),
            onChanged: isSaving
                ? null
                : (value) {
                    if (value != null) controller.setEnvironmentStatus(value);
                  },
          ),
        ] else
          const Text(
            'The remaining session observation questions do not apply.',
          ),
      ],
    );
  }
}

class CourseVisitMentorsSection extends StatelessWidget {
  final AdminCourseVisitFormController controller;
  final bool isSaving;

  const CourseVisitMentorsSection({
    required this.controller,
    required this.isSaving,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final mentors = controller.courseMentors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Mentors present'),
        const SizedBox(height: 12),
        if (controller.selectedCourse == null)
          const Text('Select a course to show its mentors.')
        else if (mentors.isEmpty)
          const Text('No mentors are assigned to this course.')
        else
          ...mentors.map((mentor) {
            final state = controller.mentorState(mentor.id);

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
                      onChanged: isSaving
                          ? null
                          : (value) {
                              if (value != null) {
                                controller.setMentorState(mentor.id, value);
                              }
                            },
                    ),
                    if (state != CourseVisitMentorState.absent) ...[
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int>(
                        key: ValueKey((
                          mentor.id,
                          controller.mentorRating(mentor.id),
                        )),
                        initialValue: controller.mentorRating(mentor.id),
                        decoration: const InputDecoration(
                          labelText: 'Performance',
                        ),
                        items: List.generate(5, (index) {
                          final rating = index + 1;
                          return DropdownMenuItem(
                            value: rating,
                            child: Text(
                              '$rating – ${_mentorRatingLabel(rating)}',
                            ),
                          );
                        }),
                        onChanged: isSaving
                            ? null
                            : (value) {
                                if (value != null) {
                                  controller.setMentorRating(mentor.id, value);
                                }
                              },
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }
}

class CourseVisitStudentsSection extends StatelessWidget {
  final AdminCourseVisitFormController controller;
  final bool isSaving;

  const CourseVisitStudentsSection({
    required this.controller,
    required this.isSaving,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final students = controller.courseStudents;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Students present and interviewed'),
        const SizedBox(height: 12),
        if (controller.selectedCourse == null)
          const Text('Select a course to show its students.')
        else if (students.isEmpty)
          const Text('No students are enrolled in this course.')
        else ...[
          Row(
            children: [
              TextButton(
                onPressed: isSaving
                    ? null
                    : controller.selectAllStudentsPresent,
                child: const Text('Select all present'),
              ),
              TextButton(
                onPressed: isSaving ? null : controller.clearStudents,
                child: const Text('Clear'),
              ),
              const Spacer(),
              Text('${controller.presentStudentCount}/${students.length}'),
            ],
          ),
          ...students.map((student) {
            final present = controller.isStudentPresent(student.id);
            final interviewed = controller.isStudentInterviewed(student.id);

            return Card.outlined(
              margin: const EdgeInsets.only(bottom: 10),
              child: Column(
                children: [
                  CheckboxListTile(
                    value: present,
                    title: Text(student.fullName),
                    subtitle: const Text('Present'),
                    onChanged: isSaving
                        ? null
                        : (value) {
                            controller.setStudentPresent(
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
                      onChanged: isSaving
                          ? null
                          : (value) {
                              controller.setStudentInterviewed(
                                student.id,
                                value ?? false,
                              );
                            },
                    ),
                    if (interviewed)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: _InterviewFields(
                          controller: controller,
                          studentId: student.id,
                          isSaving: isSaving,
                        ),
                      ),
                  ],
                ],
              ),
            );
          }),
        ],
      ],
    );
  }
}

class CourseVisitAssessmentSection extends StatelessWidget {
  final AdminCourseVisitFormController controller;
  final bool isSaving;

  const CourseVisitAssessmentSection({
    required this.controller,
    required this.isSaving,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Assessment and supervision'),
        const SizedBox(height: 16),
        DropdownButtonFormField<int>(
          initialValue: controller.courseHealthRating,
          decoration: const InputDecoration(labelText: 'Course health'),
          items: List.generate(5, (index) {
            final rating = index + 1;
            return DropdownMenuItem(
              value: rating,
              child: Text('$rating – ${_courseHealthLabel(rating)}'),
            );
          }),
          onChanged: isSaving
              ? null
              : (value) {
                  if (value != null) controller.setCourseHealthRating(value);
                },
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: controller.whatHappenedController,
          enabled: !isSaving,
          decoration: const InputDecoration(labelText: 'What happened?'),
          minLines: 2,
          maxLines: 4,
          maxLength: 500,
          textCapitalization: TextCapitalization.sentences,
          validator: controller.requiredText,
        ),
        const SizedBox(height: 20),
        _OptionalTextField(
          controller: controller.mainStrengthController,
          label: 'Main strength',
          enabled: !isSaving,
        ),
        const SizedBox(height: 20),
        _OptionalTextField(
          controller: controller.mainProblemController,
          label: 'Main problem or improvement needed',
          enabled: !isSaving,
        ),
        const SizedBox(height: 20),
        _OptionalTextField(
          controller: controller.supportProvidedController,
          label: 'Advice or practical help provided',
          enabled: !isSaving,
        ),
      ],
    );
  }
}

class CourseVisitActionsSection extends StatelessWidget {
  final AdminCourseVisitFormController controller;
  final bool isSaving;
  final ValueChanged<CourseVisitActionDraft> onSelectActionDate;

  const CourseVisitActionsSection({
    required this.controller,
    required this.isSaving,
    required this.onSelectActionDate,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Follow-up actions'),
        const SizedBox(height: 8),
        const Text('Optional. Add each action separately.'),
        const SizedBox(height: 12),
        ...controller.actions.asMap().entries.map((entry) {
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
                        onPressed: isSaving
                            ? null
                            : () => controller.removeAction(index),
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
                    onChanged: isSaving
                        ? null
                        : (value) {
                            if (value != null) {
                              controller.setActionCategory(index, value);
                            }
                          },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: action.descriptionController,
                    enabled: !isSaving,
                    decoration: const InputDecoration(
                      labelText: 'Specific action',
                    ),
                    maxLength: 500,
                    textCapitalization: TextCapitalization.sentences,
                    validator: controller.requiredText,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: action.responsiblePersonController,
                    enabled: !isSaving,
                    decoration: const InputDecoration(
                      labelText: 'Responsible person',
                    ),
                    maxLength: 100,
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: isSaving ? null : () => onSelectActionDate(action),
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
        OutlinedButton.icon(
          onPressed: isSaving ? null : controller.addAction,
          icon: const Icon(Icons.add),
          label: const Text('Add action'),
        ),
      ],
    );
  }
}

class CourseVisitSafeguardingSection extends StatelessWidget {
  final AdminCourseVisitFormController controller;
  final bool isSaving;

  const CourseVisitSafeguardingSection({
    required this.controller,
    required this.isSaving,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Safeguarding'),
        const SizedBox(height: 8),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: controller.safeguardingConcern,
          title: const Text('Safeguarding concern'),
          onChanged: isSaving ? null : controller.setSafeguardingConcern,
        ),
        if (controller.safeguardingConcern)
          TextFormField(
            controller: controller.safeguardingNoteController,
            enabled: !isSaving,
            decoration: const InputDecoration(
              labelText: 'Restricted safeguarding note',
            ),
            minLines: 3,
            maxLines: 5,
            maxLength: 1000,
            textCapitalization: TextCapitalization.sentences,
            validator: controller.requiredText,
          ),
      ],
    );
  }
}

class _AnswerField extends StatelessWidget {
  final String label;
  final CourseVisitAnswer value;
  final bool isSaving;
  final ValueChanged<CourseVisitAnswer> onChanged;

  const _AnswerField({
    required this.label,
    required this.value,
    required this.isSaving,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<CourseVisitAnswer>(
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      items: CourseVisitAnswer.values.map((answer) {
        return DropdownMenuItem(value: answer, child: Text(answer.label));
      }).toList(),
      onChanged: isSaving
          ? null
          : (newValue) {
              if (newValue != null) onChanged(newValue);
            },
    );
  }
}

class _InterviewFields extends StatelessWidget {
  final AdminCourseVisitFormController controller;
  final int studentId;
  final bool isSaving;

  const _InterviewFields({
    required this.controller,
    required this.studentId,
    required this.isSaving,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DropdownButtonFormField<CourseVisitStudentEnjoyment>(
          initialValue: controller.enjoymentFor(studentId),
          decoration: const InputDecoration(labelText: 'Enjoys the course'),
          items: CourseVisitStudentEnjoyment.values.map((answer) {
            return DropdownMenuItem(value: answer, child: Text(answer.label));
          }).toList(),
          onChanged: isSaving
              ? null
              : (value) {
                  if (value != null) {
                    controller.setStudentEnjoyment(studentId, value);
                  }
                },
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<CourseVisitStudentLearning>(
          initialValue: controller.learningFor(studentId),
          decoration: const InputDecoration(
            labelText: 'Can explain something learned',
          ),
          items: CourseVisitStudentLearning.values.map((answer) {
            return DropdownMenuItem(value: answer, child: Text(answer.label));
          }).toList(),
          onChanged: isSaving
              ? null
              : (value) {
                  if (value != null) {
                    controller.setStudentLearning(studentId, value);
                  }
                },
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<CourseVisitStudentSafety>(
          initialValue: controller.safetyFor(studentId),
          decoration: const InputDecoration(
            labelText: 'Feels safe and respected',
          ),
          items: CourseVisitStudentSafety.values.map((answer) {
            return DropdownMenuItem(value: answer, child: Text(answer.label));
          }).toList(),
          onChanged: isSaving
              ? null
              : (value) {
                  if (value != null) {
                    controller.setStudentSafety(studentId, value);
                  }
                },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: controller.noteControllerFor(studentId),
          enabled: !isSaving,
          decoration: const InputDecoration(labelText: 'Short interview note'),
          minLines: 2,
          maxLines: 3,
          maxLength: 500,
          textCapitalization: TextCapitalization.sentences,
        ),
      ],
    );
  }
}

class _OptionalTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool enabled;

  const _OptionalTextField({
    required this.controller,
    required this.label,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      decoration: InputDecoration(labelText: label),
      minLines: 2,
      maxLines: 4,
      maxLength: 500,
      textCapitalization: TextCapitalization.sentences,
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

String _formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day-$month-${date.year}';
}

String _mentorRatingLabel(int rating) {
  return switch (rating) {
    1 => 'Serious concern',
    2 => 'Needs substantial support',
    3 => 'Adequate',
    4 => 'Good',
    _ => 'Very strong',
  };
}

String _courseHealthLabel(int rating) {
  return switch (rating) {
    1 => 'At risk',
    2 => 'Major problems',
    3 => 'Functioning',
    4 => 'Healthy',
    _ => 'Very strong',
  };
}
