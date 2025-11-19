# Step 01 – Project Scaffolding & Architecture

## Service scope and dependencies
- Flutter frontend for the `template-go` Todo API (CRUD todos, toggle completion, delete) with OpenTelemetry telemetry to correlate with backend traces.
- Outbound dependency: the REST API base URL configured via `API_BASE_URL` in `.env`.
- Observability dependency: OTLP collector endpoint configured via `OTEL_EXPORTER_OTLP_ENDPOINT`.

## Discovery and routing
- Network entry points are defined by Flutter platform hosts (web origin, mobile package ID) and the API base URL.
- The repository README documents API paths; environment-driven configuration keeps routing centralized in `lib/core/config/app_config.dart`.

## Redundancy and availability expectations
- Frontend assets can be served from a CDN or static site host with multiple replicas; mobile builds are distributed through app stores with rollout controls.
- Avoid single points of failure by:
  - Hosting at least two instances per availability zone for the web build.
  - Relying on the API health/readiness endpoints (from template-go) to gate traffic; the Flutter client surfaces errors via `AsyncError` widget to fail fast.
