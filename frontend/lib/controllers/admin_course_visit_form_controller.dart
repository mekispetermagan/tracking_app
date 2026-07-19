import 'package:flutter/material.dart';

import '../models/models.dart';

enum CourseVisitMentorState { teaching, supporting, absent }

class CourseVisitActionDraft {
  CourseVisitActionCategory _category =
      CourseVisitActionCategory.mentorCoaching;
  final descriptionController = TextEditingController();
  final responsiblePersonController = TextEditingController();
  DateTime? _targetDate;

  CourseVisitActionCategory get category => _category;
  DateTime? get targetDate => _targetDate;

  void dispose() {
    descriptionController.dispose();
    responsiblePersonController.dispose();
  }
}

class AdminCourseVisitFormController extends ChangeNotifier {
  AdminCourseVisitFormController({
    required this.courses,
    required this.mentors,
    required this.students,
    int? selectedCourseId,
    DateTime? initialDate,
  }) : _selectedCourseId = selectedCourseId,
       _date = DateUtils.dateOnly(initialDate ?? DateTime.now());

  final List<Course> courses;
  final List<Mentor> mentors;
  final List<Student> students;
  final whatHappenedController = TextEditingController();
  final mainStrengthController = TextEditingController();
  final mainProblemController = TextEditingController();
  final supportProvidedController = TextEditingController();
  final safeguardingNoteController = TextEditingController();
  final Map<int, CourseVisitMentorState> _mentorStates = {};
  final Map<int, int> _mentorRatings = {};
  final Set<int> _presentStudentIds = {};
  final Set<int> _interviewedStudentIds = {};
  final Map<int, CourseVisitStudentEnjoyment> _studentEnjoyment = {};
  final Map<int, CourseVisitStudentLearning> _studentLearning = {};
  final Map<int, CourseVisitStudentSafety> _studentSafety = {};
  final Map<int, TextEditingController> _studentNoteControllers = {};
  final List<CourseVisitActionDraft> _actions = [];

  int? _selectedCourseId;
  late DateTime _date;
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

  int? get selectedCourseId => _selectedCourseId;
  DateTime get date => _date;
  CourseVisitSessionStatus get sessionStatus => _sessionStatus;
  CourseVisitAnswer get teachingTookPlace => _teachingTookPlace;
  CourseVisitAnswer get sessionFollowedPlan => _sessionFollowedPlan;
  CourseVisitLearnerEngagement get learnerEngagement => _learnerEngagement;
  CourseVisitAnswer get equipmentAdequate => _equipmentAdequate;
  CourseVisitEnvironmentStatus get environmentStatus => _environmentStatus;
  int get courseHealthRating => _courseHealthRating;
  bool get safeguardingConcern => _safeguardingConcern;
  List<CourseVisitActionDraft> get actions => List.unmodifiable(_actions);
  int get presentStudentCount => _presentStudentIds.length;

  Course? get selectedCourse {
    for (final course in courses) {
      if (course.id == _selectedCourseId) return course;
    }
    return null;
  }

  List<Mentor> get courseMentors {
    final ids = selectedCourse?.mentorIds.toSet();
    if (ids == null) return [];
    return mentors.where((mentor) => ids.contains(mentor.id)).toList()
      ..sort((a, b) => a.fullName.compareTo(b.fullName));
  }

  List<Student> get courseStudents {
    final ids = selectedCourse?.studentIds.toSet();
    if (ids == null) return [];
    return students.where((student) => ids.contains(student.id)).toList()
      ..sort((a, b) => a.fullName.compareTo(b.fullName));
  }

  bool get sessionWasHeld => _sessionStatus != CourseVisitSessionStatus.notHeld;

  CourseVisitMentorState mentorState(int id) =>
      _mentorStates[id] ?? CourseVisitMentorState.absent;
  int mentorRating(int id) => _mentorRatings[id] ?? 3;
  bool isStudentPresent(int id) => _presentStudentIds.contains(id);
  bool isStudentInterviewed(int id) => _interviewedStudentIds.contains(id);
  CourseVisitStudentEnjoyment enjoymentFor(int id) =>
      _studentEnjoyment[id] ?? CourseVisitStudentEnjoyment.yes;
  CourseVisitStudentLearning learningFor(int id) =>
      _studentLearning[id] ?? CourseVisitStudentLearning.clearly;
  CourseVisitStudentSafety safetyFor(int id) =>
      _studentSafety[id] ?? CourseVisitStudentSafety.yes;
  TextEditingController noteControllerFor(int id) =>
      _studentNoteControllers.putIfAbsent(id, TextEditingController.new);

  void selectCourse(int id) {
    if (_selectedCourseId == id) return;
    _selectedCourseId = id;
    _clearParticipantState();
    notifyListeners();
  }

  void setDate(DateTime value) {
    _date = DateUtils.dateOnly(value);
    for (final action in _actions) {
      if (action._targetDate?.isBefore(_date) ?? false) {
        action._targetDate = null;
      }
    }
    notifyListeners();
  }

  void setSessionStatus(CourseVisitSessionStatus value) {
    _sessionStatus = value;
    if (!sessionWasHeld) _teachingTookPlace = CourseVisitAnswer.no;
    notifyListeners();
  }

  void setTeachingTookPlace(CourseVisitAnswer value) {
    _teachingTookPlace = value;
    notifyListeners();
  }

  void setSessionFollowedPlan(CourseVisitAnswer value) {
    _sessionFollowedPlan = value;
    notifyListeners();
  }

  void setLearnerEngagement(CourseVisitLearnerEngagement value) {
    _learnerEngagement = value;
    notifyListeners();
  }

  void setEquipmentAdequate(CourseVisitAnswer value) {
    _equipmentAdequate = value;
    notifyListeners();
  }

  void setEnvironmentStatus(CourseVisitEnvironmentStatus value) {
    _environmentStatus = value;
    notifyListeners();
  }

  void setMentorState(int id, CourseVisitMentorState value) {
    _mentorStates[id] = value;
    if (value == CourseVisitMentorState.absent) {
      _mentorRatings.remove(id);
    } else {
      _mentorRatings.putIfAbsent(id, () => 3);
    }
    notifyListeners();
  }

  void setMentorRating(int id, int value) {
    _mentorRatings[id] = value;
    notifyListeners();
  }

  void selectAllStudentsPresent() {
    _presentStudentIds.addAll(courseStudents.map((student) => student.id));
    notifyListeners();
  }

  void setStudentPresent(int id, bool present) {
    if (present) {
      _presentStudentIds.add(id);
    } else {
      _presentStudentIds.remove(id);
      _clearStudentInterview(id);
    }
    notifyListeners();
  }

  void setStudentInterviewed(int id, bool interviewed) {
    if (interviewed) {
      _interviewedStudentIds.add(id);
      _studentEnjoyment[id] = CourseVisitStudentEnjoyment.yes;
      _studentLearning[id] = CourseVisitStudentLearning.clearly;
      _studentSafety[id] = CourseVisitStudentSafety.yes;
    } else {
      _clearStudentInterview(id);
    }
    notifyListeners();
  }

  void _clearStudentInterview(int id) {
    _interviewedStudentIds.remove(id);
    _studentEnjoyment.remove(id);
    _studentLearning.remove(id);
    _studentSafety.remove(id);
    _studentNoteControllers.remove(id)?.dispose();
  }

  void clearStudents() {
    _presentStudentIds.clear();
    for (final controller in _studentNoteControllers.values) {
      controller.dispose();
    }
    _interviewedStudentIds.clear();
    _studentEnjoyment.clear();
    _studentLearning.clear();
    _studentSafety.clear();
    _studentNoteControllers.clear();
    notifyListeners();
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

  void setStudentEnjoyment(int id, CourseVisitStudentEnjoyment value) {
    _studentEnjoyment[id] = value;
    notifyListeners();
  }

  void setStudentLearning(int id, CourseVisitStudentLearning value) {
    _studentLearning[id] = value;
    notifyListeners();
  }

  void setStudentSafety(int id, CourseVisitStudentSafety value) {
    _studentSafety[id] = value;
    notifyListeners();
  }

  void setCourseHealthRating(int value) {
    _courseHealthRating = value;
    notifyListeners();
  }

  void setSafeguardingConcern(bool value) {
    _safeguardingConcern = value;
    if (!value) safeguardingNoteController.clear();
    notifyListeners();
  }

  void addAction() {
    _actions.add(CourseVisitActionDraft());
    notifyListeners();
  }

  void removeAction(int index) {
    _actions.removeAt(index).dispose();
    notifyListeners();
  }

  void setActionCategory(int index, CourseVisitActionCategory value) {
    _actions[index]._category = value;
    notifyListeners();
  }

  void setActionDate(CourseVisitActionDraft action, DateTime value) {
    if (!_actions.contains(action)) return;
    action._targetDate = DateUtils.dateOnly(value);
    notifyListeners();
  }

  CourseVisitReportCreateRequest? buildRequest() {
    final courseId = _selectedCourseId;
    if (courseId == null) return null;
    final selectedMentors = courseMentors
        .where(
          (mentor) =>
              (_mentorStates[mentor.id] ?? CourseVisitMentorState.absent) !=
              CourseVisitMentorState.absent,
        )
        .map(
          (mentor) => CourseVisitMentor(
            mentorId: mentor.id,
            role: _mentorStates[mentor.id] == CourseVisitMentorState.teaching
                ? CourseVisitMentorRole.teaching
                : CourseVisitMentorRole.supporting,
            performanceRating: _mentorRatings[mentor.id] ?? 3,
          ),
        )
        .toList();
    final ids = _presentStudentIds.toList()..sort();
    final selectedStudents = ids.map((id) {
      final interviewed = _interviewedStudentIds.contains(id);
      return CourseVisitStudent(
        studentId: id,
        interviewed: interviewed,
        enjoyment: interviewed ? _studentEnjoyment[id] : null,
        learning: interviewed ? _studentLearning[id] : null,
        feelsSafe: interviewed ? _studentSafety[id] : null,
        note: interviewed
            ? optionalText(_studentNoteControllers[id]?.text ?? '')
            : null,
      );
    }).toList();
    final selectedActions = _actions
        .map(
          (action) => CourseVisitActionCreateRequest(
            category: action.category,
            description: action.descriptionController.text.trim(),
            responsiblePerson: optionalText(
              action.responsiblePersonController.text,
            ),
            targetDate: action.targetDate,
          ),
        )
        .toList();
    return CourseVisitReportCreateRequest(
      courseId: courseId,
      date: _date,
      sessionStatus: _sessionStatus,
      teachingTookPlace: sessionWasHeld
          ? _teachingTookPlace
          : CourseVisitAnswer.no,
      sessionFollowedPlan: sessionWasHeld ? _sessionFollowedPlan : null,
      learnerEngagement: sessionWasHeld ? _learnerEngagement : null,
      equipmentAdequate: sessionWasHeld ? _equipmentAdequate : null,
      environmentStatus: sessionWasHeld ? _environmentStatus : null,
      whatHappened: whatHappenedController.text.trim(),
      mainStrength: optionalText(mainStrengthController.text),
      mainProblem: optionalText(mainProblemController.text),
      supportProvided: optionalText(supportProvidedController.text),
      courseHealthRating: _courseHealthRating,
      safeguardingConcern: _safeguardingConcern,
      safeguardingNote: _safeguardingConcern
          ? optionalText(safeguardingNoteController.text)
          : null,
      mentors: selectedMentors,
      students: selectedStudents,
      actions: selectedActions,
    );
  }

  String? requiredText(String? value) =>
      value == null || value.trim().isEmpty ? 'Required' : null;

  String? optionalText(String value) {
    final text = value.trim();
    return text.isEmpty ? null : text;
  }

  @override
  void dispose() {
    whatHappenedController.dispose();
    mainStrengthController.dispose();
    mainProblemController.dispose();
    supportProvidedController.dispose();
    safeguardingNoteController.dispose();
    for (final controller in _studentNoteControllers.values) {
      controller.dispose();
    }
    for (final action in _actions) {
      action.dispose();
    }
    super.dispose();
  }
}
