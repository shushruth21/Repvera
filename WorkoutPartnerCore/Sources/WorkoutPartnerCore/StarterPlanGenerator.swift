import Foundation

/// Builds a first training block from a curated catalogue. This is template
/// selection, not ATI adaptation, and never calls a language model.
public struct StarterPlanGenerator: Sendable {
    public init() {}

    public func generate(
        input: PlanGenerationInput,
        catalogue: [ExerciseDefinition] = ExerciseCatalogue.standard
    ) -> TrainingPlanDraft {
        let days = input.availableWeekdays
        let templates = SessionTemplate.templates(dayCount: max(days.count, 1), goal: input.profile.goal)
        let usable = catalogue.filter { definition in
            definition.requiredEquipment.isSubset(of: input.equipment)
                && !input.limitedMovementPatterns.contains(definition.movementPattern)
        }
        let slotCount = exerciseCount(for: input.sessionDurationMinutes)

        let workouts = days.enumerated().map { index, weekday in
            let template = templates[index % templates.count]
            let prescriptions = prescriptions(
                for: Array(template.slots.prefix(slotCount)),
                from: usable,
                experience: input.profile.experience
            )
            return PlannedWorkoutDraft(
                weekday: weekday,
                title: template.title,
                focus: template.focus,
                durationMinutes: input.sessionDurationMinutes,
                prescriptions: prescriptions
            )
        }

        return TrainingPlanDraft(version: 1, goal: input.profile.goal, workouts: workouts)
    }

    private func prescriptions(
        for slots: [SessionSlot],
        from catalogue: [ExerciseDefinition],
        experience: TrainingExperience
    ) -> [ExercisePrescription] {
        var used = Set<String>()
        return slots.enumerated().compactMap { order, slot in
            guard let exercise = pick(slot, from: catalogue, excluding: used) else { return nil }
            used.insert(exercise.id)
            return ExercisePrescription(
                exerciseID: exercise.id,
                movementPattern: exercise.movementPattern,
                sets: slot.sets,
                targetReps: slot.reps,
                loadKilograms: exercise.load(for: experience),
                targetRPE: slot.rpe,
                restSeconds: slot.restSeconds
            )
        }
    }

    private func pick(
        _ slot: SessionSlot,
        from catalogue: [ExerciseDefinition],
        excluding used: Set<String>
    ) -> ExerciseDefinition? {
        let patterns = [slot.pattern] + slot.fallbacks
        for pattern in patterns {
            if let match = catalogue.first(where: { $0.movementPattern == pattern && !used.contains($0.id) }) {
                return match
            }
        }
        return catalogue.first { !used.contains($0.id) }
    }

    private func exerciseCount(for durationMinutes: Int) -> Int {
        switch durationMinutes {
        case ...35: 3
        case ...50: 4
        case ...65: 5
        default: 6
        }
    }
}

private struct SessionTemplate {
    let title: String
    let focus: String
    let slots: [SessionSlot]

    static func templates(dayCount: Int, goal: TrainingGoal) -> [SessionTemplate] {
        let strengthBiased = goal == .buildStrength
        switch dayCount {
        case 1, 2:
            return [fullBody("Full Body A", strengthBiased), fullBody("Full Body B", strengthBiased)]
        case 3:
            return [push(strengthBiased), pull(strengthBiased), legs(strengthBiased)]
        case 5:
            return [
                upper("Upper Strength", strength: true),
                lower("Lower Strength", strength: true),
                push(false),
                pull(false),
                legs(false)
            ]
        case 6:
            return [
                push(strengthBiased),
                pull(strengthBiased),
                legs(strengthBiased),
                push(false),
                pull(false),
                legs(false)
            ]
        default:
            return [
                upper("Upper Strength", strength: true),
                lower("Lower Strength", strength: true),
                upper("Upper Hypertrophy", strength: false),
                lower("Lower Hypertrophy", strength: false)
            ]
        }
    }

    static func upper(_ title: String, strength: Bool) -> SessionTemplate {
        SessionTemplate(
            title: title,
            focus: strength ? "Strength" : "Hypertrophy",
            slots: [
                SessionSlot(pattern: .horizontalPush, fallbacks: [.verticalPush], sets: strength ? 4 : 4, reps: strength ? 6 : 10, rpe: 8, restSeconds: 150),
                SessionSlot(pattern: .horizontalPull, fallbacks: [.verticalPull], sets: 4, reps: strength ? 6 : 10, rpe: 8, restSeconds: 150),
                SessionSlot(pattern: .verticalPush, fallbacks: [.horizontalPush], sets: 3, reps: strength ? 8 : 12, rpe: 8, restSeconds: 120),
                SessionSlot(pattern: .verticalPull, fallbacks: [.isolation], sets: 3, reps: 10, rpe: 8, restSeconds: 90),
                SessionSlot(pattern: .isolation, fallbacks: [], sets: 3, reps: 12, rpe: 8, restSeconds: 75),
                SessionSlot(pattern: .isolation, fallbacks: [], sets: 3, reps: 12, rpe: 8, restSeconds: 75)
            ]
        )
    }

    static func lower(_ title: String, strength: Bool) -> SessionTemplate {
        SessionTemplate(
            title: title,
            focus: strength ? "Strength" : "Hypertrophy",
            slots: [
                SessionSlot(pattern: .squat, fallbacks: [.singleLeg], sets: 4, reps: strength ? 5 : 8, rpe: 8, restSeconds: 180),
                SessionSlot(pattern: .hinge, fallbacks: [.squat], sets: 3, reps: strength ? 6 : 10, rpe: 8, restSeconds: 150),
                SessionSlot(pattern: .singleLeg, fallbacks: [.squat], sets: 3, reps: 8, rpe: 8, restSeconds: 120),
                SessionSlot(pattern: .isolation, fallbacks: [], sets: 3, reps: 12, rpe: 8, restSeconds: 75),
                SessionSlot(pattern: .isolation, fallbacks: [], sets: 3, reps: 12, rpe: 8, restSeconds: 75),
                SessionSlot(pattern: .carry, fallbacks: [.isolation], sets: 3, reps: 12, rpe: 7, restSeconds: 75)
            ]
        )
    }

    static func push(_ strength: Bool) -> SessionTemplate {
        SessionTemplate(
            title: strength ? "Push Strength" : "Push",
            focus: strength ? "Strength" : "Hypertrophy",
            slots: [
                SessionSlot(pattern: .horizontalPush, fallbacks: [], sets: 4, reps: strength ? 6 : 10, rpe: 8, restSeconds: 150),
                SessionSlot(pattern: .verticalPush, fallbacks: [.horizontalPush], sets: 3, reps: 8, rpe: 8, restSeconds: 120),
                SessionSlot(pattern: .isolation, fallbacks: [], sets: 3, reps: 12, rpe: 8, restSeconds: 75),
                SessionSlot(pattern: .isolation, fallbacks: [], sets: 3, reps: 12, rpe: 8, restSeconds: 75),
                SessionSlot(pattern: .isolation, fallbacks: [], sets: 3, reps: 15, rpe: 8, restSeconds: 60)
            ]
        )
    }

    static func pull(_ strength: Bool) -> SessionTemplate {
        SessionTemplate(
            title: strength ? "Pull Strength" : "Pull",
            focus: strength ? "Strength" : "Hypertrophy",
            slots: [
                SessionSlot(pattern: .verticalPull, fallbacks: [.horizontalPull], sets: 4, reps: strength ? 6 : 8, rpe: 8, restSeconds: 150),
                SessionSlot(pattern: .horizontalPull, fallbacks: [.verticalPull], sets: 4, reps: 8, rpe: 8, restSeconds: 150),
                SessionSlot(pattern: .isolation, fallbacks: [], sets: 3, reps: 12, rpe: 8, restSeconds: 75),
                SessionSlot(pattern: .isolation, fallbacks: [], sets: 3, reps: 12, rpe: 8, restSeconds: 75),
                SessionSlot(pattern: .carry, fallbacks: [.isolation], sets: 3, reps: 12, rpe: 7, restSeconds: 75)
            ]
        )
    }

    static func legs(_ strength: Bool) -> SessionTemplate {
        SessionTemplate(
            title: strength ? "Leg Strength" : "Legs",
            focus: strength ? "Strength" : "Hypertrophy",
            slots: [
                SessionSlot(pattern: .squat, fallbacks: [.singleLeg], sets: 4, reps: strength ? 5 : 8, rpe: 8, restSeconds: 180),
                SessionSlot(pattern: .hinge, fallbacks: [], sets: 3, reps: 8, rpe: 8, restSeconds: 150),
                SessionSlot(pattern: .singleLeg, fallbacks: [.squat], sets: 3, reps: 8, rpe: 8, restSeconds: 120),
                SessionSlot(pattern: .isolation, fallbacks: [], sets: 3, reps: 12, rpe: 8, restSeconds: 75),
                SessionSlot(pattern: .isolation, fallbacks: [], sets: 3, reps: 12, rpe: 8, restSeconds: 75)
            ]
        )
    }

    static func fullBody(_ title: String, _ strength: Bool) -> SessionTemplate {
        SessionTemplate(
            title: title,
            focus: "Full body",
            slots: [
                SessionSlot(pattern: .squat, fallbacks: [.singleLeg], sets: 3, reps: strength ? 6 : 10, rpe: 8, restSeconds: 150),
                SessionSlot(pattern: .horizontalPush, fallbacks: [.verticalPush], sets: 3, reps: strength ? 6 : 10, rpe: 8, restSeconds: 120),
                SessionSlot(pattern: .hinge, fallbacks: [.squat], sets: 3, reps: 8, rpe: 8, restSeconds: 120),
                SessionSlot(pattern: .horizontalPull, fallbacks: [.verticalPull], sets: 3, reps: 8, rpe: 8, restSeconds: 120),
                SessionSlot(pattern: .verticalPush, fallbacks: [.isolation], sets: 2, reps: 12, rpe: 8, restSeconds: 75)
            ]
        )
    }
}

private struct SessionSlot {
    let pattern: MovementPattern
    let fallbacks: [MovementPattern]
    let sets: Int
    let reps: Int
    let rpe: Double
    let restSeconds: Int
}
