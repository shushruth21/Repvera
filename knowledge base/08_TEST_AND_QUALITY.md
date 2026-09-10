# Test and quality strategy

## Test pyramid

| Layer | What to test | Tooling |
| --- | --- | --- |
| Domain unit tests | Every ATI branch, reason code, and invariant | Swift Testing in `WorkoutPartnerCore` |
| Repository tests | SwiftData mapping, migrations, transaction behaviour | In-memory model container |
| Use-case tests | Logging → decision → plan update → ledger sequence | Fakes + in-memory persistence |
| UI tests | Onboarding, log set, pain state, explanation display | XCTest UI tests |
| Manual device tests | HealthKit permission modes, actual workout flow, Dynamic Type | Xcode + iPhone |

## Mandatory ATI test matrix

- Two easy comparable completions increase load by the configured increment.
- A missed target holds load and includes `targetMissed`.
- RPE 9–10 holds load and includes `highPerceivedExertion`.
- Low readiness reduces volume and never increases load.
- Pain 7/10+ returns no automatic prescription.
- Missing equipment requests a substitute and does not silently change movement.
- No comparable history retains the prescription and identifies a baseline.
- Identical inputs always return identical decisions.
- Decisions remain valid when HealthKit inputs are absent.

## Invariants to enforce in code

```text
completed session logs are immutable
decision records are append-only
one decision = a reproducible input snapshot + output + reasons
no load progression after failed/high-RPE performance
no health permission = no broken core feature
```

## Definition of done for a feature

- Acceptance criteria from the relevant product/UX document are met.
- Empty, loading, failure, and privacy-denied states are designed.
- At least one automated test protects new domain behaviour.
- UI is accessible with Dynamic Type and VoiceOver labels.
- No new sensitive data leaves the device.
- Build succeeds in Xcode and the changed flow is checked on target device where
platform features are involved.

## Release gates

- No crashes during onboarding, logging, or decision generation.
- All mandatory ATI matrix tests pass.
- App remains usable offline and without HealthKit permission.
- User can inspect/clear local data.
- Health-related copy has no unsupported diagnostic claim.
