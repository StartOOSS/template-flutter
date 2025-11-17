import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  const AppConfig({
    required this.apiBaseUrl,
    required this.otelEndpoint,
    required this.serviceName,
  });

  final String apiBaseUrl;
  final String otelEndpoint;
  final String serviceName;

  factory AppConfig.fromEnv() {
    final env = dotenv.env;
    return AppConfig(
      apiBaseUrl: env['API_BASE_URL'] ?? 'http://localhost:8080',
      otelEndpoint: env['OTEL_EXPORTER_OTLP_ENDPOINT'] ?? 'http://localhost:4318',
      serviceName: env['OTEL_SERVICE_NAME'] ?? 'template-flutter',
    );
  }
}
