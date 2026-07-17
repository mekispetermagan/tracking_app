class ApiConfig {
  // normal dev: local hosting
  static const String debugBaseUrl = 'http://127.0.0.1:8000';
  // demo: hosting from server
  // static const String debugBaseUrl = 'https://tracking.mekis.dev';
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: debugBaseUrl,
  );
}
