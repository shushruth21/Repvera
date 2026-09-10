# Implementation roadmap

## Sequence rule

Build a vertically usable loop before a broader feature set. Do not begin body
scan, nutrition vision, Watch coaching, or a backend until Milestone 4 is
working on a physical iPhone.

## Milestone 0 — project foundation

- Create/rename Xcode target as Repvera.
- Set Bundle ID and local-only SwiftData configuration.
- Link `WorkoutPartnerCore` as a local package.
- Establish folder/module conventions and a test target.
- Create a basic four-tab shell with sample data.

**Done when:** the app builds and the adaptive-engine package tests pass.

## Milestone 1 — onboarding and catalogue

- Create profile, goals, availability, equipment, and limitation flows.
- Seed 30–50 exercises with movement patterns and vetted alternatives.
- Generate one starter plan from deterministic templates.

**Done when:** a fresh local install can produce and display a confirmed plan.

## Milestone 2 — workout execution

- Implement sessions, prescriptions, set logs, rest timer, skip/replace flow,
  RPE, notes, pain reporting, and PR detection.
- Save every logged set immediately.

**Done when:** a user can finish a complete session, terminate/reopen the app,
and see exactly what was logged.

## Milestone 3 — ATI integration

- Map logged data to `ExerciseContext`.
- Persist immutable `TrainingDecision` records and plan versions.
- Show old/new prescription and deterministic reason copy on Today.
- Expand rule tests for each policy branch.

**Done when:** logging two easy comparable bench sessions produces a visible,
explainable load increase; adverse paths remain conservative.

## Milestone 4 — HealthKit and progress

- Add clear consent flow and read-only HealthKit adapter.
- Create daily derived snapshot and use it only as optional ATI context.
- Add weight/strength/adherence trends and weekly review.

**Done when:** the app behaves correctly with full, partial, and denied access
on a real iPhone.

## Milestone 5 — polish and release readiness

- Accessibility pass, empty/error/offline states, data export/delete, app icon,
  privacy copy, and test flight checklist.

**Done when:** a new user can onboard, train, receive an adaptation, and inspect
its reason with no developer help.

## Backlog after validation

Notifications, richer charts/2D muscle map, photo progress journal, nutrition
targets, Apple Watch companion, optional on-device model copy, then any cloud
capability behind a separate privacy and architecture decision.
