# Step 05 – Secure Coding Practices

## Auth and input validation
- The client validates todo input locally (non-empty titles) and trusts backend auth; UI surfaces backend auth errors via `AsyncError`.

## Transport security
- Recommend HTTPS for `API_BASE_URL`; README instructs to configure CORS and TLS at the backend/edge.

## Static analysis and secret scanning
- CI enforces `flutter analyze`, formatting, and gitleaks secret scanning.
- Trivy scans dependencies for known vulnerabilities.

## Runtime posture
- Mobile/web builds do not request elevated permissions; no embedded secrets in source or assets.
