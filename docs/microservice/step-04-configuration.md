# Step 04 – Configuration & Environment Management

## Layered loading
- Configuration is centralized in `lib/core/config/app_config.dart` and hydrated from `.env` using `flutter_dotenv` with sane defaults.
- Precedence: runtime environment > `.env` file > baked-in defaults.

## Secrets handling
- Secrets are not committed; `.env` is gitignored and `.env.example` documents required values.
- CI secret scanning via Gitleaks prevents accidental commits.

## Fail-fast behavior
- Missing `API_BASE_URL` triggers errors when HTTP calls are attempted; telemetry initialization logs missing exporter URLs and falls back to console exporters to avoid crashes while keeping observability signals available.
