import Testing
@testable import WorkoutPartnerCore

struct WorkoutSessionModelsTests {
    private let prescription = ExercisePrescription(
        exerciseID: "barbell_bench_press",
        movementPattern: .horizontalPush,
        sets: 3,
        targetReps: 8,
        loadKilograms: 60,
        targetRPE: 8
    )

    @Test func summarizingEmptySetsReturnsNil() {
        #expect(ExercisePerformance.summarizing([], against: prescription) == nil)
    }

    @Test func summarizingSetsThatMeetTargetIsCompleted() {
        let sets = (1...3).map {
            LoggedSet(prescriptionID: prescription.id, exerciseID: prescription.exerciseID, setIndex: $0, repsCompleted: 8, loadKilograms: 60, rpe: 7)
        }
        let performance = ExercisePerformance.summarizing(sets, against: prescription)
        #expect(performance?.completed(prescription) == true)
    }

    @Test func summarizingAFailedRepIsReflected() {
        let sets = [
            LoggedSet(prescriptionID: prescription.id, exerciseID: prescription.exerciseID, setIndex: 1, repsCompleted: 8, loadKilograms: 60, rpe: 7),
            LoggedSet(prescriptionID: prescription.id, exerciseID: prescription.exerciseID, setIndex: 2, repsCompleted: 5, loadKilograms: 60, rpe: 9)
        ]
        let performance = ExercisePerformance.summarizing(sets, against: prescription)
        #expect(performance?.failedReps == 1)
        #expect(performance?.completed(prescription) == false)
    }

    @Test func summarizingTakesTheHighestRPE() {
        let sets = [
            LoggedSet(prescriptionID: prescription.id, exerciseID: prescription.exerciseID, setIndex: 1, repsCompleted: 8, loadKilograms: 60, rpe: 6.5),
            LoggedSet(prescriptionID: prescription.id, exerciseID: prescription.exerciseID, setIndex: 2, repsCompleted: 8, loadKilograms: 60, rpe: 8.5)
        ]
        let performance = ExercisePerformance.summarizing(sets, against: prescription)
        #expect(performance?.highestRPE == 8.5)
    }

    @Test func loggedSetsForExerciseIDFiltersAndOrdersBySetIndex() {
        let log = WorkoutSessionLog(
            plannedWorkoutID: prescription.id,
            status: .completed,
            startedAt: .now,
            completedAt: .now,
            loggedSets: [
                LoggedSet(prescriptionID: prescription.id, exerciseID: "other_exercise", setIndex: 1, repsCompleted: 8, loadKilograms: nil, rpe: nil),
                LoggedSet(prescriptionID: prescription.id, exerciseID: prescription.exerciseID, setIndex: 2, repsCompleted: 8, loadKilograms: 60, rpe: 7),
                LoggedSet(prescriptionID: prescription.id, exerciseID: prescription.exerciseID, setIndex: 1, repsCompleted: 8, loadKilograms: 60, rpe: 7)
            ]
        )
        let sets = log.loggedSets(forExerciseID: prescription.exerciseID)
        #expect(sets.map(\.setIndex) == [1, 2])
    }
}
