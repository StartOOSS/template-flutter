import 'package:flutter_dotenv/flutter_dotenv.dart';

class ConfigValidationException implements Exception {
  ConfigValidationException(this.message);

  final String message;

  @override
  String toString() => 'ConfigValidationException: $message';
}

class AppConfig {
  const AppConfig({
    required this.apiBaseUrl,
    required this.otelEndpoint,
    required this.serviceName,
  });

  final String apiBaseUrl;
  final String otelEndpoint;
  final String serviceName;

  factory AppConfig.fromEnv({Map<String, String?>? overrides}) {
    final env = overrides ?? dotenv.env;
    return AppConfig.fromMap(env);
  }

  factory AppConfig.fromMap(Map<String, String?> env) {
    final apiBaseUrl = env['API_BASE_URL'] ?? 'http://localhost:8080';
    final otlpEndpoint =
        env['OTEL_EXPORTER_OTLP_ENDPOINT'] ?? 'http://localhost:4318';
    final serviceName = env['OTEL_SERVICE_NAME'] ?? 'template-flutter';

    return AppConfig(
      apiBaseUrl: _validatedUrl(apiBaseUrl, 'API_BASE_URL'),
      otelEndpoint: _validatedUrl(otlpEndpoint, 'OTEL_EXPORTER_OTLP_ENDPOINT'),
      serviceName: _requireNonEmpty(serviceName, 'OTEL_SERVICE_NAME'),
    );
  }

  static String _validatedUrl(String value, String key) {
    final trimmed = value.trim();
    final uri = Uri.tryParse(trimmed);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      throw ConfigValidationException(
        '$key must be an absolute http(s) URL. See README.md for details.',
      );
    }
    if (uri.scheme != 'http' && uri.scheme != 'https') {
      throw ConfigValidationException(
        '$key must use http or https schemes.',
      );
    }
    return trimmed;
  }

  static String _requireNonEmpty(String value, String key) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      throw ConfigValidationException('$key cannot be empty.');
    }
    return trimmed;
  }
}
