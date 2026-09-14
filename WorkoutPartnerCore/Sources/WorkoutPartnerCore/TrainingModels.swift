import Foundation

public enum TrainingGoal: String, Sendable, Codable, CaseIterable, Identifiable {
    case buildMuscle
    case loseFat
    case buildStrength
    case generalFitness

    public var id: String { rawValue }

    public var label: String {
        switch self {
        case .buildMuscle: "Build muscle"
        case .loseFat: "Lose fat"
        case .buildStrength: "Build strength"
        case .generalFitness: "General fitness"
        }
    }
}

public enum TrainingExperience: String, Sendable, Codable, CaseIterable, Identifiable {
    case beginner
    case intermediate
    case advanced

    public var id: String { rawValue }

    public var label: String {
        switch self {
        case .beginner: "Beginner"
        case .intermediate: "Intermediate"
        case .advanced: "Advanced"
        }
    }
}

public enum MovementPattern: String, Sendable, Codable, CaseIterable, Identifiable {
    case squat
    case hinge
    case horizontalPush
    case horizontalPull
    case verticalPush
    case verticalPull
    case singleLeg
    case carry
    case isolation

    public var id: String { rawValue }

    public var label: String {
        switch self {
        case .squat: "Squat"
        case .hinge: "Hinge"
        case .horizontalPush: "Horizontal push"
        case .horizontalPull: "Horizontal pull"
        case .verticalPush: "Vertical push"
        case .verticalPull: "Vertical pull"
        case .singleLeg: "Single-leg"
        case .carry: "Carry"
        case .isolation: "Accessory"
        }
    }
}

public struct TrainingProfile: Sendable, Codable, Equatable {
    public let goal: TrainingGoal
    public let experience: TrainingExperience
    public let minimumLoadIncrementKilograms: Double

    public init(
        goal: TrainingGoal,
        experience: TrainingExperience,
        minimumLoadIncrementKilograms: Double = 2.5
    ) {
        self.goal = goal
        self.experience = experience
        self.minimumLoadIncrementKilograms = minimumLoadIncrementKilograms
    }
}

public struct ExercisePrescription: Sendable, Codable, Equatable, Identifiable {
    public let id: UUID
    public let exerciseID: String
    public let movementPattern: MovementPattern
    public let sets: Int
    public let targetReps: Int
    public let loadKilograms: Double?
    public let targetRPE: Double
    public let restSeconds: Int?

    public init(
        id: UUID = UUID(),
        exerciseID: String,
        movementPattern: MovementPattern,
        sets: Int,
        targetReps: Int,
        loadKilograms: Double?,
        targetRPE: Double,
        restSeconds: Int? = nil
    ) {
        self.id = id
        self.exerciseID = exerciseID
        self.movementPattern = movementPattern
        self.sets = sets
        self.targetReps = targetReps
        self.loadKilograms = loadKilograms
        self.targetRPE = targetRPE
        self.restSeconds = restSeconds
    }
}

public struct ExercisePerformance: Sendable, Codable, Equatable {
    public let completedSets: Int
    public let lowestCompletedReps: Int
    public let highestRPE: Double
    public let failedReps: Int

    public init(
        completedSets: Int,
        lowestCompletedReps: Int,
        highestRPE: Double,
        failedReps: Int = 0
    ) {
        self.completedSets = completedSets
        self.lowestCompletedReps = lowestCompletedReps
        self.highestRPE = highestRPE
        self.failedReps = failedReps
    }

    public func completed(_ prescription: ExercisePrescription) -> Bool {
        completedSets >= prescription.sets
            && lowestCompletedReps >= prescription.targetReps
            && failedReps == 0
    }

    /// Summarizes one session's logged sets for a single exercise, judged
    /// against the prescription they were performed under. Returns `nil`
    /// when there is nothing logged yet for that exercise.
    public static func summarizing(_ sets: [LoggedSet], against prescription: ExercisePrescription) -> ExercisePerformance? {
        let completedSets = sets.filter { $0.repsCompleted > 0 }
        guard !completedSets.isEmpty else { return nil }
        let lowestReps = completedSets.map(\.repsCompleted).min() ?? 0
        let highestRPE = sets.compactMap(\.rpe).max() ?? 0
        let failedReps = completedSets.filter { $0.repsCompleted < prescription.targetReps }.count
        return ExercisePerformance(
            completedSets: completedSets.count,
            lowestCompletedReps: lowestReps,
            highestRPE: highestRPE,
            failedReps: failedReps
        )
    }
}

public struct ReadinessSnapshot: Sendable, Codable, Equatable {
    /// A 1...10 self-reported check-in. HealthKit-derived metrics are optional
    /// supplemental evidence and should never be interpreted as a diagnosis.
    public let energy: Int
    public let sleepQuality: Int
    public let stress: Int
    public let soreness: Int
    public let sleepHours: Double?
    public let hrvBelowBaseline: Bool?
    public let restingHeartRateAboveBaseline: Bool?

    public init(
        energy: Int,
        sleepQuality: Int,
        stress: Int,
        soreness: Int,
        sleepHours: Double? = nil,
        hrvBelowBaseline: Bool? = nil,
        restingHeartRateAboveBaseline: Bool? = nil
    ) {
        self.energy = min(max(energy, 1), 10)
        self.sleepQuality = min(max(sleepQuality, 1), 10)
        self.stress = min(max(stress, 1), 10)
        self.soreness = min(max(soreness, 1), 10)
        self.sleepHours = sleepHours
        self.hrvBelowBaseline = hrvBelowBaseline
        self.restingHeartRateAboveBaseline = restingHeartRateAboveBaseline
    }

    public var needsConservativeSession: Bool {
        let poorCheckIn = energy <= 3 || sleepQuality <= 3 || stress >= 8 || soreness >= 8
        let poorSleep = (sleepHours ?? .greatestFiniteMagnitude) < 5.5
        let adverseHealthSignals = hrvBelowBaseline == true && restingHeartRateAboveBaseline == true
        return poorCheckIn || poorSleep || adverseHealthSignals
    }

    /// The conservative "nothing reported yet" baseline used wherever a real
    /// daily check-in hasn't been collected. A single shared constant so the
    /// same assumption isn't hand-typed at every call site.
    public static let defaultOptimistic = ReadinessSnapshot(energy: 8, sleepQuality: 8, stress: 3, soreness: 3)
}

public struct ExerciseContext: Sendable, Codable, Equatable {
    public let prescription: ExercisePrescription
    /// Latest comparable performances at the current prescription, oldest first.
    public let recentPerformances: [ExercisePerformance]
    public let readiness: ReadinessSnapshot
    public let painLevel: Int
    public let equipmentAvailable: Bool

    public init(
        prescription: ExercisePrescription,
        recentPerformances: [ExercisePerformance],
        readiness: ReadinessSnapshot,
        painLevel: Int = 0,
        equipmentAvailable: Bool = true
    ) {
        self.prescription = prescription
        self.recentPerformances = recentPerformances
        self.readiness = readiness
        self.painLevel = min(max(painLevel, 0), 10)
        self.equipmentAvailable = equipmentAvailable
    }
}
