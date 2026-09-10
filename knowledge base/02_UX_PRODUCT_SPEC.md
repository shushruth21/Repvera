# UX and screen specification

## Design direction

Repvera should feel focused, capable, and calm: dark/neutral surfaces, one
distinctive indigo accent, readable type, generous spacing, and status colours
used only for meaningful states. It is a training tool, not a social feed.

## Information architecture

```text
Today
├── Readiness and coach note
├── Today's workout
└── This week's progress

Plan
├── Current training block
├── Upcoming sessions
└── Decision history

Progress
├── Strength trends
├── Adherence and volume
├── Weight / measurements
└── Weekly review

Profile
├── Goal, schedule, equipment, limitations
├── Health connection
└── Data controls
```

## Required flows

### 1. Onboarding

1. State goal and experience.
2. Choose available days, session duration, equipment, and limitations.
3. Enter optional baseline weight and measurements.
4. Choose whether to connect Apple Health later; do not interrupt setup with a
   large permission sheet.
5. Review the generated starter plan and confirm it.

**Exit condition:** `TrainingProfile` is valid and `TrainingPlan v1` exists.

### 2. Today → start workout

Today must show one primary action: **Start workout**. Before starting, show the
session title, duration, focus, readiness state, and any change since the last
comparable session. Do not bury the workout behind coaching prose.

### 3. Workout player

For each exercise, show prior performance, prescription, target RPE/RIR, rest
timer, and a compact set table. The user can log a set, change load/reps, mark
an exercise skipped, add a note, or report pain. A logged set is saved
immediately; never require a final “save workout” to preserve work.

### 4. End workout

Show: completion summary, PRs, skipped work, next likely recommendation, and a
small check-in. Do not generate a new plan in the UI; request the engine to
produce a structured decision.

### 5. Decision explanation

Use this fixed format:

```text
Changed: Bench press 100 kg → 102.5 kg
Why: You completed 4 × 8 twice at RPE 6.
Confidence: High — two comparable sessions were logged.
Action: Start the next session with the updated prescription.
```

## States to design explicitly

| State | Required user experience |
| --- | --- |
| No plan | Clear setup CTA; no empty dashboard charts |
| No HealthKit permission | Full manual workflow with an optional connect CTA |
| Limited/missing HealthKit data | State that recovery is based on self-report only |
| Severe pain | Stop affected exercise, protect data, show non-diagnostic safety copy |
| Low readiness | Offer a reduced session, mobility/rest option, and a reason |
| Offline | Normal core app behaviour; only optional AI wording may be unavailable |
| Data unavailable | Explain what is missing and how it affects confidence |

## Accessibility requirements

- Support Dynamic Type without truncating prescriptions or decision reasons.
- Never rely on colour alone for readiness, completion, or warning states.
- All controls need useful VoiceOver labels: include exercise, set, load, reps,
  and target effort.
- Use system controls where possible; respect Reduce Motion and high contrast.
- Make set logging targets at least 44 × 44 points.

## Copy rules

- Say “suggest”, “based on your logged data”, and “consider” when uncertain.
- Never say “diagnosis”, “injury detected”, “you must”, or “optimal” without a
  validated basis.
- Give one main recommendation, not a wall of AI-generated options.
