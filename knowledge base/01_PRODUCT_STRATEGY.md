# Product strategy

## One-sentence positioning

**Repvera is a private adaptive training coach that turns workout outcomes and
recovery signals into a clear next workout with an explanation.**

## Product thesis

Most workout trackers record what happened. Repvera earns its place by deciding
what should happen next, then showing the evidence behind that decision. The
value is not an AI chat interface; it is trustworthy, low-friction coaching.

## User and job to be done

The first user is the builder: an intermediate lifter training independently at
a gym, with a changing schedule and some Apple Health data.

> When I am about to train, help me choose and complete the right session for
> today, adjust my future training from the outcome, and show whether my effort
> is producing progress.

## V1 outcome

After a short onboarding, a user can complete this loop without assistance:

```text
profile → starter plan → workout log → ATI decision → next workout + explanation
```

The loop is successful when a logged performance changes a future prescription
only when the evidence supports a change.

## Scope

### Include

- Goal, experience, schedule, equipment, limitations, and target session length.
- Curated exercise catalogue and substitution relationships.
- Workout plan, workout player, set/reps/load/RPE logging, notes, and PRs.
- Daily self-report: energy, sleep quality, stress, soreness, pain.
- Explainable ATI adaptation and immutable decision history.
- Optional HealthKit read-only inputs and simple progress trends.

### Exclude until the loop is proven

- Photo-based body-fat/physique assessment and visual comparison.
- Meal-photo nutrition estimation, barcode scanning, and meal plans.
- 3D body visualisation, exercise video library, real-time form analysis.
- Apple Watch workout app, voice coaching, social/community, marketplace,
  subscriptions, and backend accounts.

## Product principles

1. **Coach before tracker.** A screen must help decide or execute an action.
2. **Explain before persuade.** Show what changed, the evidence, and the option
   to keep/review the plan.
3. **Conservative by default.** Missing data means less certainty, never more
   aggressive progression.
4. **Local and private by default.** The app is useful without an account or
   network connection.
5. **Fast while lifting.** Set logging should take seconds and be usable one
   handed with a timer running.

## Measurable success criteria

| Metric | First personal-build target |
| --- | --- |
| Onboarding completion | A valid starter plan in under five minutes |
| Workout logging | Log a working set in two interactions or fewer |
| Decision coverage | Every altered prescription has one or more reason codes |
| Safety coverage | Pain, poor readiness, missed targets, and absent data are tested |
| Trust | User can inspect the prior prescription, new prescription, and reason |

## Naming and tone

Use **Repvera** as the product/display name. The tone is direct, calm, and
specific: “Hold 100 kg next time; the target was missed at RPE 10.” Avoid
medical language, shame, body judgement, or unsupported certainty.
