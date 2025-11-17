# Step 12 – Rate Limiting, Retries, and Backoff

## Outbound protections
- HTTP client wrappers can be extended with timeouts and retry logic; default `http.Client` supports timeouts and can be swapped for resilient clients via dependency injection in `Telemetry`.

## Circuit breaking and limits
- Use API gateway/CDN to enforce rate limits and circuit breaking for the frontend origin; document limits alongside backend policies.

## Degradation testing
- Integration tests can be extended with delayed/mock responses to validate UI resilience and user messaging when dependencies slow down.
