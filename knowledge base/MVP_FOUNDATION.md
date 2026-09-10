# Workout Partner — MVP foundation

## Product decision

Build **an adaptive workout coach**, not a broad fitness super-app. The app must
reliably answer three questions:

1. What should I do today?
2. Why is that the right session today?
3. Am I progressing?

The Adaptive Training Intelligence (ATI) is the system of record for the
answer. It creates a safe starting programme, adjusts it from logged outcomes,
and records an explanation for every change. It is not an unconstrained chat
model that writes workouts from scratch.

## V1 scope

### Build first

| Capability | V1 behaviour |
| --- | --- |
| Onboarding | Goals, experience, equipment, available days/time, current weight, training limitations, and a simple readiness baseline. Keep name, date of birth, and gender optional unless they affect a plan. |
| Health connection | Opt-in, read-only HealthKit import of body mass, sleep, resting heart rate, HRV, steps, active energy, and workouts when available. Work with partial or no permission. |
| Workout engine | Generate a starting programme from vetted exercises and progress it from completed sets, reps, RPE/RIR, skipped work, time available, soreness, and recovery inputs. |
| Workout player | Log exercises, sets, load, reps, RPE/RIR, rest, notes, and pain/soreness. Detect personal records. |
| Daily coach | Show the next session, readiness, the proposed changes, and a plain-language reason for each change. |
| Progress | Weight, completed workouts, strength trend, and voluntary measurements. Include a simple weekly check-in. |

### Deliberately defer

| Capability | Why it waits |
| --- | --- |
| AI body-fat estimates, physique labels, and visual comparisons | These are unreliable from photos without a validated approach and create an unnecessary privacy and body-image risk. Store voluntary photos only after the core loop works. |
| Meal-photo recognition and full nutrition assistant | It needs a vision model, nutrition data source, correction flow, and careful expectation-setting. Start later with manual calorie/protein targets if needed. |
| 3D heat map and exercise video library | Valuable presentation, but neither improves the core training decision in the first build. Begin with a 2D muscle-volume summary and a small vetted exercise catalogue. |
| Apple Watch workout app, live voice coaching, form analysis, automatic exercise detection | These are separate products with significant real-time, watchOS, computer-vision, and validation work. |
| Achievements, community, marketplace, family accounts | They do not help validate whether the coaching loop works for one person. |

## Technical architecture

```text
SwiftUI screens
     |
Feature view models
     |
ATI orchestration ──> decision ledger + explainability
     |                         |
     |                    SwiftData (on device)
     |
HealthKit adapter ──> Health app / Apple Watch data
     |
Optional on-device language model ──> wording only, never safety or programming rules
```

Use these native frameworks:

| Need | Choice | Reason |
| --- | --- | --- |
| Interface | SwiftUI | Fast native iPhone iteration and accessible system controls. |
| App-owned persistence | SwiftData, local-only | Keeps the first version offline-friendly and avoids a backend. Do not configure CloudKit sync for health information. |
| Health and Apple Watch data | HealthKit | The Apple-approved source for the user’s opted-in data. |
| Reminders | UserNotifications | Schedule only after a person sets their workout plan and asks for reminders. |
| Optional AI copy | Foundation Models, when available | It can phrase a coach explanation privately on device. The app needs a deterministic fallback because the model may be unavailable. |
| Photos, later | PhotosUI + local encrypted storage | Select only the photo the user explicitly chooses; do not infer medical measurements from it in V1. |

Target iOS 26.0 or later for the first personal build. That allows a current SwiftUI/SwiftData codebase and the Foundation Models option, while the app still works when Apple Intelligence is unavailable.

## ATI: the actual training engine

### Inputs

Only inputs with a clear training purpose should affect a decision:

- Profile: goal, experience, equipment, schedule, available time, limitations.
- Workout facts: prescribed versus completed sets, load, reps, RPE/RIR, duration, rest, skipped work, PRs, and reported pain.
- Daily check-in: sleep quality, energy, stress, motivation, and muscle soreness.
- HealthKit signals when authorised and present: sleep, resting heart rate, HRV, activity, body mass, and recorded workouts.
- Trends: recent volume by muscle group, performance trend, adherence, and a weekly weight/measurement trend.

Photos and subjective physique observations are not engine inputs in the first release.

### Decision pipeline

1. **Validate input** — ignore impossible values, stale HealthKit samples, and missing data.
2. **Apply safety gates** — acute pain, an injury limitation, or an unusually poor check-in means reduce, replace, or pause the relevant work; do not diagnose.
3. **Build the base session** — select from a curated exercise catalogue according to the active training split, equipment, and available time.
4. **Adapt within limits** — apply a small number of rule-based changes to load, reps, sets, rest, exercise choice, or session order.
5. **Persist a decision** — save the input snapshot, programme version, output prescription, reason codes, and whether the user accepted the change.
6. **Explain it** — turn reason codes into concise, reviewable coach language. An optional language model may improve the wording but cannot alter the prescription.

### Non-negotiable guardrails

- A language model cannot choose exercises, loads, volume, or deloads by itself.
- Every programme change is versioned, has structured reason codes, and can be reviewed or reversed.
- Do not increase load after failed reps or high RPE; require successful, comparable performance first.
- Limit simultaneous changes. For example, do not raise both load and weekly volume in the same exercise decision without an explicit rule.
- Enforce per-session time limits and conservative volume/load ceilings based on experience.
- Reported severe pain stops the affected movement and shows a prompt to seek an appropriate clinician; the app must not diagnose injuries.
- Recovery is a coaching signal, not a medical score. State uncertainty when HealthKit data is incomplete.

### First progression rules

Start transparent and testable. Examples:

| Observation | Action |
| --- | --- |
| All prescribed reps completed at RPE 6–7 twice | Add the smallest available load increment next time, or add one rep where load cannot increase. |
| Target missed or RPE 9–10 | Keep load, reduce one hard set when fatigue is elevated, and retry in the next comparable session. |
| Low readiness for 2–3 days plus high recent volume | Offer a reduced-volume session or rest/mobility option; do not present it as a medical conclusion. |
| No performance progress across several comparable sessions | Review adherence and recovery; then alter one variable: volume, rep range, or exercise variation. |
| Equipment unavailable | Substitute only from the same movement pattern and preserve the intended effort/rep range. |
| Pain at 7/10 or greater | Stop the movement, remove the aggravating pattern from the session, and recommend professional assessment if it persists or is severe. |

## Core data model

Keep identifiers, timestamps, and immutable workout/decision history. The initial entities are:

- `UserProfile`, `Goal`, `EquipmentProfile`, `Availability`, `TrainingLimitation`
- `Exercise` (a curated catalogue), `ExerciseAlternative`, `MovementPattern`
- `TrainingPlan`, `PlanWeek`, `PlannedWorkout`, `ExercisePrescription`
- `WorkoutSession`, `SetLog`, `PersonalRecord`
- `DailyCheckIn`, `MeasurementEntry`, `WeeklyReview`
- `HealthSnapshot` (a derived, on-device daily summary; never treat it as a medical record)
- `TrainingDecision` and `DecisionReason` (the audit trail for ATI)

Keep raw HealthKit samples in HealthKit. Store only the minimum derived summary needed to explain a decision locally. Do not design an iCloud or third-party data sync path for health data in this first release.

## Project structure

```text
WorkoutPartner/
  App/                 app entry, dependency container, app navigation
  Domain/              immutable value types and training rules
  Data/                SwiftData models, repositories, seed exercise catalogue
  Health/              HealthKit authorisation, queries, availability mapping
  TrainingEngine/      programme creation, adaptation, guardrails, explanations
  Features/
    Onboarding/
    Today/
    Workout/
    Progress/
    Settings/
  SharedUI/             reusable controls, charts, empty/error states
  Tests/
    TrainingEngineTests/ deterministic rule and safety tests
    HealthMappingTests/
```

Feature screens never query HealthKit or edit training plans directly. They request a use case from the engine and render the returned state.

## Prerequisites before coding features

- Xcode 26.6 and Swift 6.3 are installed locally.
- Use a real iPhone to test HealthKit and Apple Watch data; the simulator is fine for ordinary screens and seeded test data, but not a substitute for real permissions/data.
- Create an Apple App ID for the app and enable the HealthKit capability. Add clear HealthKit read/write purpose strings before requesting access.
- Start read-only for HealthKit. Only consider writing a completed workout to HealthKit after the in-app workout log is dependable and duplicate handling is designed.
- Ask for the smallest useful set of HealthKit permissions at the moment it is needed. The app must gracefully support denied or limited history access.
- Use a private, local development build first. If distributed later, add a privacy policy and complete Apple’s health-data disclosures before submission.
- Do not embed any cloud-model API key in the iOS app. The first version has no cloud dependency.
- Collect a small, reviewed initial exercise catalogue (approximately 30–50 exercises) with movement patterns, equipment, safety notes, load increments, and substitute relationships.
- Create deterministic test fixtures: easy progress, missed reps, bad sleep, reduced time, unavailable equipment, moderate pain, severe pain, and no HealthKit access.

## Build order

1. Create the native app target with local persistence, design tokens, navigation, and sample data.
2. Add profile/onboarding, equipment, schedule, training limitations, and the curated exercise catalogue.
3. Add the workout player and immutable set logging; calculate basic PRs and history.
4. Implement ATI v1 with the progression rules above, plan versioning, decision reasons, and tests.
5. Add HealthKit authorisation and daily derived readiness snapshot as an optional input.
6. Add the Today dashboard and weekly progress review.
7. Only then add notifications, richer visualizations, optional on-device coach wording, photos, nutrition, or Watch features.

## Success condition for the first usable build

After onboarding, the app should create a realistic next workout, let the user log it with no friction, alter the following comparable workout from the outcome, and clearly explain what changed and why — even when HealthKit access or Apple Intelligence is unavailable.
