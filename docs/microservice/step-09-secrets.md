# Step 09 – Secrets & Sensitive Data Handling

## Storage and injection
- Secrets are never committed; `.env` is gitignored and `.env.example` lists placeholders.
- For CI/CD, use repository/environment secrets to supply API endpoints and OTLP credentials.

## PII hygiene
- No PII is collected beyond todo titles; avoid logging sensitive values and ensure telemetry exporters are secured.

## Rotation
- Rotate OTLP and API tokens via platform secret stores; document ownership in runbooks.
