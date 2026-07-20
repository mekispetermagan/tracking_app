import 'feature_controller.dart';

import '../api/api.dart';
import '../models/models.dart';
import 'student_record_controller.dart';

enum TrackStudentsView { list, record }

class TrackStudentsController extends FeatureController {
  final SharedStudentApi _studentApi;

  TrackStudentsController({
    SharedStudentApi? studentApi,
    SharedStudentRecordApi? studentRecordApi,
  }) : _studentApi = studentApi ?? SharedStudentApi(),
       recordController = StudentRecordController(
         studentRecordApi: studentRecordApi,
       );

  final StudentRecordController recordController;

  List<Student> _students = [];
  TrackStudentsView _view = TrackStudentsView.list;

  int? _selectedStudentId;
  bool _isLoading = false;
  String? _message;

  List<Student> get students => List.unmodifiable(_students);

  TrackStudentsView get view => _view;
  int? get selectedStudentId => _selectedStudentId;
  bool get isLoading => _isLoading;
  String? get message => _message;

  Student? get selectedStudent {
    final studentId = _selectedStudentId;

    if (studentId == null) {
      return null;
    }

    for (final student in _students) {
      if (student.id == studentId) {
        return student;
      }
    }

    return null;
  }

  bool get canView => selectedStudent != null && !_isLoading;

  Future<void> openList({required String accessToken}) async {
    final request = beginRequest();
    _view = TrackStudentsView.list;
    _selectedStudentId = null;
    _students = [];
    _isLoading = true;
    _message = null;
    recordController.reset();
    notifyListeners();

    final result = await _studentApi.fetchStudents(
      accessToken: accessToken,
      activeOnly: false,
    );

    if (!requestIsCurrent(request)) return;

    if (result.students == null) {
      _message = result.message ?? _messageForStudentFailure(result.failure);
      _isLoading = false;
      notifyListeners();
      return;
    }

    _students = result.students!;
    _isLoading = false;
    notifyListeners();
  }

  void selectStudent(int studentId) {
    if (_isLoading ||
        _selectedStudentId == studentId ||
        !_students.any((student) => student.id == studentId)) {
      return;
    }

    _selectedStudentId = studentId;
    _message = null;
    notifyListeners();
  }

  Future<void> openSelectedStudentRecord({required String accessToken}) async {
    final student = selectedStudent;

    if (student == null) {
      _message = 'No student selected.';
      notifyListeners();
      return;
    }

    await openStudentRecord(accessToken: accessToken, studentId: student.id);
  }

  Future<void> openStudentRecord({
    required String accessToken,
    required int studentId,
  }) async {
    final studentExists = _students.any((student) => student.id == studentId);

    if (!studentExists) {
      _message = 'Student not available.';
      notifyListeners();
      return;
    }

    _selectedStudentId = studentId;
    _view = TrackStudentsView.record;
    _message = null;
    notifyListeners();

    await recordController.load(accessToken: accessToken, studentId: studentId);
  }

  void closeRecord() {
    _view = TrackStudentsView.list;
    recordController.reset();
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
    _students = [];
    _view = TrackStudentsView.list;
    _selectedStudentId = null;
    _isLoading = false;
    _message = null;
    recordController.reset();
    notifyListeners();
  }

  String _messageForStudentFailure(SharedStudentFailure? failure) {
    return switch (failure) {
      SharedStudentFailure.badRequest => 'Invalid student request.',
      SharedStudentFailure.unauthorized => 'Login expired.',
      SharedStudentFailure.forbidden => 'Student access denied.',
      SharedStudentFailure.notFound => 'Student not found.',
      SharedStudentFailure.conflict => 'Student conflict.',
      SharedStudentFailure.serverError => 'Server error.',
      SharedStudentFailure.networkError => 'Cannot connect to server.',
      null => 'Unknown error.',
    };
  }

  @override
  void dispose() {
    recordController.dispose();
    super.dispose();
  }
}
