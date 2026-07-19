import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/models.dart';

enum CurriculumFailure { serverError, networkError, invalidData }

class CurriculumCatalogResult {
  final CurriculumCatalog? catalog;
  final CurriculumFailure? failure;

  const CurriculumCatalogResult.success({required this.catalog})
    : failure = null;

  const CurriculumCatalogResult.failure({required this.failure})
    : catalog = null;
}

class CurriculumApi {
  static const String _catalogUrl =
      'https://curriculum.afterschool-geekery.org/data/curriculum.json';

  Future<CurriculumCatalogResult> fetchCatalog() async {
    try {
      final response = await http.get(Uri.parse(_catalogUrl));

      if (response.statusCode != 200) {
        return const CurriculumCatalogResult.failure(
          failure: CurriculumFailure.serverError,
        );
      }

      final data = jsonDecode(response.body);

      if (data is! Map<String, dynamic>) {
        return const CurriculumCatalogResult.failure(
          failure: CurriculumFailure.invalidData,
        );
      }

      return CurriculumCatalogResult.success(
        catalog: CurriculumCatalog.fromJson(data),
      );
    } on FormatException {
      return const CurriculumCatalogResult.failure(
        failure: CurriculumFailure.invalidData,
      );
    } catch (_) {
      return const CurriculumCatalogResult.failure(
        failure: CurriculumFailure.networkError,
      );
    }
  }
}
