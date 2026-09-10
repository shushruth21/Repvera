import Testing
@testable import WorkoutPartnerCore

struct AdaptiveTrainingEngineTests {
    private let engine = AdaptiveTrainingEngine()
    private let profile = TrainingProfile(goal: .buildStrength, experience: .intermediate)
    private let prescription = ExercisePrescription(
        exerciseID: "barbell_bench_press",
        movementPattern: .horizontalPush,
        sets: 4,
        targetReps: 8,
        loadKilograms: 100,
        targetRPE: 8
    )
    private let ready = ReadinessSnapshot(energy: 8, sleepQuality: 8, stress: 3, soreness: 3)
    private let easy = ExercisePerformance(completedSets: 4, lowestCompletedReps: 8, highestRPE: 6)

    @Test func progressesLoadOnlyAfterTwoEasyComparableSessions() {
        let decision = decide(performances: [easy, easy])

        #expect(decision.action == .increaseLoad)
        #expect(decision.prescription?.loadKilograms == 102.5)
        #expect(decision.reasons == [.repeatedEasyCompletion])
    }

    @Test func holdsLoadAfterMissedTarget() {
        let performance = ExercisePerformance(completedSets: 4, lowestCompletedReps: 5, highestRPE: 10, failedReps: 3)
        let decision = decide(performances: [performance])

        #expect(decision.action == .holdLoad)
        #expect(decision.prescription == prescription)
        #expect(decision.reasons.contains(.targetMissed))
        #expect(decision.reasons.contains(.highPerceivedExertion))
    }

    @Test func holdsLoadAfterHighPerceivedExertion() {
        let performance = ExercisePerformance(completedSets: 4, lowestCompletedReps: 8, highestRPE: 9)
        let decision = decide(performances: [performance])

        #expect(decision.action == .holdLoad)
        #expect(decision.prescription?.loadKilograms == 100)
        #expect(decision.reasons == [.highPerceivedExertion])
    }

    @Test func reducesVolumeWhenReadinessIsPoor() {
        let poorReadiness = ReadinessSnapshot(energy: 2, sleepQuality: 2, stress: 9, soreness: 6, sleepHours: 5)
        let decision = decide(performances: [], readiness: poorReadiness)

        #expect(decision.action == .reduceVolume)
        #expect(decision.prescription?.sets == 3)
        #expect(decision.prescription?.loadKilograms == 100)
        #expect(decision.reasons == [.lowReadiness])
    }

    @Test func pausesMovementAtSeverePainThreshold() {
        let decision = decide(performances: [], painLevel: 7)

        #expect(decision.action == .pauseAndReplace)
        #expect(decision.prescription == nil)
        #expect(decision.reasons == [.severePainReported])
    }

    @Test func requestsSubstituteWhenEquipmentIsUnavailable() {
        let decision = decide(performances: [], equipmentAvailable: false)

        #expect(decision.action == .selectSubstitution)
        #expect(decision.prescription == nil)
        #expect(decision.reasons == [.equipmentUnavailable])
    }

    @Test func keepsPrescriptionWhenThereIsNoComparableHistory() {
        let decision = decide(performances: [])

        #expect(decision.action == .keepPrescription)
        #expect(decision.prescription == prescription)
        #expect(decision.reasons == [.noComparableHistory])
    }

    @Test func identicalInputsReturnIdenticalDecisions() {
        let context = ExerciseContext(
            prescription: prescription,
            recentPerformances: [easy, easy],
            readiness: ready
        )

        #expect(engine.decide(profile: profile, context: context) == engine.decide(profile: profile, context: context))
    }

    @Test func missingHealthKitSignalsDoNotBlockProgression() {
        let decision = decide(performances: [easy, easy], readiness: ready)

        #expect(decision.action == .increaseLoad)
        #expect(decision.reasons == [.repeatedEasyCompletion])
    }

    @Test func bodyweightWorkDoesNotInventALoadIncrease() {
        let bodyweight = ExercisePrescription(
            exerciseID: "push_up",
            movementPattern: .horizontalPush,
            sets: 3,
            targetReps: 12,
            loadKilograms: nil,
            targetRPE: 7
        )
        let performance = ExercisePerformance(completedSets: 3, lowestCompletedReps: 12, highestRPE: 6)
        let decision = engine.decide(
            profile: profile,
            context: ExerciseContext(
                prescription: bodyweight,
                recentPerformances: [performance, performance],
                readiness: ready
            )
        )

        #expect(decision.action == .keepPrescription)
        #expect(decision.prescription == bodyweight)
        #expect(decision.reasons == [.performanceOnTarget])
    }

    private func decide(
        performances: [ExercisePerformance],
        readiness: ReadinessSnapshot? = nil,
        painLevel: Int = 0,
        equipmentAvailable: Bool = true
    ) -> TrainingDecision {
        engine.decide(
            profile: profile,
            context: ExerciseContext(
                prescription: prescription,
                recentPerformances: performances,
                readiness: readiness ?? ready,
                painLevel: painLevel,
                equipmentAvailable: equipmentAvailable
            )
        )
    }
}
