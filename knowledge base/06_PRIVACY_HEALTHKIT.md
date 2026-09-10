# Privacy, HealthKit, and AI boundary

## Data classification

| Class | Examples | V1 handling |
| --- | --- | --- |
| App training data | plan, set logs, RPE, notes, schedule | Local SwiftData only |
| Sensitive wellness data | weight, sleep, HRV, RHR, pain, check-in | Local only; minimum derived values |
| HealthKit source data | workouts, sleep samples, heart metrics | Query with permission; do not copy raw history to cloud |
| Photos | future progress photos | Out of V1; explicit pick only, local storage |
| Model input | structured decision/reasons | No cloud model in V1 |

## HealthKit policy

- Start read-only and ask only for types needed by a visible feature.
- Request permissions progressively, with a clear explanation of the benefit.
- The app must work when access is denied, partial, or limited to recent history.
- Check HealthKit availability before queries.
- Treat all data as optional and potentially stale/incomplete.
- Do not infer medical status from HRV, heart rate, sleep, or oxygen metrics.
- Do not write workouts to HealthKit until duplicate-source and conflict handling
  are designed and tested.

## Recommended initial data types

| Purpose | HealthKit input |
| --- | --- |
| Body trend | body mass |
| Recovery context | sleep analysis, resting heart rate, HRV |
| Activity context | workouts, step count, active energy |
| Later, optional | VO₂ max where available |

Do not make Blood Oxygen, ECG, or clinical records part of V1.

## Permission copy requirements

Provide precise `NSHealthShareUsageDescription` and, only if writing later,
`NSHealthUpdateUsageDescription` text. Example read copy:

> Repvera reads the health data you choose to share so it can add optional sleep
> and activity context to your training recommendations. Your plan still works
> without it.

## AI boundary

### Allowed

- On-device wording improvement from a structured, redacted decision.
- Summarising a user-authored workout note locally.
- Showing deterministic explanation templates when no model is available.

### Not allowed

- Sending raw HealthKit data, photos, or personally identifying data to a model.
- Embedding an API key in the app.
- Letting a model choose exercises, change a programme, score readiness, or
  issue injury/medical guidance.

## Distribution readiness

Before App Store distribution, add a privacy policy, confirm App Store privacy
nutrition labels, document each HealthKit type requested, and review all claims
about health/recovery/body analysis. Maintain a data-deletion path even for
local data.
