# Data model and persistence

## Principles

- Keep app-owned history append-friendly and auditable.
- Separate a planned prescription from what was actually performed.
- Store identities as UUIDs and timestamps in UTC.
- Persist decisions as immutable events; do not overwrite decision history.
- Store only minimum, derived HealthKit summaries locally.

## Core entities

| Entity | Key fields | Notes |
| --- | --- | --- |
| `UserProfile` | goal, experience, unit preference, schedule, session duration | One active profile in V1 |
| `EquipmentProfile` | equipment IDs, available load increments | Supports travel/gym changes |
| `TrainingLimitation` | movement pattern, severity, user note, active flag | Not a diagnosis |
| `Exercise` | ID, name, movement pattern, equipment, cues, safety notes | Seeded and versioned catalogue |
| `ExerciseAlternative` | source ID, alternative ID, constraints | Same-pattern substitution map |
| `TrainingPlan` | ID, version, status, goal, start/end dates | Only one active plan |
| `PlannedWorkout` | plan ID, scheduled day, focus, duration | A reusable planned session |
| `ExercisePrescription` | exercise ID, order, sets, reps, load, RPE/rest | Immutable once attached to a completed session |
| `WorkoutSession` | plan/workout ID, started/ended, completion status, notes | User’s actual session |
| `SetLog` | session ID, prescription ID, set index, load, reps, RPE, completed | Save immediately |
| `DailyCheckIn` | energy, sleep quality, stress, soreness, mood/motivation | Self-report is primary readiness input |
| `HealthSnapshot` | date, sleep hours, HRV/RHR trend flags, active energy | Derived, optional, local |
| `MeasurementEntry` | date, body mass, optional body measurements | Never assume a measurement exists |
| `TrainingDecision` | input snapshot, output, reasons, decision timestamp | Immutable ledger record |
| `PersonalRecord` | exercise ID, metric, value, achieved date/session | Derived/cached from set logs |

## Relationships

```text
UserProfile ── 1:many ── TrainingPlan ── 1:many ── PlannedWorkout
                                           │
                                           └── 1:many ── ExercisePrescription

PlannedWorkout ── 1:many ── WorkoutSession ── 1:many ── SetLog
TrainingDecision ── references ── prescription + performance snapshot + plan version
```

## SwiftData boundary

SwiftData types live in `Data`. Map them to immutable core values before calling
ATI. For example, `SwiftDataSetLog` maps to `ExercisePerformance`; ATI never
imports SwiftData.

## Migration rules

- Additive fields should have defaults or optional values.
- Never rename/delete persisted fields without a migration plan.
- Version the seeded exercise catalogue separately from user workouts.
- A plan change creates a new `TrainingPlan.version`; it does not mutate the
  historical prescription used by a completed session.

## Data retention and export

V1 keeps data on device until the user deletes it. Provide a later export as a
human-readable CSV/JSON package with sessions, set logs, decisions, and
measurements. Raw HealthKit data is not included in the export.
