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
