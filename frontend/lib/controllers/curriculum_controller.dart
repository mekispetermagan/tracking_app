import 'feature_controller.dart';

import '../api/api.dart';
import '../models/models.dart';

class CurriculumController extends FeatureController {
  final CurriculumApi _curriculumApi;

  CurriculumController({CurriculumApi? curriculumApi})
    : _curriculumApi = curriculumApi ?? CurriculumApi();

  List<CurriculumCategory> _categories = [];
  CurriculumChapter? _selectedChapter;

  bool _isLoading = false;
  String? _message;

  List<CurriculumCategory> get categories {
    return List.unmodifiable(_categories);
  }

  CurriculumChapter? get selectedChapter => _selectedChapter;

  bool get isLoading => _isLoading;
  String? get message => _message;

  String? get selectedChapterUrl {
    final chapter = _selectedChapter;

    if (chapter == null) {
      return null;
    }

    return Uri.https('curriculum.afterschool-geekery.org', '/chapter.html', {
      'lang': 'eng',
      'chapter': chapter.slug,
    }).toString();
  }

  Future<void> initialize() async {
    _categories = [];
    _selectedChapter = null;
    _isLoading = false;
    _message = null;

    await _loadCatalog();
  }

  Future<void> reload() async {
    if (_isLoading) {
      return;
    }

    await _loadCatalog();
  }

  void selectChapter(CurriculumChapter chapter) {
    _selectedChapter = chapter;
    notifyListeners();
  }

  void closeChapter() {
    if (_selectedChapter == null) {
      return;
    }

    _selectedChapter = null;
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
    _categories = [];
    _selectedChapter = null;
    _isLoading = false;
    _message = null;
    notifyListeners();
  }

  Future<void> _loadCatalog() async {
    final request = beginRequest();
    _categories = [];
    _isLoading = true;
    _message = null;
    notifyListeners();

    final result = await _curriculumApi.fetchCatalog();

    if (!requestIsCurrent(request)) return;

    if (result.catalog != null) {
      _categories = result.catalog!.categories;
    } else {
      _message = _messageForFailure(result.failure);
    }

    _isLoading = false;
    notifyListeners();
  }

  String _messageForFailure(CurriculumFailure? failure) {
    return switch (failure) {
      CurriculumFailure.serverError => 'Curriculum server error.',
      CurriculumFailure.networkError =>
        'Cannot connect to the curriculum server.',
      CurriculumFailure.invalidData => 'Invalid curriculum data.',
      null => 'Unknown error.',
    };
  }
}
