import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:opentelemetry/api.dart' as otel_api;
import 'package:opentelemetry/sdk.dart' as otel_sdk;

import '../config/app_config.dart';
import '../network/resilient_http_client.dart';

class Telemetry {
  static otel_api.Tracer tracer =
      otel_api.globalTracerProvider.getTracer('template_flutter');
  static late http.Client httpClient;
  static final TelemetryNavigatorObserver navigatorObserver =
      TelemetryNavigatorObserver();
  static FlutterExceptionHandler? _originalFlutterErrorHandler;

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

    final resilientClient = ResilientHttpClient(client ?? http.Client());
    httpClient = TelemetryHttpClient(resilientClient);
    _installFlutterErrorHandler();
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
      span
        ..recordException(error, stackTrace: stack)
        ..setStatus(otel_api.StatusCode.error, error.toString());
      rethrow;
    } finally {
      span.end();
    }
  }
}

void _recordFlutterError(FlutterErrorDetails details) {
  final span = Telemetry.tracer.startSpan(
    'flutter.error',
    attributes: [
      otel_api.Attribute.fromString(
          'error.exception_as_string', details.exceptionAsString()),
      if (details.library != null)
        otel_api.Attribute.fromString('error.library', details.library!),
    ],
  );
  final stack = details.stack;
  if (stack != null) {
    span.recordException(details.exception, stackTrace: stack);
  } else {
    span.recordException(details.exception);
  }
  span.setStatus(otel_api.StatusCode.error, 'FlutterError');
  span.end();
}

void _installFlutterErrorHandler() {
  Telemetry._originalFlutterErrorHandler ??= FlutterError.onError;
  FlutterError.onError = (details) {
    _recordFlutterError(details);
    Telemetry._originalFlutterErrorHandler?.call(details);
  };
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
      span
        ..recordException(error, stackTrace: stack)
        ..setAttributes([
          otel_api.Attribute.fromString('http.method', request.method),
          otel_api.Attribute.fromString('http.host', request.url.host),
          otel_api.Attribute.fromInt(
              'http.duration_ms', stopwatch.elapsedMilliseconds),
        ])
        ..setStatus(otel_api.StatusCode.error, error.toString());
      rethrow;
    } finally {
      span.end();
    }
  }
}

class TelemetryNavigatorObserver extends NavigatorObserver {
  final Map<Route<dynamic>, otel_api.Span> _routeSpans = {};

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _startSpan(route, action: 'push', previous: previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (oldRoute != null) {
      _endSpan(oldRoute, action: 'replace');
    }
    if (newRoute != null) {
      _startSpan(newRoute, action: 'replace');
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _endSpan(route, action: 'pop');
  }

  void _startSpan(Route<dynamic> route,
      {required String action, Route<dynamic>? previous}) {
    final routeName = route.settings.name ?? route.runtimeType.toString();
    final previousName =
        previous?.settings.name ?? previous?.runtimeType.toString();
    final span = Telemetry.tracer.startSpan(
      'Navigation $routeName',
      attributes: [
        otel_api.Attribute.fromString('navigation.action', action),
        if (previousName != null)
          otel_api.Attribute.fromString('navigation.previous', previousName),
      ],
    );
    _routeSpans[route] = span;
  }

  void _endSpan(Route<dynamic> route, {required String action}) {
    final span = _routeSpans.remove(route);
    span?.setAttribute(
      otel_api.Attribute.fromString('navigation.complete_action', action),
    );
    span?.end();
  }
}
