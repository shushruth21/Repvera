import SwiftData
import Testing
import WorkoutPartnerCore
@testable import Repvera

struct TrainingDecisionLedgerTests {
    @MainActor
    private func makeOnboardedStore() throws -> (container: ModelContainer, store: TrainingStore, workout: PlannedWorkoutDraft) {
        let container = try RepveraSchema.makeContainer(inMemory: true)
        let store = TrainingStore(context: container.mainContext)
        let input = PlanGenerationInput(
            profile: TrainingProfile(goal: .buildStrength, experience: .intermediate),
            availableWeekdays: [2, 4, 6],
            sessionDurationMinutes: 45,
            equipment: EquipmentKind.homeGym
        )
        try store.completeOnboarding(input, bodyMassKilograms: 82)
        let workout = try #require(store.plan?.workouts.first)
        return (container, store, workout)
    }

    @MainActor
    private func completeSession(
        store: TrainingStore,
        workout: PlannedWorkoutDraft,
        prescription: ExercisePrescription,
        rpe: Double
    ) throws {
        let sessionID = store.startSession(for: workout)
        for setIndex in 1...prescription.sets {
            try store.logSet(
                sessionID: sessionID,
                prescription: prescription,
                setIndex: setIndex,
                repsCompleted: prescription.targetReps,
                loadKilograms: prescription.loadKilograms,
                rpe: rpe
            )
        }
        try store.completeSession(sessionID: sessionID)
    }

    @MainActor
    @Test func firstCompletedSessionRecordsABaselineDecision() throws {
        let (container, store, workout) = try makeOnboardedStore()
        _ = container
        let prescription = try #require(workout.prescriptions.first)

        try completeSession(store: store, workout: workout, prescription: prescription, rpe: 7)

        let history = store.decisionHistory(for: prescription.exerciseID)
        #expect(history.count == 1)
        #expect(history.first?.decisionType == .maintain)
    }

    @MainActor
    @Test func twoEasyComparableSessionsRecordAnIncreaseLoadDecision() throws {
        let (container, store, workout) = try makeOnboardedStore()
        _ = container
        let prescription = try #require(workout.prescriptions.first)

        try completeSession(store: store, workout: workout, prescription: prescription, rpe: 7)
        try completeSession(store: store, workout: workout, prescription: prescription, rpe: 7)

        let history = store.decisionHistory(for: prescription.exerciseID)
        #expect(history.count == 2)
        #expect(history.first?.decisionType == .increaseLoad)
        if let previousLoad = prescription.loadKilograms {
            #expect(history.first?.newWeightKilograms == previousLoad + 2.5)
        }
    }

    @MainActor
    @Test func decisionHistoryIsNewestFirst() throws {
        let (container, store, workout) = try makeOnboardedStore()
        _ = container
        let prescription = try #require(workout.prescriptions.first)

        try completeSession(store: store, workout: workout, prescription: prescription, rpe: 7)
        try completeSession(store: store, workout: workout, prescription: prescription, rpe: 7)

        let history = store.decisionHistory(for: prescription.exerciseID)
        let timestamps = history.map(\.recordedAt)
        #expect(timestamps == timestamps.sorted(by: >))
    }

    @MainActor
    @Test func decisionHistoryForExerciseFiltersToThatExerciseOnly() throws {
        let (container, store, workout) = try makeOnboardedStore()
        _ = container
        let prescription = try #require(workout.prescriptions.first)

        try completeSession(store: store, workout: workout, prescription: prescription, rpe: 7)

        #expect(store.decisionHistory(for: "nonexistent_exercise").isEmpty)
        #expect(store.decisionHistory(for: prescription.exerciseID).count == 1)
    }

    @MainActor
    @Test func weeklyDecisionSummaryCountsThisWeeksDecisions() throws {
        let (container, store, workout) = try makeOnboardedStore()
        _ = container
        let prescription = try #require(workout.prescriptions.first)

        try completeSession(store: store, workout: workout, prescription: prescription, rpe: 7)
        try completeSession(store: store, workout: workout, prescription: prescription, rpe: 7)

        let summary = store.weeklyDecisionSummary()
        #expect(summary.total == 2)
        #expect(summary.progressions == 1)
    }

    @MainActor
    @Test func completingASessionWithNoLoggedSetsRecordsNoDecisions() throws {
        let (container, store, workout) = try makeOnboardedStore()
        _ = container

        let sessionID = store.startSession(for: workout)
        try store.completeSession(sessionID: sessionID)

        #expect(store.decisionHistory().isEmpty)
    }

    @MainActor
    @Test func decisionsSurvivePersistenceAcrossAFreshStore() throws {
        let (container, store, workout) = try makeOnboardedStore()
        let prescription = try #require(workout.prescriptions.first)

        try completeSession(store: store, workout: workout, prescription: prescription, rpe: 7)

        let reloadedStore = TrainingStore(context: container.mainContext)
        #expect(reloadedStore.decisionHistory(for: prescription.exerciseID).count == 1)
    }
}
