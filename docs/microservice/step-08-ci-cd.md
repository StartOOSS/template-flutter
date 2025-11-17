# Step 08 – CI/CD Foundations

## Build and test automation
- GitHub Actions workflow runs formatting, analysis, unit tests, integration tests, and security scans on every push/PR.
- Code coverage uploaded to Codecov for reporting.

## Artifact publishing
- Web builds can be produced with `flutter build web`; integrate with static hosting/CDN. Mobile builds are signed per platform before release.

## Deployment safety
- Recommend blue/green or canary rollout at the hosting layer (e.g., CDN versioned assets). Post-deploy smoke tests can reuse `integration_test` suite against staging environments via configuration.
