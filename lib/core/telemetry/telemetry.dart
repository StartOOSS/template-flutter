import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:opentelemetry/api.dart' as otel_api;
import 'package:opentelemetry/exporter_otlp.dart';
import 'package:opentelemetry/sdk.dart' as otel_sdk;

import '../config/app_config.dart';

class Telemetry {
  static otel_api.Tracer tracer = otel_api.traceProvider.getTracer('template_flutter');
  static otel_api.Meter meter = otel_api.meterProvider.getMeter('template_flutter');
  static late http.Client httpClient;

  static Future<void> init(
    AppConfig config, {
    http.Client? client,
    bool enableExporters = true,
  }) async {
    final resource = otel_sdk.Resource(attributes: {
      otel_api.resourceServiceNameKey: config.serviceName,
    });

    final traceProcessors = <otel_sdk.SpanProcessor>[];
    if (enableExporters) {
      traceProcessors.add(
        otel_sdk.BatchSpanProcessor(
          otel_otlp.OtlpHttpTraceExporter(
            endpoint: Uri.parse('${config.otelEndpoint}/v1/traces'),
          ),
        ),
      );
    }

    final tracerProvider = otel_sdk.TracerProvider(
      resource: resource,
      processors: traceProcessors,
    );

    otel_api.registerGlobalTracerProvider(tracerProvider);
    tracer = tracerProvider.getTracer('template_flutter');

    final readers = <otel_sdk.MetricReader>[];
    if (enableExporters) {
      readers.add(
        otel_sdk.PeriodicMetricReader(
          exporter: otel_otlp.OtlpHttpMetricExporter(
            endpoint: Uri.parse('${config.otelEndpoint}/v1/metrics'),
          ),
        ),
      );
    }

    final meterProvider = otel_sdk.MeterProvider(
      resource: resource,
      readers: readers,
    );

    otel_api.setGlobalMeterProvider(meterProvider);
    meter = meterProvider.getMeter('template_flutter');

    httpClient = TelemetryHttpClient(client ?? http.Client());
  }

  /// Allows tests to supply a pre-configured HTTP client without
  /// reinitializing all telemetry exporters.
  static void overrideHttpClient(http.Client client) {
    httpClient = TelemetryHttpClient(client);
  }

  static Future<T> span<T>(String name, FutureOr<T> Function(otel_api.Span span) run) async {
    final span = tracer.startSpan(name);
    try {
      return await run(span);
    } catch (error, stack) {
      span.recordException(error, stackTrace: stack);
      span.setStatus(otel_api.SpanStatus.error(error.toString()));
      rethrow;
    } finally {
      span.end();
    }
  }
}

class TelemetryHttpClient extends http.BaseClient {
  TelemetryHttpClient(this._delegate) {
    _latencyHistogram = Telemetry.meter.createHistogram<double>(
      name: 'http.client.duration',
      description: 'Latency of HTTP client requests',
      unit: 'ms',
    );
    _requestCounter = Telemetry.meter.createCounter<int>(
      name: 'http.client.requests',
      description: 'Count of HTTP client requests',
    );
  }

  final http.Client _delegate;
  late final otel_api.Counter<int> _requestCounter;
  late final otel_api.Histogram<double> _latencyHistogram;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final span = Telemetry.tracer.startSpan('HTTP ${request.method}');
    span.setAttribute(otel_api.Attribute.fromString('http.method', request.method));
    span.setAttribute(otel_api.Attribute.fromString('http.url', request.url.toString()));

    final stopwatch = Stopwatch()..start();
    try {
      final response = await _delegate.send(request);
      stopwatch.stop();
      span.setAttribute(otel_api.Attribute.fromInt('http.status_code', response.statusCode));
      if (response.statusCode >= 400) {
        span.setStatus(otel_api.SpanStatus.error('HTTP ${response.statusCode}'));
      }
      _recordMetrics(request, response.statusCode, stopwatch.elapsedMilliseconds.toDouble());
      return response;
    } catch (error, stack) {
      stopwatch.stop();
      span.recordException(error, stackTrace: stack);
      span.setStatus(otel_api.SpanStatus.error(error.toString()));
      _recordMetrics(request, 500, stopwatch.elapsedMilliseconds.toDouble());
      rethrow;
    } finally {
      span.end();
    }
  }

  void _recordMetrics(http.BaseRequest request, int statusCode, double durationMs) {
    _requestCounter.add(1, attributes: [
      otel_api.Attribute.fromString('http.method', request.method),
      otel_api.Attribute.fromString('http.host', request.url.host),
      otel_api.Attribute.fromInt('http.status_code', statusCode),
    ]);
    _latencyHistogram.record(durationMs, attributes: [
      otel_api.Attribute.fromString('http.method', request.method),
      otel_api.Attribute.fromString('http.host', request.url.host),
      otel_api.Attribute.fromInt('http.status_code', statusCode),
    ]);
  }
}
