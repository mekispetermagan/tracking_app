import 'package:flutter/foundation.dart';

import '../api/api.dart';
import '../models/models.dart';

enum MentorStatusFilter { active, all, inactive }

enum AdminMentorManagementView { list, form, resetPin }

enum AdminMentorFormMode { add, edit }

class AdminMentorManagementController extends ChangeNotifier {
  final AdminMentorApi _api;

  AdminMentorManagementController({AdminMentorApi? api})
    : _api = api ?? AdminMentorApi();

  List<Mentor> _mentors = [];
  MentorStatusFilter _statusFilter = MentorStatusFilter.active;
  AdminMentorManagementView _view = AdminMentorManagementView.list;
  AdminMentorFormMode _formMode = AdminMentorFormMode.add;

  int? _countryIdFilter;
  int? _selectedMentorId;
  bool _isLoading = false;
  bool _isSaving = false;
  bool _hasLoaded = false;
  String? _message;

  List<Mentor> get mentors => List.unmodifiable(_mentors);

  List<Mentor> get visibleMentors {
    return _mentors.where((mentor) {
      final statusMatches = switch (_statusFilter) {
        MentorStatusFilter.active => mentor.active,
        MentorStatusFilter.all => true,
        MentorStatusFilter.inactive => !mentor.active,
      };

      final countryMatches =
          _countryIdFilter == null || mentor.countryId == _countryIdFilter;

      return statusMatches && countryMatches;
    }).toList();
  }

  MentorStatusFilter get statusFilter => _statusFilter;
  AdminMentorManagementView get view => _view;
  AdminMentorFormMode get formMode => _formMode;
  int? get countryIdFilter => _countryIdFilter;
  int? get selectedMentorId => _selectedMentorId;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get message => _message;

  Mentor? get selectedMentor {
    final selectedId = _selectedMentorId;

    if (selectedId == null) {
      return null;
    }

    for (final mentor in _mentors) {
      if (mentor.id == selectedId) {
        return mentor;
      }
    }

    return null;
  }

  Mentor? get formMentor {
    return _formMode == AdminMentorFormMode.edit ? selectedMentor : null;
  }

  bool get canEdit => selectedMentor != null && !_isLoading && !_isSaving;

  Future<void> openList({required String accessToken}) async {
    _view = AdminMentorManagementView.list;
    _message = null;
    notifyListeners();

    if (!_hasLoaded) {
      await loadMentors(accessToken: accessToken);
    }
  }

  void startAddMentor() {
    if (_isLoading || _isSaving) {
      return;
    }

    _formMode = AdminMentorFormMode.add;
    _view = AdminMentorManagementView.form;
    _message = null;
    notifyListeners();
  }

  void startEditSelectedMentor() {
    if (!canEdit) {
      _message = 'No mentor selected.';
      notifyListeners();
      return;
    }

    _formMode = AdminMentorFormMode.edit;
    _view = AdminMentorManagementView.form;
    _message = null;
    notifyListeners();
  }

  void cancelTaskScreen() {
    _view = AdminMentorManagementView.list;
    _message = null;
    notifyListeners();
  }

  Future<void> loadMentors({required String accessToken}) async {
    _isLoading = true;
    _message = null;
    notifyListeners();

    final result = await _api.fetchMentors(
      accessToken: accessToken,
      activeOnly: _statusFilter == MentorStatusFilter.active,
    );

    if (result.mentors != null) {
      _mentors = result.mentors!;
      _hasLoaded = true;
      _clearSelectionIfHidden();
    } else {
      _message = result.message ?? _messageForFailure(result.failure);
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> setStatusFilter({
    required MentorStatusFilter value,
    required String accessToken,
  }) async {
    if (_statusFilter == value) {
      return;
    }

    _statusFilter = value;
    _selectedMentorId = null;
    notifyListeners();

    await loadMentors(accessToken: accessToken);
  }

  void setCountryIdFilter(int? value) {
    if (_countryIdFilter == value) {
      return;
    }

    _countryIdFilter = value;
    _clearSelectionIfHidden();
    notifyListeners();
  }

  void selectMentor(int mentorId) {
    if (_selectedMentorId == mentorId) {
      return;
    }

    _selectedMentorId = mentorId;
    notifyListeners();
  }

  void clearSelection() {
    if (_selectedMentorId == null) {
      return;
    }

    _selectedMentorId = null;
    notifyListeners();
  }

  void clearMessage() {
    if (_message == null) {
      return;
    }

    _message = null;
    notifyListeners();
  }

  Future<bool> createMentor({
    required String accessToken,
    required MentorCreateRequest request,
  }) async {
    _isSaving = true;
    _message = null;
    notifyListeners();

    final result = await _api.createMentor(
      accessToken: accessToken,
      request: request,
    );

    if (result.mentor != null) {
      _selectedMentorId = result.mentor!.id;
      _view = AdminMentorManagementView.list;
      await loadMentors(accessToken: accessToken);
      _isSaving = false;
      notifyListeners();
      return true;
    }

    _message = result.message ?? _messageForFailure(result.failure);
    _isSaving = false;
    notifyListeners();
    return false;
  }

  Future<bool> updateMentor({
    required String accessToken,
    required int mentorId,
    required MentorUpdateRequest request,
  }) async {
    _isSaving = true;
    _message = null;
    notifyListeners();

    final result = await _api.updateMentor(
      accessToken: accessToken,
      mentorId: mentorId,
      request: request,
    );

    if (result.mentor != null) {
      _replaceMentor(result.mentor!);
      _selectedMentorId = result.mentor!.id;
      _clearSelectionIfHidden();
      _view = AdminMentorManagementView.list;
      _isSaving = false;
      notifyListeners();
      return true;
    }

    _message = result.message ?? _messageForFailure(result.failure);
    _isSaving = false;
    notifyListeners();
    return false;
  }

  Future<bool> deactivateSelectedMentor({required String accessToken}) async {
    final mentor = selectedMentor;

    if (mentor == null) {
      _message = 'No mentor selected.';
      notifyListeners();
      return false;
    }

    _isSaving = true;
    _message = null;
    notifyListeners();

    final result = await _api.deactivateMentor(
      accessToken: accessToken,
      mentorId: mentor.id,
    );

    if (result.mentor != null) {
      _replaceMentor(result.mentor!);
      _clearSelectionIfHidden();
      _isSaving = false;
      notifyListeners();
      return true;
    }

    _message = result.message ?? _messageForFailure(result.failure);
    _isSaving = false;
    notifyListeners();
    return false;
  }

  void startResetPin() {
    if (!canEdit) {
      _message = 'No mentor selected.';
      notifyListeners();
      return;
    }

    _view = AdminMentorManagementView.resetPin;
    _message = null;
    notifyListeners();
  }

  Future<bool> resetSelectedMentorPin({
    required String accessToken,
    required MentorResetPinRequest request,
  }) async {
    final mentor = selectedMentor;

    if (mentor == null) {
      _message = 'No mentor selected.';
      notifyListeners();
      return false;
    }

    _isSaving = true;
    _message = null;
    notifyListeners();

    final result = await _api.resetMentorPin(
      accessToken: accessToken,
      mentorId: mentor.id,
      request: request,
    );

    if (result.mentor != null) {
      _replaceMentor(result.mentor!);
      _selectedMentorId = result.mentor!.id;
      _message = 'Temporary PIN reset.';
      _isSaving = false;
      notifyListeners();
      return true;
    }

    _message = result.message ?? _messageForFailure(result.failure);
    _isSaving = false;
    notifyListeners();
    return false;
  }

  void reset() {
    _mentors = [];
    _statusFilter = MentorStatusFilter.active;
    _view = AdminMentorManagementView.list;
    _formMode = AdminMentorFormMode.add;
    _countryIdFilter = null;
    _selectedMentorId = null;
    _isLoading = false;
    _isSaving = false;
    _hasLoaded = false;
    _message = null;
    notifyListeners();
  }

  void _replaceMentor(Mentor updatedMentor) {
    final index = _mentors.indexWhere(
      (mentor) => mentor.id == updatedMentor.id,
    );

    if (index == -1) {
      _mentors = [..._mentors, updatedMentor];
      return;
    }

    _mentors = [
      ..._mentors.sublist(0, index),
      updatedMentor,
      ..._mentors.sublist(index + 1),
    ];
  }

  void _clearSelectionIfHidden() {
    final selectedId = _selectedMentorId;

    if (selectedId == null) {
      return;
    }

    final stillVisible = visibleMentors.any(
      (mentor) => mentor.id == selectedId,
    );

    if (!stillVisible) {
      _selectedMentorId = null;
    }
  }

  String _messageForFailure(AdminMentorFailure? failure) {
    return switch (failure) {
      AdminMentorFailure.badRequest => 'Invalid mentor data.',
      AdminMentorFailure.unauthorized => 'Login expired.',
      AdminMentorFailure.forbidden => 'Admin access required.',
      AdminMentorFailure.notFound => 'Mentor not found.',
      AdminMentorFailure.conflict => 'Phone number already exists.',
      AdminMentorFailure.serverError => 'Server error.',
      AdminMentorFailure.networkError => 'Cannot connect to server.',
      null => 'Unknown error.',
    };
  }
}
