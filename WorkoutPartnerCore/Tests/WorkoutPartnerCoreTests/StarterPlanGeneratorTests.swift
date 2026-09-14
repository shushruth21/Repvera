import Testing
@testable import WorkoutPartnerCore

struct StarterPlanGeneratorTests {
    private let generator = StarterPlanGenerator()
    private let profile = TrainingProfile(goal: .buildStrength, experience: .intermediate)

    @Test func fourDayGymPlanCreatesFourWorkoutsWithPrescriptions() {
        let plan = generator.generate(input: input(days: [2, 3, 5, 7], equipment: EquipmentKind.commercialGym))

        #expect(plan.version == 1)
        #expect(plan.workouts.count == 4)
        #expect(plan.workouts.map(\.weekday) == [2, 3, 5, 7])
        #expect(plan.workouts.allSatisfy { !$0.prescriptions.isEmpty })
        #expect(plan.workouts[0].title == "Upper Strength")
        #expect(plan.workouts[2].title == "Upper Hypertrophy")
    }

    @Test func bodyweightEquipmentNeverSelectsBarbellWork() {
        let plan = generator.generate(input: input(days: [2, 4, 6], equipment: EquipmentKind.bodyweightOnly))
        let equipment = plan.workouts.flatMap(\.prescriptions).compactMap { ExerciseCatalogue.definition(id: $0.exerciseID)?.requiredEquipment }

        #expect(!equipment.isEmpty)
        #expect(equipment.allSatisfy { $0.isSubset(of: EquipmentKind.bodyweightOnly) })
        #expect(!plan.workouts.flatMap(\.prescriptions).contains { $0.exerciseID.contains("barbell") })
    }

    @Test func squatLimitationExcludesSquatPattern() {
        let plan = generator.generate(
            input: input(days: [2, 4, 6], equipment: EquipmentKind.commercialGym, limited: [.squat])
        )
        let patterns = plan.workouts.flatMap(\.prescriptions).map(\.movementPattern)

        #expect(!patterns.contains(.squat))
        #expect(!patterns.isEmpty)
    }

    @Test func shortSessionsCapExerciseCount() {
        let short = generator.generate(input: input(days: [2, 4], duration: 30, equipment: EquipmentKind.commercialGym))
        let long = generator.generate(input: input(days: [2, 4], duration: 75, equipment: EquipmentKind.commercialGym))

        #expect(short.workouts.allSatisfy { $0.prescriptions.count <= 3 })
        #expect(long.workouts.contains { $0.prescriptions.count > short.workouts[0].prescriptions.count })
    }

    @Test func identicalInputsAreDeterministic() {
        let first = generator.generate(input: input(days: [2, 4, 6], equipment: EquipmentKind.homeGym))
        let second = generator.generate(input: input(days: [2, 4, 6], equipment: EquipmentKind.homeGym))

        #expect(exerciseIDs(first) == exerciseIDs(second))
    }

    @Test func catalogueHasAtLeastThirtyExercisesWithAlternatives() {
        #expect(ExerciseCatalogue.standard.count >= 30)
        #expect(ExerciseCatalogue.standard.count <= 50)
        #expect(!ExerciseCatalogue.alternatives.isEmpty)
    }

    private func input(
        days: [Int],
        duration: Int = 60,
        equipment: Set<EquipmentKind>,
        limited: Set<MovementPattern> = []
    ) -> PlanGenerationInput {
        PlanGenerationInput(
            profile: profile,
            availableWeekdays: days,
            sessionDurationMinutes: duration,
            equipment: equipment,
            limitedMovementPatterns: limited
        )
    }

    private func exerciseIDs(_ plan: TrainingPlanDraft) -> [String] {
        plan.workouts.flatMap { workout in
            workout.prescriptions.map(\.exerciseID)
        }
    }
}
