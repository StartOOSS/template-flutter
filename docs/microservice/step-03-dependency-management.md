# Step 03 – Dependency Management

## Module state
- `pubspec.yaml` pins Dart/Flutter SDK versions and library constraints; `flutter pub get` generates the lockfile on consumers.
- CI runs `dart pub outdated --mode=null-safety` to spot stale dependencies and `flutter pub deps --style=compact` for SBOM-friendly inventory.

## Update automation
- GitHub Dependency Review blocks risky additions; Dependabot/Renovate can be enabled to watch `pubspec.yaml`.

## Approved libraries and licenses
- Core runtime dependencies are limited to `http`, `flutter_dotenv`, `opentelemetry*`, `uuid`, and `collection` to minimize attack surface.
- Security scanners (Trivy) run in CI to detect known CVEs in transitive dependencies.
