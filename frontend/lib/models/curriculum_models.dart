class CurriculumCatalog {
  final List<CurriculumCategory> categories;

  const CurriculumCatalog({required this.categories});

  factory CurriculumCatalog.fromJson(Map<String, dynamic> json) {
    return CurriculumCatalog(
      categories: (json['categories'] as List<dynamic>)
          .map(
            (item) => CurriculumCategory.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
    );
  }
}

class CurriculumCategory {
  final String slug;
  final Map<String, String> titles;
  final List<CurriculumChapter> chapters;

  const CurriculumCategory({
    required this.slug,
    required this.titles,
    required this.chapters,
  });

  String get englishTitle => titles['eng'] ?? slug;

  factory CurriculumCategory.fromJson(Map<String, dynamic> json) {
    return CurriculumCategory(
      slug: json['id'] as String,
      titles: Map<String, String>.from(json['titles'] as Map),
      chapters: (json['chapters'] as List<dynamic>)
          .map(
            (item) => CurriculumChapter.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
    );
  }
}

class CurriculumChapter {
  final String slug;
  final Map<String, String> titles;

  const CurriculumChapter({required this.slug, required this.titles});

  String get englishTitle => titles['eng'] ?? slug;

  factory CurriculumChapter.fromJson(Map<String, dynamic> json) {
    return CurriculumChapter(
      slug: json['slug'] as String,
      titles: Map<String, String>.from(json['titles'] as Map),
    );
  }
}
