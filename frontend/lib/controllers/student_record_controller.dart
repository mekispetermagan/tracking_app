import 'feature_controller.dart';

import '../api/api.dart';
import '../models/models.dart';

class StudentRecordController extends FeatureController {
  final SharedStudentRecordApi _studentRecordApi;

  StudentRecordController({SharedStudentRecordApi? studentRecordApi})
    : _studentRecordApi = studentRecordApi ?? SharedStudentRecordApi();

  StudentRecord? _studentRecord;
  bool _isLoading = false;
  String? _message;

  StudentRecord? get studentRecord => _studentRecord;
  bool get isLoading => _isLoading;
  String? get message => _message;

  Future<bool> load({
    required String accessToken,
    required int studentId,
  }) async {
    final request = beginRequest();
    _studentRecord = null;
    _isLoading = true;
    _message = null;
    notifyListeners();

    final result = await _studentRecordApi.fetchStudentRecord(
      accessToken: accessToken,
      studentId: studentId,
    );

    if (!requestIsCurrent(request)) return false;

    if (result.studentRecord != null) {
      _studentRecord = result.studentRecord;
      _isLoading = false;
      notifyListeners();
      return true;
    }

    _message = result.message ?? _messageForFailure(result.failure);

    _isLoading = false;
    notifyListeners();
    return false;
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
    _studentRecord = null;
    _isLoading = false;
    _message = null;
    notifyListeners();
  }

  String _messageForFailure(SharedStudentRecordFailure? failure) {
    return switch (failure) {
      SharedStudentRecordFailure.unauthorized => 'Login expired.',
      SharedStudentRecordFailure.forbidden => 'Student record access denied.',
      SharedStudentRecordFailure.notFound => 'Student not found.',
      SharedStudentRecordFailure.serverError => 'Server error.',
      SharedStudentRecordFailure.networkError => 'Cannot connect to server.',
      null => 'Unknown error.',
    };
  }
}
