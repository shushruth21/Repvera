import Foundation

// MARK: - Decision type

/// A richer, display-friendly vocabulary for the decision ledger. Always
/// derived from `TrainingAction` via `from(_:)` — never assigned ad hoc at a
/// call site — so the ledger's labels can never drift from what the engine
/// actually decided.
public enum TrainingDecisionType: String, Sendable, Codable, CaseIterable, Identifiable {
    case increaseLoad
    case decreaseLoad
    case maintain
    case increaseVolume
    case decreaseVolume
    case deload
    case resetProgression
    case exerciseSwap
    case custom

    public var id: String { rawValue }

    public var label: String {
        switch self {
        case .increaseLoad: "Weight increased"
        case .decreaseLoad: "Weight decreased"
        case .maintain: "Held steady"
        case .increaseVolume: "Volume increased"
        case .decreaseVolume: "Volume reduced"
        case .deload: "Deload"
        case .resetProgression: "Progression reset"
        case .exerciseSwap: "Exercise swapped"
        case .custom: "Adjusted"
        }
    }

    /// Maps the engine's actual `TrainingAction` output to the ledger's
    /// vocabulary. `decreaseLoad`, `increaseVolume`, `resetProgression`, and
    /// `custom` are unreachable from the v1 engine today — reserved for when
    /// it grows those distinct behaviors.
    public static func from(_ action: TrainingAction) -> TrainingDecisionType {
        switch action {
        case .increaseLoad: .increaseLoad
        case .reduceVolume: .decreaseVolume
        case .holdLoad: .maintain
        case .keepPrescription: .maintain
        case .pauseAndReplace: .deload
        case .selectSubstitution: .exerciseSwap
        }
    }
}

// MARK: - Confidence

public extension TrainingDecision {
    /// A pure, testable numeric counterpart to how confident the engine was
    /// in this decision, for ledger analytics. Independent of any UI copy.
    var confidenceScore: Double {
        switch reasons.first {
        case .repeatedEasyCompletion: 0.9
        case .severePainReported, .equipmentUnavailable, .targetMissed, .highPerceivedExertion, .lowReadiness: 0.8
        case .noComparableHistory: 0.3
        case .performanceOnTarget, .none: 0.6
        }
    }
}

// MARK: - Decision log

/// One immutable, permanent record of a decision the adaptive engine made
/// about a single exercise, at the moment a workout session completed.
public struct TrainingDecisionLog: Sendable, Equatable, Identifiable {
    public let id: UUID
    public let sessionID: UUID
    public let exerciseID: String
    public let exerciseName: String
    public let decisionType: TrainingDecisionType
    public let previousWeightKilograms: Double?
    public let newWeightKilograms: Double?
    public let previousReps: Int
    public let newReps: Int
    public let previousSets: Int
    public let newSets: Int
    public let averageRPE: Double
    public let completionRate: Double
    public let fatigueScore: Double
    public let confidence: Double
    public let reasoning: String
    public let adaptationVersion: Int
    public let notes: String
    public let recordedAt: Date

    public init(
        id: UUID = UUID(),
        sessionID: UUID,
        exerciseID: String,
        exerciseName: String,
        decisionType: TrainingDecisionType,
        previousWeightKilograms: Double?,
        newWeightKilograms: Double?,
        previousReps: Int,
        newReps: Int,
        previousSets: Int,
        newSets: Int,
        averageRPE: Double,
        completionRate: Double,
        fatigueScore: Double,
        confidence: Double,
        reasoning: String,
        adaptationVersion: Int,
        notes: String,
        recordedAt: Date = .now
    ) {
        self.id = id
        self.sessionID = sessionID
        self.exerciseID = exerciseID
        self.exerciseName = exerciseName
        self.decisionType = decisionType
        self.previousWeightKilograms = previousWeightKilograms
        self.newWeightKilograms = newWeightKilograms
        self.previousReps = previousReps
        self.newReps = newReps
        self.previousSets = previousSets
        self.newSets = newSets
        self.averageRPE = averageRPE
        self.completionRate = completionRate
        self.fatigueScore = fatigueScore
        self.confidence = confidence
        self.reasoning = reasoning
        self.adaptationVersion = adaptationVersion
        self.notes = notes
        self.recordedAt = recordedAt
    }
}

// MARK: - Summary

public struct DecisionSummary: Sendable, Equatable {
    public let progressions: Int
    public let deloadsOrHolds: Int
    public let substitutions: Int
    public let total: Int
    public let averageConfidence: Double

    public init(progressions: Int, deloadsOrHolds: Int, substitutions: Int, total: Int, averageConfidence: Double) {
        self.progressions = progressions
        self.deloadsOrHolds = deloadsOrHolds
        self.substitutions = substitutions
        self.total = total
        self.averageConfidence = averageConfidence
    }

    public static func summarizing(_ decisions: [TrainingDecisionLog]) -> DecisionSummary {
        DecisionSummary(
            progressions: numberOfProgressions(decisions),
            deloadsOrHolds: numberOfDeloads(decisions),
            substitutions: decisions.filter { $0.decisionType == .exerciseSwap }.count,
            total: decisions.count,
            averageConfidence: decisions.isEmpty ? 0 : decisions.map(\.confidence).reduce(0, +) / Double(decisions.count)
        )
    }
}

// MARK: - Analytics

/// Pure functions over decision history, independent of persistence, so any
/// future dashboard can reuse them without touching SwiftData.
public func numberOfProgressions(_ decisions: [TrainingDecisionLog]) -> Int {
    decisions.filter { $0.decisionType == .increaseLoad || $0.decisionType == .increaseVolume }.count
}

public func numberOfDeloads(_ decisions: [TrainingDecisionLog]) -> Int {
    decisions.filter { $0.decisionType == .deload || $0.decisionType == .decreaseLoad || $0.decisionType == .decreaseVolume }.count
}

/// Decisions recorded per week, spanning the earliest to the latest entry.
/// Returns 0 when there are fewer than two entries (no span to measure).
public func adaptationFrequency(_ decisions: [TrainingDecisionLog]) -> Double {
    guard decisions.count > 1,
          let earliest = decisions.map(\.recordedAt).min(),
          let latest = decisions.map(\.recordedAt).max() else { return 0 }
    let weeks = max(latest.timeIntervalSince(earliest) / (60 * 60 * 24 * 7), 1.0 / 7)
    return Double(decisions.count) / weeks
}

/// Mean load increase across `.increaseLoad` decisions with a known load.
public func averageIncrease(_ decisions: [TrainingDecisionLog]) -> Double {
    let increases = decisions
        .filter { $0.decisionType == .increaseLoad }
        .compactMap { decision -> Double? in
            guard let previous = decision.previousWeightKilograms, let new = decision.newWeightKilograms else { return nil }
            return new - previous
        }
    guard !increases.isEmpty else { return 0 }
    return increases.reduce(0, +) / Double(increases.count)
}

public func averageRPE(_ decisions: [TrainingDecisionLog]) -> Double {
    guard !decisions.isEmpty else { return 0 }
    return decisions.map(\.averageRPE).reduce(0, +) / Double(decisions.count)
}
