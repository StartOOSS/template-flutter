# Step 15 – Documentation & Runbooks

## README and onboarding
- README covers setup, configuration, telemetry, quality gates, and deployment basics.
- `.env.example` documents required environment variables.

## Runbooks and catalog
- Document staging/prod URLs and API base URLs; register the service in your internal catalog with ownership and on-call links.
- Include steps to refresh OTLP endpoints, rotate secrets, and run smoke tests after changes.
