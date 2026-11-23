# lettuceguard

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Air-temperature alerts

Air temperature comes from the DHT22 (confirmed in the ESP32 firmware). The
firmware samples every 3 seconds and sends Firebase `/current` snapshots; history
snapshots remain every 5 minutes. Flutter defaults to demo mode. In production,
Firebase current snapshots are now the default live source. Settings also retains
an explicit ESP32 local HTTP option. Local HTTP responses must include an actual
sensor Unix/ISO timestamp; receipt time is never substituted for measurement time.

### Configuration and stability

`LettuceGuardConstants` and `TemperatureAlertConfig` configure these application
thresholds (not universal biological limits):

| Temperature | Level | Behavior |
| --- | --- | --- |
| Below 18 C | Low | Blue warning after 3 distinct valid samples |
| 18 through 26 C | Normal | No new alert |
| Above 26, below 30 C | High | Orange banner; event after 3 samples |
| 30 through below 35 C | Critical | Critical event/popup after 3 samples |
| 35 C and above | Extreme | Immediate event/escalation for a valid fresh sample |

The banner identifies readings awaiting confirmation. Recovery requires 3
consecutive valid readings. Critical can downgrade only below 29 C, extreme only
below 34 C; low temperature can recover at 19 C or above. Full resolution requires
sustained readings in the configured normal range. Recovery hysteresis, counts,
maximum age (30 seconds), allowed future skew (5 seconds), and sample gap
(12 seconds) are configurable. Duplicate/out-of-order timestamps do not count.
Missing, error-flagged, nonfinite or out-of-DHT22-range (-40 to 80 C) readings
cannot start or resolve a temperature event. A failed or stale sensor leaves an
existing condition unresolved and displays unavailable data.

### Persistence and authorization

Existing generic alert records and sensor history paths are preserved. Temperature
monitoring uses these children of the existing per-device alerts path:

- `/devices/{deviceId}/alerts/air_temperature/state`: small detector checkpoint,
  latest event, confirmation counters, and last processed sensor timestamp.
- `/devices/{deviceId}/alerts/air_temperature/events/{eventId}`: one audit record
  per incident, including measured values, thresholds, timestamps, lifecycle,
  acknowledgment, popup presentation, and severity/recovery transitions.

State bookkeeping is checkpointed per new measurement; audit records change only
on event transitions, acknowledgment, or popup presentation. Firebase ETag/If-Match
conditional writes serialize concurrent clients. Retries use the same event ID
and revision. A partial archive write is repaired from the state checkpoint before
that event can be replaced. Active incidents and presentation/acknowledgment state
are restored before synchronized production detection continues. Multiple clients
sharing a snapshot cannot count it more than once.

Writes require the signed-in Firebase user's ID token and the database's existing
per-device authorization. No rules were deployed or weakened. If current rules do
not permit these two child paths, minimally extend the existing device-membership
read/write predicate to `alerts/air_temperature/state` and
`alerts/air_temperature/events/$eventId`. Do not grant access merely because a
user is signed in; reuse the actual authorized-device ownership/membership check.
The administrator must verify both authorized and unauthorized users in the
Firebase Rules simulator/emulator before enabling production persistence. Existing
parent-level grants must also be reviewed because child rules cannot revoke them.

Unsent operations remain queued in memory and retry while the app is open. Their
original sensor and receipt timestamps are retained. Closing the app before an
unsynchronized incident is saved can lose those unsent changes. Closed-app heat
detection and background push notifications are not implemented. No Cloud
Functions or device-side alert writer is introduced, so there is one foreground
alert generation path. Demo incidents never reach this storage.

### Manual verification

1. Run `flutter run -d chrome` (debug). Sign in and keep Demo Mode enabled.
2. In Settings, use **Developer demo air-temperature scenarios**: 24 C, then
   28 C, 32 C and 36 C. These target mock temperatures with the existing simulated
   variation. Wait for three generated samples (normally about 6 seconds) for High
   and Critical. Extreme needs one. The controls are hidden in release/production.
3. Verify High has no popup. Critical opens one even while Settings or History is
   selected. Extreme updates the same popup. Acknowledge leaves the alert active.
4. Select 24 C and wait for sustained recovery. Inspect the resolved record and
   its recovery time in Alerts. DHT22 fault injection must not resolve an event.
5. Confirm the correct Firebase project/database URL and matching authenticated
   device access. Platform Firebase options currently reference different project
   IDs; align them with the intended deployment rather than copying example URLs.
6. Save the database URL, choose **Firebase current snapshot**, disable Demo Mode,
   and confirm actual sensor timestamps advance every approximately 3 seconds.
7. Observe normal operation first. Verify real abnormal readings only through a
   supervised hardware test; do not write invented measurements to production.
   Inspect `state` and `events` in Firebase and restart the app during an active
   incident to verify restoration. The app still defaults to Demo Mode on launch;
   reselect the same production configuration before checking restored alerts.
   Verify access is denied for an unauthorized
   account. Confirm sensor disconnection produces an unavailable state without
   resolving the incident.

Validation commands: `flutter pub get`, `dart format .`, `flutter analyze`,
`flutter test`, and `flutter build web`. Automated temperature persistence tests
use an in-memory HTTP fixture, not the live database.
