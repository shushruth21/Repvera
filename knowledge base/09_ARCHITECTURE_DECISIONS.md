# Architecture decision record

## ADR-001 — Local-first, no backend in V1

**Decision:** Store app data locally with SwiftData and do not introduce an
account, backend, or cloud sync.

**Reason:** The first user is the builder; the core value is personal coaching,
not multi-device collaboration. This avoids privacy, authentication, cost, and
sync-conflict complexity.

**Consequence:** No remote backup in V1. Add explicit export before considering
sync.

## ADR-002 — Deterministic ATI is authoritative

**Decision:** Programme changes are rule/policy output, not LLM output.

**Reason:** Decisions need safety boundaries, repeatability, testability, and
clear auditability.

**Consequence:** AI language features are optional presentation helpers.

## ADR-003 — HealthKit is optional and read-only initially

**Decision:** The manual training loop works without HealthKit. V1 reads a
small, purpose-bound subset only after permission.

**Reason:** Health data is sensitive, permission may be limited, and Apple Watch
data availability varies.

**Consequence:** The app must display confidence/availability rather than
pretend absent data means poor recovery.

## ADR-004 — No body-photo estimation in V1

**Decision:** Do not estimate body fat, posture, symmetry, or physique category
from photos in the first build.

**Reason:** Accuracy, validation, privacy, and body-image risks exceed the
value before the training loop is proven.

**Consequence:** Measurements and optional manual progress notes cover the
initial progress need.

## ADR-005 — Plan and decision history are immutable

**Decision:** Completed sessions retain their original prescriptions; every
adaptation creates a decision record and plan version.

**Reason:** Coaching must be explainable and reversible.

**Consequence:** The data model needs versioning rather than in-place updates.

## ADR-006 — V1 policy source of truth

**Decision:** When product docs disagree, v1 follows this freeze so the engine
and UI do not fork.

- The four-tab shell, including Today, is Milestone 0. Real Today data arrives
  with onboarding, logging, and ATI integration. HealthKit remains Milestone 4.
- The Profile tab is the settings home. Onboarding lives under
  `Features/Onboarding`; profile and later data controls live under
  `Features/Profile`.
- `TrainingProfile` is the ATI input value type. SwiftData persists
  `UserProfile` and maps into `TrainingProfile`.
- Do not persist `PlanWeek`. Derive weeks from `PlannedWorkout` dates.
- Missed-target v1 policy is hold load only. Reducing a hard set after fatigue
  is a later named policy.
- Low-readiness v1 policy is a single-session volume reduction. A rest or
  mobility option may be offered in the UI later; it is not a diagnosis.
- Bodyweight v1 policy keeps the prescription. Adding a rep when load cannot
  increase is a later named policy.
- Log RPE in v1. Optional RIR may be stored later; it is not an ATI input.
- Domain and ATI rules live in `WorkoutPartnerCore`, not in app `Domain/` or
  `TrainingEngine/` folders.
- Personal build target is iPhone, iOS 26. The core package may declare a
  lower platform as long as it compiles in the app SDK.
- SwiftData is local-only, with CloudKit disabled. The engine stays
  side-effect free; use cases persist after `decide`.
- Milestone 4 may show a weekly summary. Automatic weekly plan rewrites wait
  for ATI v2.

**Reason:** The knowledge base was internally consistent on the product thesis
but split on sequencing, naming, and a few progression details.

**Consequence:** New features implement this freeze, not the conflicting
sentences they replace.
