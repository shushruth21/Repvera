import SwiftUI
import WorkoutPartnerCore

struct CoachExplanationCard: View {
    let decision: TrainingDecision
    let exerciseName: String
    let previousLoadKilograms: Double?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("COACH NOTE")
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)

            Label(
                decision.action == .keepPrescription ? "ATI kept your prescription" : "ATI changed your next session",
                systemImage: "brain.head.profile"
            )
            .font(.headline)

            explanationBlock(title: "Changed", text: changedLine)
            explanationBlock(title: "Why", text: decision.coachExplanation)
            explanationBlock(title: "Confidence", text: confidenceLine)
            explanationBlock(title: "Action", text: actionLine)

            HStack(spacing: 8) {
                ForEach(decision.reasons, id: \.rawValue) { reason in
                    Text(reason.label)
                        .font(.caption.weight(.medium))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.repveraAccent.opacity(0.12), in: Capsule())
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(decision.reasons.map(\.label).joined(separator: ", "))
        }
        .padding(18)
        .background(Color.repveraAccent.opacity(0.07), in: RoundedRectangle(cornerRadius: 20))
    }

    private var changedLine: String {
        let nextLoad = decision.prescription?.loadKilograms
        switch decision.action {
        case .increaseLoad:
            if let previousLoadKilograms, let nextLoad {
                return "\(exerciseName) \(format(previousLoadKilograms)) kg → \(format(nextLoad)) kg"
            }
            return "Load increased for \(exerciseName)"
        case .reduceVolume:
            if let sets = decision.prescription?.sets {
                return "\(exerciseName) volume reduced to \(sets) sets"
            }
            return "Volume reduced for \(exerciseName)"
        case .holdLoad:
            return "\(exerciseName) load held"
        case .pauseAndReplace:
            return "\(exerciseName) paused"
        case .selectSubstitution:
            return "\(exerciseName) needs a substitute"
        case .keepPrescription:
            return "No prescription change"
        }
    }

    private var confidenceLine: String {
        switch decision.reasons.first {
        case .repeatedEasyCompletion:
            return "High — two comparable sessions were logged."
        case .severePainReported, .equipmentUnavailable, .targetMissed, .highPerceivedExertion, .lowReadiness:
            return "High — based on the latest logged session and check-in."
        case .noComparableHistory:
            return "Low — this is a baseline session."
        case .performanceOnTarget, .none:
            return "Medium — recent performance is on target."
        }
    }

    private var actionLine: String {
        switch decision.action {
        case .increaseLoad, .keepPrescription, .holdLoad, .reduceVolume:
            return "Start the next session with the updated prescription."
        case .pauseAndReplace:
            return "Stop the affected movement and choose a comfortable alternative."
        case .selectSubstitution:
            return "Pick a vetted substitute from the same movement pattern."
        }
    }

    private func explanationBlock(title: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(text)
                .font(.subheadline)
        }
        .accessibilityElement(children: .combine)
    }

    private func format(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(0...1)))
    }
}
