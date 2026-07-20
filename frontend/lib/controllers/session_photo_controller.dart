import 'feature_controller.dart';
import 'package:image_picker/image_picker.dart';

import '../api/api.dart';
import '../models/models.dart';

class SessionPhotoController extends FeatureController {
  final SharedSessionPhotoApi _sharedPhotoApi;
  final MentorSessionPhotoApi _mentorPhotoApi;
  final SharedCourseApi _courseApi;
  final ImagePicker _imagePicker;

  SessionPhotoController({
    SharedSessionPhotoApi? sharedPhotoApi,
    MentorSessionPhotoApi? mentorPhotoApi,
    SharedCourseApi? courseApi,
    ImagePicker? imagePicker,
  }) : _sharedPhotoApi = sharedPhotoApi ?? SharedSessionPhotoApi(),
       _mentorPhotoApi = mentorPhotoApi ?? MentorSessionPhotoApi(),
       _courseApi = courseApi ?? SharedCourseApi(),
       _imagePicker = imagePicker ?? ImagePicker();

  List<SessionPhoto> _photos = [];
  List<XFile> _selectedPhotos = [];
  List<Course> _courses = [];

  int? _selectedCourseId;

  bool _isLoading = false;
  bool _isSelecting = false;
  bool _isUploading = false;
  String? _message;

  List<SessionPhoto> get photos => List.unmodifiable(_photos);

  List<XFile> get selectedPhotos => List.unmodifiable(_selectedPhotos);

  List<Course> get courses => List.unmodifiable(_courses);

  int? get selectedCourseId => _selectedCourseId;

  bool get isLoading => _isLoading;
  bool get isSelecting => _isSelecting;
  bool get isUploading => _isUploading;
  String? get message => _message;

  Course? get selectedCourse {
    final courseId = _selectedCourseId;

    if (courseId == null) {
      return null;
    }

    for (final course in _courses) {
      if (course.id == courseId) {
        return course;
      }
    }

    return null;
  }

  bool get canViewCourse => selectedCourse != null && !_isLoading;

  bool get canUpload =>
      _selectedPhotos.length == 3 &&
      !_isLoading &&
      !_isSelecting &&
      !_isUploading;

  Future<void> initializeCourseSelection({required String accessToken}) async {
    final request = beginRequest();
    _courses = [];
    _selectedCourseId = null;
    _photos = [];
    _selectedPhotos = [];
    _isLoading = true;
    _message = null;
    notifyListeners();

    final result = await _courseApi.fetchCourses(
      accessToken: accessToken,
      activeOnly: false,
    );

    if (!requestIsCurrent(request)) return;

    if (result.courses != null) {
      _courses = result.courses!..sort((a, b) => a.name.compareTo(b.name));
    } else {
      _message = result.message ?? _messageForCourseFailure(result.failure);
    }

    _isLoading = false;
    notifyListeners();
  }

  void selectCourse(int courseId) {
    if (_isLoading ||
        _selectedCourseId == courseId ||
        !_courses.any((course) => course.id == courseId)) {
      return;
    }

    _selectedCourseId = courseId;
    _message = null;
    notifyListeners();
  }

  Future<bool> loadSelectedCoursePhotos({required String accessToken}) async {
    final courseId = _selectedCourseId;

    if (courseId == null) {
      _message = 'Select a course.';
      notifyListeners();
      return false;
    }

    await loadCoursePhotos(accessToken: accessToken, courseId: courseId);

    return _message == null;
  }

  bool hasSubmissionForMentor(int mentorProfileId) {
    return _photos.any((photo) => photo.mentorProfileId == mentorProfileId);
  }

  List<SessionPhoto> photosForMentor(int mentorProfileId) {
    final result = _photos
        .where((photo) => photo.mentorProfileId == mentorProfileId)
        .toList();

    result.sort((a, b) => a.photoNumber.compareTo(b.photoNumber));

    return result;
  }

  Future<void> loadSessionPhotos({
    required String accessToken,
    required int sessionLogId,
  }) async {
    final request = _startLoading();

    final result = await _sharedPhotoApi.fetchSessionPhotos(
      accessToken: accessToken,
      sessionLogId: sessionLogId,
    );

    if (!requestIsCurrent(request)) return;
    _finishLoading(result);
  }

  Future<void> loadCoursePhotos({
    required String accessToken,
    required int courseId,
  }) async {
    final request = _startLoading();

    final result = await _sharedPhotoApi.fetchCoursePhotos(
      accessToken: accessToken,
      courseId: courseId,
    );

    if (!requestIsCurrent(request)) return;
    _finishLoading(result);
  }

  Future<void> selectPhotos() async {
    if (_isLoading || _isSelecting || _isUploading) {
      return;
    }

    final request = beginRequest();
    _isSelecting = true;
    _message = null;
    notifyListeners();

    try {
      final selected = await _imagePicker.pickMultiImage();

      if (!requestIsCurrent(request)) return;

      if (selected.isEmpty) {
        _isSelecting = false;
        notifyListeners();
        return;
      }

      if (selected.length != 3) {
        _selectedPhotos = [];
        _message = 'Select exactly three photos.';
        _isSelecting = false;
        notifyListeners();
        return;
      }

      _selectedPhotos = selected;
      _isSelecting = false;
      notifyListeners();
    } catch (_) {
      _selectedPhotos = [];
      _message = 'Could not select photos.';
      _isSelecting = false;
      notifyListeners();
    }
  }

  void clearSelection() {
    if (_selectedPhotos.isEmpty || _isUploading) {
      return;
    }

    _selectedPhotos = [];
    _message = null;
    notifyListeners();
  }

  Future<bool> uploadPhotos({
    required String accessToken,
    required int sessionLogId,
    required int mentorProfileId,
  }) async {
    if (_selectedPhotos.length != 3) {
      _message = 'Select exactly three photos.';
      notifyListeners();
      return false;
    }

    if (hasSubmissionForMentor(mentorProfileId)) {
      _message =
          'You have already submitted photos '
          'for this session.';
      notifyListeners();
      return false;
    }

    if (_isLoading || _isSelecting || _isUploading) {
      return false;
    }

    final request = beginRequest();
    _isUploading = true;
    _message = null;
    notifyListeners();

    final result = await _mentorPhotoApi.submitSessionPhotos(
      accessToken: accessToken,
      sessionLogId: sessionLogId,
      photoPaths: [for (final photo in _selectedPhotos) photo.path],
    );

    if (!requestIsCurrent(request)) return false;

    if (result.photos != null) {
      _photos = [..._photos, ...result.photos!];

      _selectedPhotos = [];
      _isUploading = false;
      notifyListeners();
      return true;
    }

    _message = result.message ?? _messageForUploadFailure(result.failure);

    _isUploading = false;
    notifyListeners();
    return false;
  }

  void closeGallery() {
    invalidateRequests();
    _photos = [];
    _selectedPhotos = [];
    _isLoading = false;
    _isSelecting = false;
    _isUploading = false;
    _message = null;
    notifyListeners();
  }

  void clearMessage() {
    if (_message == null) {
      return;
    }

    _message = null;
    notifyListeners();
  }

  void reset() {
    invalidateRequests();
    _photos = [];
    _selectedPhotos = [];
    _courses = [];
    _selectedCourseId = null;
    _isLoading = false;
    _isSelecting = false;
    _isUploading = false;
    _message = null;
    notifyListeners();
  }

  int _startLoading() {
    final request = beginRequest();
    _photos = [];
    _selectedPhotos = [];
    _isLoading = true;
    _message = null;
    notifyListeners();
    return request;
  }

  void _finishLoading(SharedSessionPhotoListResult result) {
    if (result.photos != null) {
      _photos = result.photos!;
      _message = null;
    } else {
      _photos = [];
      _message = result.message ?? _messageForLoadingFailure(result.failure);
    }

    _isLoading = false;
    notifyListeners();
  }

  String _messageForLoadingFailure(SharedSessionPhotoFailure? failure) {
    return switch (failure) {
      SharedSessionPhotoFailure.badRequest => 'Invalid photo request.',
      SharedSessionPhotoFailure.unauthorized => 'Login expired.',
      SharedSessionPhotoFailure.forbidden => 'Photo access denied.',
      SharedSessionPhotoFailure.notFound => 'Session or course not found.',
      SharedSessionPhotoFailure.serverError => 'Server error.',
      SharedSessionPhotoFailure.networkError => 'Cannot connect to server.',
      null => 'Unknown error.',
    };
  }

  String _messageForUploadFailure(MentorSessionPhotoFailure? failure) {
    return switch (failure) {
      MentorSessionPhotoFailure.badRequest =>
        'Exactly three valid photos are required.',
      MentorSessionPhotoFailure.unauthorized => 'Login expired.',
      MentorSessionPhotoFailure.forbidden =>
        'You did not participate in this session.',
      MentorSessionPhotoFailure.notFound => 'Session log not found.',
      MentorSessionPhotoFailure.conflict =>
        'Photos have already been submitted.',
      MentorSessionPhotoFailure.serverError => 'Server error.',
      MentorSessionPhotoFailure.networkError => 'Cannot connect to server.',
      null => 'Unknown error.',
    };
  }

  String _messageForCourseFailure(SharedCourseFailure? failure) {
    return switch (failure) {
      SharedCourseFailure.badRequest => 'Invalid course request.',
      SharedCourseFailure.unauthorized => 'Login expired.',
      SharedCourseFailure.forbidden => 'Course access denied.',
      SharedCourseFailure.notFound => 'Course not found.',
      SharedCourseFailure.conflict => 'Course conflict.',
      SharedCourseFailure.serverError => 'Server error.',
      SharedCourseFailure.networkError => 'Cannot connect to server.',
      null => 'Unknown error.',
    };
  }
}
