# template-flutter

A Flutter template that pairs with the [`template-go`](https://github.com/spacetj/template-go) Todo API to demonstrate best practices for developing, testing, scanning, linting, observing, and deploying a production-ready mobile/web Flutter app. The project ships with OpenTelemetry instrumentation for HTTP client calls, navigation, and custom events so the UI can be correlated with backend spans and metrics.

## Features
- **Todo frontend** that consumes the `template-go` REST API for creating, reading, updating, and deleting todo items.
- **OpenTelemetry metrics & tracing** with automatic HTTP instrumentation and screen-level spans.
- **Environment-driven configuration** using `.env` files for API base URLs and telemetry exporters.
- **Opinionated linting** via `flutter_lints` plus repo-level analysis options.
- **Testing-ready** with unit tests for repositories, widgets, and integration/e2e flows backed by mocked HTTP clients.
- **Security & quality gates** via GitHub Actions (lint, test, formatting, dependency checks, SCA scanning, secret scanning).
- **Container-friendly** for CI runners and local dev with Makefile helpers.

## Project structure
- `lib/`
  - `app.dart`: Root widget with navigation and theming.
  - `main.dart`: Bootstraps configuration, telemetry, and the app.
  - `core/`:
    - `config/app_config.dart`: Loads configuration from environment variables.
    - `telemetry/telemetry.dart`: Sets up OpenTelemetry tracing/metrics and wraps the HTTP client.
  - `features/todos/`: Domain-specific code for the Todo feature (models, data, presentation).
- `test/`: Unit and widget tests.
- `.github/workflows/`: CI pipelines for formatting, linting, testing, and security scanning.

## Getting started
1. Install Flutter (stable channel) and Dart.
2. Copy `.env.example` to `.env` (the app will fall back to `.env.example` in CI if `.env` is absent) and set the following:
   - `API_BASE_URL`: Base URL of the `template-go` API (e.g., `http://localhost:8080`).
   - `OTEL_EXPORTER_OTLP_ENDPOINT`: OTLP collector endpoint (e.g., `http://localhost:4318`).
   - `OTEL_SERVICE_NAME`: Service name for traces/metrics (defaults to `template-flutter`).
3. Fetch dependencies and run the app:
   ```bash
   flutter pub get
   flutter run -d chrome # or ios/android target
   ```

## API integration
The UI assumes the `template-go` Todo endpoints:
- `GET /api/v1/todos`: List todos.
- `POST /api/v1/todos`: Create a todo with `{ "title": string }`.
- `PUT /api/v1/todos/{id}`: Update a todo with `{ "title": string, "completed": bool }`.
- `DELETE /api/v1/todos/{id}`: Remove a todo.

Configure CORS in the backend to allow the app origin when running on web.

## Quality gates
- `make format` – enforce Dart formatting.
- `make analyze` – run static analysis using `flutter analyze`.
- `make test` – run all unit/widget tests.
- `make e2e` – run integration tests under `integration_test/`.
- `make security` – dependency and SCA checks via `dart pub outdated` and `flutter pub deps --style=compact` for SBOM-friendly output.
- `make secrets` – gitleaks scan for committed secrets (uses Docker when available and falls back to a downloaded binary otherwise).
- `make check` – run the full suite locally.
- `make all` – install dependencies and run every check in the same order CI executes.

### End-to-end execution against live deployments
The default integration test suite uses a mocked HTTP client for deterministic runs in CI. To run the same UI flow against a deployed `template-go` instance (for example, before auto-merging dependency bumps), pass dart-defines to enable the live API:

```bash
flutter test integration_test \
  --dart-define=USE_LIVE_API=true \
  --dart-define=API_BASE_URL=https://todo.example.com
```

## Versioning and releases
- Versions are managed by [Release Please](https://github.com/googleapis/release-please) using semantic commit messages. The workflow opens PRs that bump `pubspec.yaml`, update the manifest, and append to `CHANGELOG.md`.
- Publishing a GitHub Release (or running the workflow manually) triggers the **Release Build** pipeline, which reruns formatting, analysis, unit tests, end-to-end tests, and produces a release-ready `build/web.tar.gz` asset attached to the release.
- The current version is tracked in `.release-please-manifest.json` and the changelog.

## Telemetry
- Tracing and metrics are initialized in `main.dart` via `Telemetry.init`.
- HTTP requests made by `TodoApiClient` are automatically wrapped in spans and emit metrics for latency and status codes.
- Navigation events create spans so you can correlate screen load times with backend calls.
- OTLP exporter configuration is read from `.env` and defaults to console exporters when unset.

## Microservice milestone alignment
This template documents how it satisfies the production-readiness milestones from the companion backend. See `docs/microservice/` for step-by-step guidance across architecture, API contract, dependency management, security, testing, observability, deployment, and on-call readiness.

## Deployment
- CI builds run on every push/PR to validate formatting, linting, tests, e2e flows, and security checks.
- Artifacts (web build) can be produced with `flutter build web` and deployed to a static host.
- Mobile builds should add platform-specific signing configs before releasing.

## Contributing
- Keep changes small and covered by tests.
- Run the Make targets locally before opening a PR.
- Follow the lint rules and avoid suppressing warnings unless justified.

