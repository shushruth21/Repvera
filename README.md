# Repvera

Repvera is a private, on-device adaptive training coach for iOS. It turns a starter workout plan and real logged sets into clear, explained next-session decisions — no cloud backend, no social feed, no subscription.

Every adaptation is made by a small, deterministic, fully unit-tested rules engine (the **Adaptive Training Intelligence**, or ATI). There is no black box: every decision comes with a plain-language reason, and the same inputs always produce the same output.

## Core loop

```
Onboarding → Starter plan (v1) → Log a workout → ATI decision → Next session, explained
```

1. **Onboarding** — goal, experience, schedule, equipment, and any movement limitations.
2. **Starter plan** — a deterministic, template-based first training block built from the exercise catalogue (no AI writes your program).
3. **Log a workout** — reps, load, and RPE per set, persisted immediately.
4. **ATI decision** — the engine compares the latest logged performance against the prescription and decides: hold, increase load, reduce volume, substitute, or pause — always with a reason.
5. **Ledger entry** — that decision is written to an immutable record the moment the session completes, so it's permanently explainable later.
6. **Next session** — the coach explanation and the updated prescription are shown before you train again.

## Decision ledger

Every time you finish a workout, Repvera asks the ATI engine what should happen next for each exercise you logged — and writes the answer down permanently, per exercise, as a `TrainingDecisionRecord`: what changed (load, volume, or a substitution), why (the engine's plain-language reasoning plus the reason codes behind it), and how confident it was. Nothing in the app ever edits or deletes an existing entry — it's append-only, exactly like the set log it's built from. You can see the full history under **Plan → Decision History**, and a weekly progressions/deloads summary under **Progress → Adaptation Summary**.

This is deliberately recorded at workout-completion time (a single, deliberate user action), not whenever a coaching card happens to be displayed — so the ledger reflects real decisions, not screen redraws.

## Status

| Area | Status |
|---|---|
| Onboarding + starter plan generation | Done |
| Workout logging (sets, reps, load, RPE) | Done |
| Adaptive Training Intelligence engine | Done, 21+ unit tests |
| Decision ledger (immutable adaptation history) | Done |
| Daily readiness check-in | Not started |
| Progress charts | Not started |
| HealthKit (optional, read-only) | Not started |
| Apple Intelligence coach copy | Not started |

## Future roadmap

- Daily readiness check-in (real energy/sleep/stress/soreness input, replacing today's conservative default)
- Progress charts (strength trends, volume, adherence)
- HealthKit (optional, read-only: body mass, sleep, resting heart rate, HRV)
- On-device Apple Intelligence coach copy (rephrasing only — it can never bypass or modify an ATI decision)
- ATI v2: weekly adaptation across a whole plan, not just per-exercise

## Tech stack

- **SwiftUI**, **SwiftData** (local-only, CloudKit disabled), Swift 6 strict concurrency
- **MVVM** with the `@Observable` macro for state (no Combine, no `ObservableObject`)
- Domain and coaching logic lives in **`WorkoutPartnerCore`**, a local Swift package with zero SwiftUI/SwiftData/HealthKit imports — the rules engine is pure, deterministic, and testable in isolation
- **Swift Testing** (`@Test`/`#expect`) throughout

## Project structure

```
Workout Partner.xcodeproj      Xcode project (app: Repvera)
Workout Partner/               App target (SwiftUI screens, SwiftData persistence)
Workout PartnerTests/          App-level persistence/integration tests
WorkoutPartnerCore/            Local Swift package: domain models + ATI engine
knowledge base/                Product, architecture, and decision docs
```

See [`knowledge base/03_SYSTEM_ARCHITECTURE.md`](knowledge%20base/03_SYSTEM_ARCHITECTURE.md) for the layering, [`04_ADAPTIVE_TRAINING_INTELLIGENCE.md`](knowledge%20base/04_ADAPTIVE_TRAINING_INTELLIGENCE.md) for the full ATI rule set, and [`09_ARCHITECTURE_DECISIONS.md`](knowledge%20base/09_ARCHITECTURE_DECISIONS.md) for the ADR log that resolves conflicts between the other docs.

## Requirements

- Xcode 26.6+
- iOS 26+ (iPhone)
- Swift 6

## Building and running

Open `Workout Partner.xcodeproj` in Xcode and run the **Repvera** scheme on an iPhone simulator or device.

## Testing

```bash
# Domain/engine tests (fast, no simulator needed)
cd WorkoutPartnerCore && swift test

# Full app test suite (persistence + integration)
xcodebuild -project "Workout Partner.xcodeproj" -scheme Repvera \
  -destination 'platform=iOS Simulator,name=iPhone 17' test
```

## Privacy

Repvera is local-first: all training data stays on-device in SwiftData, with CloudKit sync explicitly disabled. HealthKit integration, when added, will be strictly opt-in and read-only. See [`knowledge base/06_PRIVACY_HEALTHKIT.md`](knowledge%20base/06_PRIVACY_HEALTHKIT.md) for the full policy.

## License

Apache License 2.0 — see [`LICENSE`](LICENSE).
