# Step 06 – Unit, Integration, and End-to-End Testing

## Unit coverage
- `test/features/todos/todo_repository_test.dart` exercises repository logic with mocked HTTP clients.

## Integration tests
- `integration_test/todo_flow_test.dart` drives the UI against mocked backend responses with telemetry-enabled HTTP clients.
- Make targets (`make test`, `make e2e`) and CI jobs run both layers.

## Load and race considerations
- For backend load tests, defer to `template-go`; the Flutter client is stateless and can be tested with tools like `flutter drive` plus API replay.
- Widget tests validate async loading/error paths to prevent UI race regressions.
