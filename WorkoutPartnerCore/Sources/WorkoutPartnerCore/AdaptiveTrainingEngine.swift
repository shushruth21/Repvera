import Foundation

public enum DecisionReason: String, Sendable, Codable, CaseIterable {
    case severePainReported
    case equipmentUnavailable
    case lowReadiness
    case targetMissed
    case highPerceivedExertion
    case repeatedEasyCompletion
    case noComparableHistory
    case performanceOnTarget
}

public enum TrainingAction: String, Sendable, Codable, Equatable {
    case pauseAndReplace
    case selectSubstitution
    case reduceVolume
    case holdLoad
    case increaseLoad
    case keepPrescription
}

public struct TrainingDecision: Sendable, Codable, Equatable {
    public let action: TrainingAction
    public let prescription: ExercisePrescription?
    public let reasons: [DecisionReason]
    public let coachExplanation: String

    public init(
        action: TrainingAction,
        prescription: ExercisePrescription?,
        reasons: [DecisionReason],
        coachExplanation: String
    ) {
        self.action = action
        self.prescription = prescription
        self.reasons = reasons
        self.coachExplanation = coachExplanation
    }
}

/// A deterministic and deliberately conservative first version of Adaptive
/// Training Intelligence. A language model may rephrase `coachExplanation`,
/// but must not bypass or modify decisions made here.
public struct AdaptiveTrainingEngine: Sendable {
    public init() {}

    public func decide(profile: TrainingProfile, context: ExerciseContext) -> TrainingDecision {
        let prescription = context.prescription

        guard context.painLevel < 7 else {
            return TrainingDecision(
                action: .pauseAndReplace,
                prescription: nil,
                reasons: [.severePainReported],
                coachExplanation: "Pause \(prescription.exerciseID) today because you reported significant pain. Choose a comfortable alternative only after appropriate advice if the pain is severe or persists."
            )
        }

        guard context.equipmentAvailable else {
            return TrainingDecision(
                action: .selectSubstitution,
                prescription: nil,
                reasons: [.equipmentUnavailable],
                coachExplanation: "The required equipment is unavailable. Choose a vetted \(prescription.movementPattern.rawValue) substitute that keeps the same effort and rep target."
            )
        }

        if context.readiness.needsConservativeSession {
            let reducedSets = max(1, prescription.sets - 1)
            let adjusted = copy(prescription, sets: reducedSets)
            return TrainingDecision(
                action: .reduceVolume,
                prescription: adjusted,
                reasons: [.lowReadiness],
                coachExplanation: "Your recovery signals suggest a conservative session. Keep the load steady and complete \(reducedSets) quality set\(reducedSets == 1 ? "" : "s") instead of \(prescription.sets)."
            )
        }

        guard let latest = context.recentPerformances.last else {
            return TrainingDecision(
                action: .keepPrescription,
                prescription: prescription,
                reasons: [.noComparableHistory],
                coachExplanation: "Use this session to establish a comparable performance before making a progression change."
            )
        }

        if !latest.completed(prescription) || latest.highestRPE >= 9 {
            var reasons: [DecisionReason] = []
            if !latest.completed(prescription) { reasons.append(.targetMissed) }
            if latest.highestRPE >= 9 { reasons.append(.highPerceivedExertion) }
            return TrainingDecision(
                action: .holdLoad,
                prescription: prescription,
                reasons: reasons,
                coachExplanation: "Hold the load for the next comparable session. Finish the current target with more control before progressing."
            )
        }

        let hasTwoEasyComparablePerformances = context.recentPerformances.suffix(2).count == 2
            && context.recentPerformances.suffix(2).allSatisfy {
                $0.completed(prescription) && $0.highestRPE <= 7
            }

        if hasTwoEasyComparablePerformances, let load = prescription.loadKilograms {
            let increased = copy(
                prescription,
                loadKilograms: load + profile.minimumLoadIncrementKilograms
            )
            return TrainingDecision(
                action: .increaseLoad,
                prescription: increased,
                reasons: [.repeatedEasyCompletion],
                coachExplanation: "Increase by \(profile.minimumLoadIncrementKilograms.formatted()) kg. You completed the target in two comparable sessions with manageable effort."
            )
        }

        return TrainingDecision(
            action: .keepPrescription,
            prescription: prescription,
            reasons: [.performanceOnTarget],
            coachExplanation: "Keep the prescription unchanged. Your recent performance is on target, so the next step is to repeat it with consistent technique."
        )
    }

    private func copy(
        _ prescription: ExercisePrescription,
        sets: Int? = nil,
        loadKilograms: Double? = nil
    ) -> ExercisePrescription {
        ExercisePrescription(
            id: prescription.id,
            exerciseID: prescription.exerciseID,
            movementPattern: prescription.movementPattern,
            sets: sets ?? prescription.sets,
            targetReps: prescription.targetReps,
            loadKilograms: loadKilograms ?? prescription.loadKilograms,
            targetRPE: prescription.targetRPE
        )
    }
}
