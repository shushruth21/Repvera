import SwiftData
import Testing
import WorkoutPartnerCore
@testable import Repvera

struct WorkoutLoggingPersistenceTests {
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
    @Test func startingASessionPersistsItAsInProgress() throws {
        let (container, store, workout) = try makeOnboardedStore()
        _ = container

        let sessionID = store.startSession(for: workout)

        #expect(store.activeSession?.id == sessionID)
        #expect(store.activeSession?.status == .inProgress)
    }

    @MainActor
    @Test func loggingASetPersistsIt() throws {
        let (container, store, workout) = try makeOnboardedStore()
        _ = container
        let prescription = try #require(workout.prescriptions.first)
        let sessionID = store.startSession(for: workout)

        try store.logSet(
            sessionID: sessionID,
            prescription: prescription,
            setIndex: 1,
            repsCompleted: prescription.targetReps,
            loadKilograms: prescription.loadKilograms,
            rpe: 7
        )

        #expect(store.activeSession?.loggedSets.count == 1)
        #expect(store.activeSession?.loggedSets.first?.repsCompleted == prescription.targetReps)
    }

    @MainActor
    @Test func completingASessionMarksItCompletedAndClearsActiveSession() throws {
        let (container, store, workout) = try makeOnboardedStore()
        _ = container
        let sessionID = store.startSession(for: workout)

        try store.completeSession(sessionID: sessionID)

        #expect(store.activeSession == nil)
    }

    @MainActor
    @Test func recentPerformancesOnlyReflectsCompletedSessions() throws {
        let (container, store, workout) = try makeOnboardedStore()
        _ = container
        let prescription = try #require(workout.prescriptions.first)

        let inProgressID = store.startSession(for: workout)
        for setIndex in 1...prescription.sets {
            try store.logSet(sessionID: inProgressID, prescription: prescription, setIndex: setIndex, repsCompleted: prescription.targetReps, loadKilograms: prescription.loadKilograms, rpe: 7)
        }

        #expect(store.recentPerformances(exerciseID: prescription.exerciseID, prescription: prescription).isEmpty)

        try store.completeSession(sessionID: inProgressID)

        let performances = store.recentPerformances(exerciseID: prescription.exerciseID, prescription: prescription)
        #expect(performances.count == 1)
        #expect(performances.first?.completed(prescription) == true)
    }

    @MainActor
    @Test func loggedSetsSurvivePersistenceAcrossAFreshStore() throws {
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
        let prescription = try #require(workout.prescriptions.first)

        let sessionID = store.startSession(for: workout)
        try store.logSet(sessionID: sessionID, prescription: prescription, setIndex: 1, repsCompleted: prescription.targetReps, loadKilograms: prescription.loadKilograms, rpe: 7)
        try store.completeSession(sessionID: sessionID)

        let reloadedStore = TrainingStore(context: container.mainContext)
        let performances = reloadedStore.recentPerformances(exerciseID: prescription.exerciseID, prescription: prescription)
        #expect(performances.count == 1)
        #expect(reloadedStore.completedSessionsThisWeek() == 1)
    }
}
