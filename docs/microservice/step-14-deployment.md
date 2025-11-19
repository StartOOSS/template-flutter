# Step 14 – Deployment Strategies & Containerization

## Containerization
- Web builds can be served from a slim Nginx container; ensure non-root user and minimal layers. Scan images with Trivy (already in CI for filesystem) before release.

## Rollout strategies
- Use versioned asset paths for blue/green or canary rollouts; configure CDN to shift traffic gradually.

## Post-deploy checks
- Run integration tests against the deployed environment (configurable `API_BASE_URL`) as smoke tests; rollback via CDN version switch on failure.
