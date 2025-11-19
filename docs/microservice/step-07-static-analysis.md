# Step 07 – Static Analysis & Code Quality Enforcement

## Tooling
- `analysis_options.yaml` enforces `flutter_lints` with strict rules.
- CI runs `dart format --set-exit-if-changed` and `flutter analyze`.

## Coverage and quality gates
- Tests run with coverage and upload to Codecov for visibility; thresholds can be enforced in branch protection.

## Review checklist
- Keep telemetry hooks intact, avoid disabling lints, ensure UI changes include tests/screenshots when visual.
