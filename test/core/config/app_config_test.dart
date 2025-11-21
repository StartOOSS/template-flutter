import 'package:flutter_test/flutter_test.dart';
import 'package:template_flutter/core/config/app_config.dart';

void main() {
  group('AppConfig', () {
    test('creates config from env map', () {
      final config = AppConfig.fromEnv(
        overrides: {
          'API_BASE_URL': 'https://example.com',
          'OTEL_EXPORTER_OTLP_ENDPOINT': 'https://otel.dev',
          'OTEL_SERVICE_NAME': 'test-service',
          'APP_ENV': 'dev',
        },
      );

      expect(config.apiBaseUrl, 'https://example.com');
      expect(config.otelEndpoint, 'https://otel.dev');
      expect(config.serviceName, 'test-service');
      expect(config.environment, 'dev');
    });

    test('throws when the API URL is invalid', () {
      expect(
        () => AppConfig.fromEnv(
          overrides: {'API_BASE_URL': 'invalid-url'},
        ),
        throwsA(isA<ConfigValidationException>()),
      );
    });
  });
}
