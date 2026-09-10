# System architecture

## Architecture objective

Make the training engine independently testable and keep platform concerns at
the edge. SwiftUI renders feature state; it never contains progression rules or
HealthKit queries.

```text
SwiftUI feature screens
        ↓ intents / view state
Use cases and feature view models
        ↓
Domain: ATI engine, policies, value types, reason codes
        ↓                     ↘
Repositories / SwiftData       HealthKit adapter
        ↓                       ↓
On-device app data             Apple Health data
```

## Modules

| Module | Owns | Must not own |
| --- | --- | --- |
| `RepveraApp` | App lifecycle, navigation, dependency container | Training rules |
| `Features` | Views, view models, UI state, accessibility | Persistence queries or HealthKit calls in views |
| `WorkoutPartnerCore` | Domain entities, adaptation policies, decision/reason types | SwiftUI, SwiftData, HealthKit, network calls |
| `Data` | SwiftData models, repositories, migrations, seeded exercise catalogue | UI logic |
| `Health` | HealthKit permission, queries, data availability mapping | Raw data persistence beyond needed local derived summaries |
| `AIExplanation` (later) | Optional structured-decision-to-copy transformation | Training decisions or safety override |

## Dependency rules

```text
Features ───────→ Use cases ───────→ WorkoutPartnerCore
                    ↓                 ↑
                 Repositories ────────┘
                    ↓
                 SwiftData

HealthKit → Health adapter → normalized HealthSnapshot → use case
```

- Dependencies point inward; the core knows nothing about Apple frameworks.
- Repositories expose domain values, not SwiftData model objects.
- The engine receives an explicit `ExerciseContext`, returns a
  `TrainingDecision`, and causes no side effect.
- Use cases write plan/session/decision data in a transaction after a decision
  has been created.

## State management

- Prefer Swift’s observation tools and `@MainActor` view models for UI state.
- Keep async operations in use cases/services, not views.
- Inject protocols into view models for deterministic previews and tests.
- Save workout logs immediately and make end-workout processing idempotent.

## Persistence strategy

Use SwiftData for app-owned data, configured local-only. HealthKit remains the
source for wearable/Health data. Store a small derived `HealthSnapshot` only to
explain a decision; do not copy raw HealthKit samples into a cloud database.

## Error strategy

Every user-facing failure must map to an actionable domain state:

| Technical condition | Product response |
| --- | --- |
| HealthKit unavailable or denied | Continue manual coaching; offer reconnect path |
| Repository write failure | Preserve unsaved log in memory and show retry/export guidance |
| No comparable history | Hold prescription and identify the session as a baseline |
| Optional model unavailable | Use template explanation from reason codes |

## Future backend boundary

There is no V1 backend. If cross-device sync or cloud AI is later approved,
introduce an API boundary and an explicit data classification review. Never
retrofit server calls directly into SwiftUI views or ATI policies.
