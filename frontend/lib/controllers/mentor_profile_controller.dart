import 'package:flutter/foundation.dart';

import '../api/api.dart';
import '../models/models.dart';

class MentorProfileController extends ChangeNotifier {
  final MentorProfileApi _api;

  MentorProfileController({MentorProfileApi? api})
    : _api = api ?? MentorProfileApi();

  Mentor? _mentor;
  bool _isLoading = false;
  bool _isSaving = false;
  bool _isChangingPin = false;
  String? _message;

  Mentor? get mentor => _mentor;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  bool get isChangingPin => _isChangingPin;
  String? get message => _message;

  Future<void> loadProfile({required String accessToken}) async {
    if (_isLoading) return;

    _isLoading = true;
    _message = null;
    notifyListeners();

    final result = await _api.fetchMyProfile(accessToken: accessToken);

    if (result.mentor != null) {
      _mentor = result.mentor;
    } else {
      _message = result.message ?? _messageForFailure(result.failure);
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> updateProfile({
    required String accessToken,
    required MentorSelfUpdateRequest request,
  }) async {
    if (_isSaving) return false;

    _isSaving = true;
    _message = null;
    notifyListeners();

    final result = await _api.updateMyProfile(
      accessToken: accessToken,
      request: request,
    );

    if (result.mentor != null) {
      _mentor = result.mentor;
      _message = 'Profile updated.';
      _isSaving = false;
      notifyListeners();
      return true;
    }

    _message = result.message ?? _messageForFailure(result.failure);
    _isSaving = false;
    notifyListeners();
    return false;
  }

  Future<bool> changePin({
    required String accessToken,
    required MentorChangePinRequest request,
  }) async {
    if (_isChangingPin) return false;

    _isChangingPin = true;
    _message = null;
    notifyListeners();

    final result = await _api.changePin(
      accessToken: accessToken,
      request: request,
    );

    if (result.success) {
      _message = 'PIN changed.';
      _isChangingPin = false;
      notifyListeners();
      return true;
    }

    _message = result.message ?? _messageForFailure(result.failure);
    _isChangingPin = false;
    notifyListeners();
    return false;
  }

  void clearMessage() {
    if (_message == null) return;

    _message = null;
    notifyListeners();
  }

  void reset() {
    _mentor = null;
    _isLoading = false;
    _isSaving = false;
    _isChangingPin = false;
    _message = null;
    notifyListeners();
  }

  String _messageForFailure(MentorProfileFailure? failure) {
    return switch (failure) {
      MentorProfileFailure.badRequest => 'Invalid profile data.',
      MentorProfileFailure.unauthorized => 'Login expired.',
      MentorProfileFailure.forbidden => 'Mentor access required.',
      MentorProfileFailure.conflict => 'Phone number already exists.',
      MentorProfileFailure.serverError => 'Server error.',
      MentorProfileFailure.networkError => 'Cannot connect to server.',
      null => 'Unknown error.',
    };
  }
}
