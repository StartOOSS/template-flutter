# Step 11 – Health Checks & Readiness Probes

## Signals
- The frontend relies on backend `/livez` and `/readyz` (from template-go) before calling APIs.
- UI surfaces connectivity failures via `AsyncError`; telemetry records failed spans for alert correlation.

## Shutdown
- Flutter apps gracefully pause/resume; for web builds, rely on hosting platform graceful shutdown and CDN cache invalidation.
