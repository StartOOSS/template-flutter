# Best Practices Guide

`template-flutter` is intended to be the golden standard starter for Flutter
apps that integrate with the `template-go` backend. This document explains the
practices that make it a strong reference point today and records the roadmap
for future enhancements so other teams can model their apps after it with
confidence.

## How to use this template
- Use the **Implemented practices** section as a checklist when evaluating or
  porting patterns to another Flutter app.
- Reference the **Planned improvements** list when contributing changes or
  borrowing ideas so you stay aligned with the template’s north star.
- Keep `README.md` in sync with this document so newcomers quickly understand
  why this repo represents production-ready standards.

## Implemented practices

### Architecture & ownership boundaries
- Widgets (`lib/app.dart`, `lib/features/.../presentation`) depend on
  repositories that encapsulate API and telemetry concerns.
- Domain models live under `lib/features/todos/models`, while data access lives
  under `lib/features/todos/data` for clear separation of responsibilities.
- Shared infrastructure (configuration, telemetry wrappers, widgets) is grouped
  under `lib/core/` so cross-cutting concerns stay reusable.

### Configuration & environment management
- `.env.mock`, `.env.dev`, `.env.preprod`, `.env.prod`, and `.env.example`
  provide curated configs; `--dart-define=APP_ENV=<env>` selects which file to
  load at runtime.
- `main.dart` auto-detects the right env file (preferring `.env.<env>` then
  `.env`/`.env.example`) so emulator workflows match CI.
- Make targets (`make setup`, `make run-*`, `make mock-api`) eliminate manual
  configuration steps and codify the required commands in one place.
- `AppConfig` validates API/OTLP URLs and service names, throwing
  `ConfigValidationException` errors that surface early in `main.dart` so
  misconfiguration never reaches runtime.

### Telemetry & observability
- `Telemetry.init` provisions OpenTelemetry tracer providers, registers
  resource attributes, and wraps the HTTP client (`TelemetryHttpClient`).
- Repository methods (`TodoRepository`) run inside `Telemetry.span` helpers to
  emit custom spans/metrics around CRUD events.
- Integration tests can toggle `USE_LIVE_API` to exercise real deployments
  while keeping deterministic mocked runs by default.
- Navigation spans are captured via `TelemetryNavigatorObserver`,
  `FlutterError.onError` is piped to OTLP, and CRUD spans emit user-centric
  events (`todo.created`, `todo.toggled`, `todo.deleted`).

### Testing strategy
- Unit and widget tests under `test/features/` cover repositories, API clients,
  and UI flows with HTTP mocks and telemetry overrides.
- `integration_test/todo_flow_test.dart` boots the reusable mock template-go
  server (or an optional live backend) so tests exercise the real HTTP client
  and telemetry pipeline end-to-end.
- CI uploads coverage via Codecov to monitor regressions and keeps bindings for
  e2e tests through `flutter test integration_test -d flutter-tester`.
- New unit tests validate configuration parsing and API error wrapping to guard
  against regressions in the hardened networking stack.

### Automation, CI/CD, and releases
- The `Makefile` mirrors CI jobs (`format`, `analyze`, `test`, `e2e`,
  `security`, `secrets`) so local developers run the exact gates.
- `.github/workflows/ci.yaml` enforces formatting, linting, unit + e2e testing,
  dependency freshness, Trivy FS scans, gitleaks, and dependency review.
- `release-please.yaml` + `release-build.yaml` automate semantic versioning,
  changelog generation, and release web builds packaged as artifacts.

### Security & quality signals
- Repository-level `analysis_options.yaml` augments `flutter_lints` with
  stricter rules (e.g., `avoid_print`, `unawaited_futures`).
- Security scanning combines `dart pub outdated`, SBOM-friendly
  `flutter pub deps --style=compact`, Trivy FS scans, and gitleaks secret
  detection.
- Documentation under `docs/microservice/` details security posture, incident
  response, and compliance milestones to align with the backend template.
- Dependabot keeps `pub` dependencies and GitHub Actions up to date on a weekly
  cadence for stronger supply-chain hygiene.

### Resilient networking & error surfacing
- HTTP traffic flows through `ResilientHttpClient`, adding timeouts, retries,
  and exponential backoff before telemetry instrumentation executes.
- `TodoApiClient` throws structured `TodoApiException`s for HTTP failures,
  timeouts, and client errors so presentation layers can react appropriately.

### Telemetry-aware UI shell
- `MaterialApp` registers `Telemetry.navigatorObserver` to emit spans on every
  navigation transition.
- Global `FlutterError` hooks record spans with exception metadata to bridge
  parity with backend traces.

## Planned improvements (priority order)

1. **State management & dependency injection**
   - Introduce a state container (Riverpod/BLoC) and providers for repositories
     so widgets stay declarative and easy to extend.

2. **Accessibility & localization**
   - Add localization scaffolding (`l10n.yaml`, `AppLocalizations`), translated
     strings, semantic labels, and accessibility acceptance tests.

3. **Offline readiness**
   - Cache todos locally (e.g., hydrated storage), support optimistic updates,
     and reconcile with the backend when connectivity returns.

4. **Broader test coverage**
   - Add golden/screenshot and performance tests plus nightly contract tests
     that hit live deployments.

5. **Security hardening**
   - Investigate TLS enforcement/cert pinning, secure token storage, and
     signing/distribution runbooks for mobile builds.
