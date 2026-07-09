class ApiConfig {
  static const String debugBaseUrl = 'http://127.0.0.1:8000';

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: debugBaseUrl,
  );
}