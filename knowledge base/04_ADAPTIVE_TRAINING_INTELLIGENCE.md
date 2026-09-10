# Adaptive Training Intelligence (ATI)

## Role

ATI is Repvera’s deterministic decision system. It receives facts about a user,
their plan, an exercise, recent comparable performance, and recovery context. It
returns the next safe prescription plus structured reasons.

```text
Inputs → validate → safety gates → base prescription → adaptation policy
       → TrainingDecision → persist ledger → user explanation
```

## Decision contract

```swift
func decide(
    profile: TrainingProfile,
    context: ExerciseContext
) -> TrainingDecision
```

`TrainingDecision` contains:

- `action`: pause/replace, select substitution, reduce volume, hold load,
  increase load, or keep prescription.
- `prescription`: the new prescription or `nil` when manual review/replacement
  is needed.
- `reasons`: stable machine-readable reason codes.
- `coachExplanation`: deterministic fallback copy.

## Inputs

### Required

- Goal, experience, available equipment, and minimum load increment.
- Existing exercise prescription: movement pattern, sets, reps, load, target RPE.
- Completed sets/reps, failed reps, highest RPE, and whether performance is
  comparable to the prescription.
- Self-reported energy, sleep quality, stress, soreness, and exercise pain.

### Optional

- Available session duration.
- HealthKit-derived sleep, HRV trend, resting-heart-rate trend, activity, and
  body-mass trend.
- Plan history: volume, frequency, adherence, deload history, substitutions.

Missing optional inputs reduce confidence; they never trigger an aggressive
change.

## Policy order

1. Validate ranges, timestamps, units, and comparability.
2. Apply safety gates.
3. Handle equipment/schedule constraints.
4. Apply readiness reduction before performance progression.
5. Apply exercise-level progression/hold policy.
6. Apply weekly plan policy only at the designated review boundary.
7. Persist the decision and reason codes before displaying it.

## V1 policy table

| Evidence | Decision | Reasons |
| --- | --- | --- |
| Pain ≥ 7/10 | Pause movement; require replacement/review | `severePainReported` |
| Equipment missing | Request vetted same-pattern substitute | `equipmentUnavailable` |
| Poor check-in, <5.5h sleep, or paired adverse HRV/RHR trend | Reduce one hard set, minimum one; hold load | `lowReadiness` |
| Missed reps or RPE ≥9 | Hold load; do not add volume | `targetMissed`, `highPerceivedExertion` |
| Two comparable full completions at RPE ≤7 | Add smallest load increment, if load exists | `repeatedEasyCompletion` |
| No comparable history | Keep prescription; establish baseline | `noComparableHistory` |
| Otherwise | Keep prescription | `performanceOnTarget` |

## Safety invariant list

- An LLM cannot generate/modify a `TrainingDecision`.
- A user can inspect the input snapshot and reason code for every change.
- Never increase load after a missed target, failed reps, RPE 9–10, or active
  readiness reduction.
- Do not change more than one major variable (load, volume, frequency, or
  exercise variation) in a single decision unless a named policy requires it.
- Severe pain returns no automatic prescription. The app offers a non-diagnostic
  prompt to stop the movement and seek appropriate professional support if pain
  is severe or persists.
- Health signals are coaching inputs, not medical measurements or diagnoses.

## Weekly adaptation (V2 of ATI)

Weekly review should evaluate adherence, strength trend, volume by movement
pattern/muscle group, repeated low readiness, and plateau evidence. Change one
variable at a time, version the plan, and publish a summary of what changed.

## LLM role, if added later

The language model receives only a redacted structured decision and approved
copy style. It may return a short explanation that is validated against the
reason codes. If unavailable, use deterministic templates. It never receives a
tool that can write a plan or access raw health history.
