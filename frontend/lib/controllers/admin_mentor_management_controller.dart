import 'feature_controller.dart';

import '../api/api.dart';
import '../models/models.dart';
import 'management_types.dart';

enum AdminMentorManagementView { list, form, resetPin }

class AdminMentorManagementController extends FeatureController {
  final AdminMentorApi _api;

  AdminMentorManagementController({AdminMentorApi? api})
    : _api = api ?? AdminMentorApi();

  List<Mentor> _mentors = [];
  ActiveStatusFilter _statusFilter = ActiveStatusFilter.active;
  AdminMentorManagementView _view = AdminMentorManagementView.list;
  EntityFormMode _formMode = EntityFormMode.add;

  int? _countryIdFilter;
  int? _selectedMentorId;
  bool _isLoading = false;
  bool _isSaving = false;
  String? _message;

  List<Mentor> get mentors => List.unmodifiable(_mentors);

  List<Mentor> get visibleMentors {
    return _mentors.where((mentor) {
      final statusMatches = switch (_statusFilter) {
        ActiveStatusFilter.active => mentor.active,
        ActiveStatusFilter.all => true,
        ActiveStatusFilter.inactive => !mentor.active,
      };

      final countryMatches =
          _countryIdFilter == null || mentor.countryId == _countryIdFilter;

      return statusMatches && countryMatches;
    }).toList();
  }

  ActiveStatusFilter get statusFilter => _statusFilter;
  AdminMentorManagementView get view => _view;
  EntityFormMode get formMode => _formMode;
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
    return _formMode == EntityFormMode.edit ? selectedMentor : null;
  }

  bool get canEdit => selectedMentor != null && !_isLoading && !_isSaving;

  Future<void> openList({required String accessToken}) async {
    _view = AdminMentorManagementView.list;
    _message = null;
    notifyListeners();

    await loadMentors(accessToken: accessToken);
  }

  void startAddMentor() {
    if (_isLoading || _isSaving) {
      return;
    }

    _formMode = EntityFormMode.add;
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

    _formMode = EntityFormMode.edit;
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
    final request = beginRequest();
    _isLoading = true;
    _message = null;
    notifyListeners();

    final result = await _api.fetchMentors(
      accessToken: accessToken,
      activeOnly: false,
    );

    if (!requestIsCurrent(request)) return;

    if (result.mentors != null) {
      _mentors = result.mentors!;
      _clearSelectionIfHidden();
    } else {
      _message = result.message ?? _messageForFailure(result.failure);
    }

    _isLoading = false;
    notifyListeners();
  }

  void setStatusFilter(ActiveStatusFilter value) {
    if (_statusFilter == value) {
      return;
    }

    _statusFilter = value;
    _clearSelectionIfHidden();
    notifyListeners();
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
    if (_isLoading ||
        _isSaving ||
        _selectedMentorId == mentorId ||
        !_mentors.any((mentor) => mentor.id == mentorId)) {
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
    if (_isLoading || _isSaving) return false;
    final operation = beginRequest();
    _isSaving = true;
    _message = null;
    notifyListeners();

    final result = await _api.createMentor(
      accessToken: accessToken,
      request: request,
    );

    if (!requestIsCurrent(operation)) return false;

    if (result.mentor != null) {
      _replaceMentor(result.mentor!);
      _selectedMentorId = result.mentor!.id;
      _view = AdminMentorManagementView.list;
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

  Future<bool> updateMentor({
    required String accessToken,
    required int mentorId,
    required MentorUpdateRequest request,
  }) async {
    if (_isLoading || _isSaving) return false;
    final operation = beginRequest();
    _isSaving = true;
    _message = null;
    notifyListeners();

    final result = await _api.updateMentor(
      accessToken: accessToken,
      mentorId: mentorId,
      request: request,
    );

    if (!requestIsCurrent(operation)) return false;

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
    if (_isLoading || _isSaving) return false;
    final mentor = selectedMentor;

    if (mentor == null) {
      _message = 'No mentor selected.';
      notifyListeners();
      return false;
    }

    final operation = beginRequest();
    _isSaving = true;
    _message = null;
    notifyListeners();

    final result = await _api.deactivateMentor(
      accessToken: accessToken,
      mentorId: mentor.id,
    );

    if (!requestIsCurrent(operation)) return false;

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
    if (_isLoading || _isSaving) return false;
    final mentor = selectedMentor;

    if (mentor == null) {
      _message = 'No mentor selected.';
      notifyListeners();
      return false;
    }

    final operation = beginRequest();
    _isSaving = true;
    _message = null;
    notifyListeners();

    final result = await _api.resetMentorPin(
      accessToken: accessToken,
      mentorId: mentor.id,
      request: request,
    );

    if (!requestIsCurrent(operation)) return false;

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
    invalidateRequests();
    _mentors = [];
    _statusFilter = ActiveStatusFilter.active;
    _view = AdminMentorManagementView.list;
    _formMode = EntityFormMode.add;
    _countryIdFilter = null;
    _selectedMentorId = null;
    _isLoading = false;
    _isSaving = false;
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
      AdminMentorFailure.invalidData => 'Invalid server data.',
      AdminMentorFailure.serverError => 'Server error.',
      AdminMentorFailure.networkError => 'Cannot connect to server.',
      null => 'Unknown error.',
    };
  }
}
