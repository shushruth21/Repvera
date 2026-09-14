import Foundation

// MARK: - Session status

public enum WorkoutSessionStatus: String, Sendable, Codable, CaseIterable {
    case inProgress
    case completed
    case abandoned
}

// MARK: - Logged set

/// One completed set, exactly as performed, independent of the prescription
/// it was measured against. Immutable once created — the log is append-only.
public struct LoggedSet: Sendable, Codable, Equatable, Identifiable {
    public let id: UUID
    public let prescriptionID: UUID
    public let exerciseID: String
    public let setIndex: Int
    public let repsCompleted: Int
    public let loadKilograms: Double?
    public let rpe: Double?
    public let loggedAt: Date

    public init(
        id: UUID = UUID(),
        prescriptionID: UUID,
        exerciseID: String,
        setIndex: Int,
        repsCompleted: Int,
        loadKilograms: Double?,
        rpe: Double?,
        loggedAt: Date = .now
    ) {
        self.id = id
        self.prescriptionID = prescriptionID
        self.exerciseID = exerciseID
        self.setIndex = setIndex
        self.repsCompleted = repsCompleted
        self.loadKilograms = loadKilograms
        self.rpe = rpe
        self.loggedAt = loggedAt
    }
}

// MARK: - Session log

public struct WorkoutSessionLog: Sendable, Equatable, Identifiable {
    public let id: UUID
    public let plannedWorkoutID: UUID
    public let status: WorkoutSessionStatus
    public let startedAt: Date
    public let completedAt: Date?
    public let loggedSets: [LoggedSet]

    public init(
        id: UUID = UUID(),
        plannedWorkoutID: UUID,
        status: WorkoutSessionStatus,
        startedAt: Date,
        completedAt: Date?,
        loggedSets: [LoggedSet]
    ) {
        self.id = id
        self.plannedWorkoutID = plannedWorkoutID
        self.status = status
        self.startedAt = startedAt
        self.completedAt = completedAt
        self.loggedSets = loggedSets
    }

    /// Sets for one exercise, oldest-first, ready for ExercisePerformance aggregation.
    public func loggedSets(forExerciseID exerciseID: String) -> [LoggedSet] {
        loggedSets.filter { $0.exerciseID == exerciseID }.sorted { $0.setIndex < $1.setIndex }
    }
}
