import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:opentelemetry/api.dart' as otel_api;
import 'package:opentelemetry/sdk.dart' as otel_sdk;

import '../config/app_config.dart';

class Telemetry {
  static otel_api.Tracer tracer =
      otel_api.globalTracerProvider.getTracer('template_flutter');
  static late http.Client httpClient;

  static Future<void> init(
    AppConfig config, {
    http.Client? client,
    bool enableExporters = true,
  }) async {
    final resource = otel_sdk.Resource([
      otel_api.Attribute.fromString(
        otel_api.ResourceAttributes.serviceName,
        config.serviceName,
      ),
    ]);

    final traceProcessors = <otel_sdk.SpanProcessor>[];
    if (enableExporters) {
      traceProcessors.add(
        otel_sdk.BatchSpanProcessor(
          otel_sdk.CollectorExporter(
            Uri.parse('${config.otelEndpoint}/v1/traces'),
          ),
        ),
      );
    } else {
      traceProcessors
          .add(otel_sdk.SimpleSpanProcessor(otel_sdk.ConsoleExporter()));
    }

    final tracerProvider = otel_sdk.TracerProviderBase(
      processors: traceProcessors,
      resource: resource,
    );

    otel_api.registerGlobalTracerProvider(tracerProvider);
    tracer = tracerProvider.getTracer('template_flutter');

    httpClient = TelemetryHttpClient(client ?? http.Client());
  }

  /// Allows tests to supply a pre-configured HTTP client without
  /// reinitializing all telemetry exporters.
  static void overrideHttpClient(http.Client client) {
    httpClient = TelemetryHttpClient(client);
  }

  static Future<T> span<T>(
      String name, FutureOr<T> Function(otel_api.Span span) run) async {
    final span = tracer.startSpan(
      name,
      kind: otel_api.SpanKind.internal,
      attributes: [
        otel_api.Attribute.fromString('telemetry.library', 'template-flutter'),
      ],
    );
    try {
      return await run(span);
    } catch (error, stack) {
      span.recordException(error, stackTrace: stack);
      span.setStatus(otel_api.StatusCode.error, error.toString());
      rethrow;
    } finally {
      span.end();
    }
  }
}

class TelemetryHttpClient extends http.BaseClient {
  TelemetryHttpClient(this._delegate);

  final http.Client _delegate;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final span = Telemetry.tracer.startSpan(
      'HTTP ${request.method}',
      kind: otel_api.SpanKind.client,
      attributes: [
        otel_api.Attribute.fromString('http.method', request.method),
        otel_api.Attribute.fromString('http.url', request.url.toString()),
      ],
    );

    final stopwatch = Stopwatch()..start();
    try {
      final response = await _delegate.send(request);
      stopwatch.stop();
      span.setAttributes([
        otel_api.Attribute.fromInt('http.status_code', response.statusCode),
        otel_api.Attribute.fromString('http.host', request.url.host),
        otel_api.Attribute.fromInt(
            'http.duration_ms', stopwatch.elapsedMilliseconds),
      ]);
      if (response.statusCode >= 400) {
        span.setStatus(
            otel_api.StatusCode.error, 'HTTP ${response.statusCode}');
      } else {
        span.setStatus(otel_api.StatusCode.ok);
      }
      return response;
    } catch (error, stack) {
      stopwatch.stop();
      span.recordException(error, stackTrace: stack);
      span.setAttributes([
        otel_api.Attribute.fromString('http.method', request.method),
        otel_api.Attribute.fromString('http.host', request.url.host),
        otel_api.Attribute.fromInt(
            'http.duration_ms', stopwatch.elapsedMilliseconds),
      ]);
      span.setStatus(otel_api.StatusCode.error, error.toString());
      rethrow;
    } finally {
      span.end();
    }
  }
}
