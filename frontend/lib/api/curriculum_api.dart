import '_api_support.dart';
import 'api_result.dart';

import 'package:http/http.dart' as http;

import '../models/models.dart';

enum CurriculumFailure { serverError, networkError, invalidData }

class CurriculumCatalogResult
    extends ApiResult<CurriculumCatalog, CurriculumFailure> {
  @override
  String? get message => null;
  final CurriculumCatalog? catalog;
  @override
  final CurriculumFailure? failure;

  const CurriculumCatalogResult.success({required this.catalog})
    : failure = null;

  const CurriculumCatalogResult.failure({required this.failure})
    : catalog = null;
}

class CurriculumApi {
  final http.Client _client;

  CurriculumApi({http.Client? client}) : _client = client ?? http.Client();

  static const String _catalogUrl =
      'https://curriculum.afterschool-geekery.org/data/curriculum.json';

  Future<CurriculumCatalogResult> fetchCatalog() async {
    try {
      final response = await _client.get(Uri.parse(_catalogUrl));

      if (response.statusCode != 200) {
        return const CurriculumCatalogResult.failure(
          failure: CurriculumFailure.serverError,
        );
      }

      final data = decodeJsonBody(response.body);

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
    } catch (error) {
      if (isInvalidApiData(error)) {
        return const CurriculumCatalogResult.failure(
          failure: CurriculumFailure.invalidData,
        );
      }
      return const CurriculumCatalogResult.failure(
        failure: CurriculumFailure.networkError,
      );
    }
  }
}
