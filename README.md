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

## Best practices
- **Golden standard:** This repo is the canonical reference for building
  production-ready Flutter frontends for the `template-go` backend—use it as
  inspiration when structuring new apps or modernizing existing ones.
- **Configuration & resiliency:** `AppConfig` validates critical env vars while
  `ResilientHttpClient` adds retries/timeouts and `TodoApiClient` throws typed
  errors for better UX.
- **Layered architecture:** `lib/core` houses shared config/telemetry utilities, while feature modules isolate models, data sources, and presentation widgets.
- **Telemetry-first development:** `Telemetry.init`, span helpers, and the custom HTTP client emit OpenTelemetry traces/metrics across API calls and navigation.
- **Defense-in-depth automation:** Make targets mirror CI, which enforces formatting, analysis, unit + e2e tests, dependency health, Trivy, and gitleaks scans.
- **Testing pyramid:** Repository, widget, and integration tests cover deterministic mocks with optional live API runs driven by dart-defines.
- **Documentation & governance:** Production-readiness milestones live under `docs/microservice/`, with semantic releases managed by Release Please and Dependabot keeping dependencies fresh.

See `docs/best-practices.md` for the full guide and the prioritized roadmap that keeps this template production ready.

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
2. Choose an environment file:
   - `.env.mock` – default mock API target for local dev (pairs with `make mock-api`).
   - `.env.dev`, `.env.preprod`, `.env.prod` – sample configs for remote stacks.
   - Copy the file you need to `.env` when running locally, or point the runtime to a specific file using `--dart-define=APP_ENV=<env>`.
3. Fetch dependencies and run the app:
   ```bash
   flutter pub get
   flutter run -d chrome --dart-define=APP_ENV=mock
   ```

### Environment profiles & mock backend
- `APP_ENV` selects which `.env.<env>` file (mock/dev/preprod/prod) is loaded at runtime.
- `make mock-api` (or `dart run tool/mock_template_go.dart --port=5050`) starts a lightweight mock of [`template-go`](https://github.com/StartOOSS/template-go) so emulators and browsers can exercise the full HTTP stack without hitting a real backend.
- Override run targets with `RUN_ARGS="--dart-define=APP_ENV=dev" make run-android` (or `preprod` / `prod`) to point the UI at downstream environments.

### Local run helpers
- `make run-web` – launches the Chrome/web build (`RUN_ARGS="--dart-define=APP_ENV=mock" make run-web`).
- `make run-ios` – runs the iOS simulator; ensure `flutter devices` lists a booted simulator/device first.
- `make run-android` – runs against the active Android emulator/device.

Set optional `RUN_ARGS` to pass additional flags/Dart defines (API env, feature flags, etc.) to any run target.

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

### End-to-end execution against mock and live deployments
Integration tests start the local mock template-go server by default so the real HTTP client, telemetry, and widget flows are exercised end-to-end. To validate against a deployed environment, pass dart-defines to point the suite at another base URL:

```bash
flutter test integration_test \
  --dart-define=USE_LIVE_API=true \
  --dart-define=API_BASE_URL=https://todo.example.com \
  --dart-define=APP_ENV=preprod
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
