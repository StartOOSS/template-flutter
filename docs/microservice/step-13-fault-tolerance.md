# Step 13 – Fault Tolerance & Graceful Degradation

## Fallbacks
- UI handles empty/error states gracefully (`AsyncError`, loading indicators) so users receive actionable feedback.
- Todo mutations are optimistic only after server acknowledgement to avoid data drift.

## Redundancy
- Host web assets across multiple AZs/CDNs; mobile binaries remain available through staged rollouts.

## Chaos and learnings
- Pair with backend chaos tests; observe frontend behavior via OpenTelemetry spans to confirm degraded paths remain usable.
