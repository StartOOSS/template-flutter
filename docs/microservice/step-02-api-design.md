# Step 02 – API Design & Versioning

## Contract
- Consumes the `template-go` Todo API with REST endpoints:
  - `GET /api/v1/todos`
  - `POST /api/v1/todos`
  - `PUT /api/v1/todos/{id}`
  - `DELETE /api/v1/todos/{id}`
- Request/response payloads and error envelopes are documented in `README.md` and validated in repository tests using mocked HTTP clients.

## Versioning and deprecation
- The client targets `v1` and reads the base URL from config so future API versions can coexist at `/api/v2` without breaking the app.
- Contract expectations are encoded in `lib/features/todos/data/todo_api_client.dart`; any breaking backend change will surface test failures.

## Human-readable docs
- API paths and environment setup live in the top-level README.
- Developers can extend docs by adding OpenAPI schemas from the backend repo; this template keeps a lightweight consumer contract description.
