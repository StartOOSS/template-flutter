# Step 16 – Incident Response & On-Call Readiness

## On-call rotation and escalation
- Assign ownership for the Flutter frontend; mirror backend escalation paths since user impact spans both tiers.

## Alerts
- Leverage backend metrics/traces and client-side telemetry errors to trigger actionable alerts (e.g., spike in failed HTTP spans).

## Exercises
- Run game days that simulate API failures and collector downtime; ensure UI messaging stays clear and roll back to prior asset versions if needed.
