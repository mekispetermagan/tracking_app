import 'package:flutter/material.dart';

import '../models/models.dart';

class MentorSessionLogFormController extends ChangeNotifier {
  MentorSessionLogFormController({DateTime? initialDate})
    : _date = DateUtils.dateOnly(initialDate ?? DateTime.now());

  static const skillGames = [
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

  final projectTitleController = TextEditingController();
  final otherProjectTypeController = TextEditingController();
  final whatWorkedController = TextEditingController();
  final challengesController = TextEditingController();
  final nextStepController = TextEditingController();

  DateTime _date;
  ProjectType _projectType = ProjectType.scratch;
  CompletionStatus _completionStatus = CompletionStatus.completed;
  final Set<String> _selectedGames = {};
  String? _mentorError;
  String? _attendanceError;

  DateTime get date => _date;
  ProjectType get projectType => _projectType;
  CompletionStatus get completionStatus => _completionStatus;
  String? get mentorError => _mentorError;
  String? get attendanceError => _attendanceError;

  bool isGameSelected(String game) => _selectedGames.contains(game);

  void setDate(DateTime value) {
    _date = DateUtils.dateOnly(value);
    notifyListeners();
  }

  void setProjectType(ProjectType value) {
    _projectType = value;
    if (value != ProjectType.other) {
      otherProjectTypeController.clear();
    }
    notifyListeners();
  }

  void setCompletionStatus(CompletionStatus value) {
    _completionStatus = value;
    notifyListeners();
  }

  void setGameSelected(String game, bool selected) {
    if (!skillGames.contains(game)) return;
    if (selected) {
      _selectedGames.add(game);
    } else {
      _selectedGames.remove(game);
    }
    notifyListeners();
  }

  void clearParticipantErrors() {
    if (_mentorError == null && _attendanceError == null) return;
    _mentorError = null;
    _attendanceError = null;
    notifyListeners();
  }

  void clearMentorError() {
    if (_mentorError == null) return;
    _mentorError = null;
    notifyListeners();
  }

  void clearAttendanceError() {
    if (_attendanceError == null) return;
    _attendanceError = null;
    notifyListeners();
  }

  bool validateParticipants({
    required Set<int> teachingMentorIds,
    required Set<int> studentIds,
  }) {
    _mentorError = teachingMentorIds.isEmpty
        ? 'Select at least one teaching mentor.'
        : null;
    _attendanceError = studentIds.isEmpty
        ? 'Select at least one student.'
        : null;
    notifyListeners();
    return _mentorError == null && _attendanceError == null;
  }

  SessionLogCreateRequest? buildRequest({
    required int? courseId,
    required Set<int> teachingMentorIds,
    required Set<int> supportingMentorIds,
    required Set<int> studentIds,
  }) {
    if (courseId == null ||
        !validateParticipants(
          teachingMentorIds: teachingMentorIds,
          studentIds: studentIds,
        )) {
      return null;
    }

    final teachingIds = teachingMentorIds.toList()..sort();
    final supportingIds = supportingMentorIds.toList()..sort();
    final students = studentIds.toList()..sort();
    final games = _selectedGames.toList()..sort();

    return SessionLogCreateRequest(
      courseId: courseId,
      date: _date,
      projectTitle: projectTitleController.text.trim(),
      projectType: _projectType,
      otherProjectType: _projectType == ProjectType.other
          ? otherProjectTypeController.text.trim()
          : null,
      gamesPlayed: games.isEmpty ? null : games.join(', '),
      completionStatus: _completionStatus,
      whatWorked: _optionalText(whatWorkedController.text),
      challenges: _optionalText(challengesController.text),
      nextStep: _optionalText(nextStepController.text),
      teachingMentorIds: teachingIds,
      supportingMentorIds: supportingIds,
      studentIds: students,
    );
  }

  String? requiredText(String? value) =>
      value == null || value.trim().isEmpty ? 'Required' : null;

  String? _optionalText(String value) {
    final text = value.trim();
    return text.isEmpty ? null : text;
  }

  @override
  void dispose() {
    projectTitleController.dispose();
    otherProjectTypeController.dispose();
    whatWorkedController.dispose();
    challengesController.dispose();
    nextStepController.dispose();
    super.dispose();
  }
}
