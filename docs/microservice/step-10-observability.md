# Step 10 – Observability (Logging, Metrics, Tracing)

## Logging
- Use structured logs when adding logging; wire correlation IDs from backend responses if available.

## Metrics and tracing
- `lib/core/telemetry/telemetry.dart` initializes OpenTelemetry tracing and metrics with OTLP exporters.
- HTTP client spans include status/latency attributes; navigation emits spans for screen loads.
- Console exporters are used when OTLP endpoints are absent to keep instrumentation testable.
