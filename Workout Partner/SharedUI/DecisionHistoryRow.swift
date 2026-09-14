import SwiftUI
import WorkoutPartnerCore

/// One entry in the training decision ledger: collapsed shows what changed
/// and when; expanded shows the full reasoning behind it. Nothing here is
/// editable — the ledger is a read-only history.
struct DecisionHistoryRow: View {
    let decision: TrainingDecisionLog

    var body: some View {
        DisclosureGroup {
            VStack(alignment: .leading, spacing: 8) {
                Text(decision.reasoning)
                    .font(.subheadline)
                LabeledContent("Average RPE", value: decision.averageRPE.formatted(.number.precision(.fractionLength(1))))
                LabeledContent("Fatigue", value: qualitativeLabel(decision.fatigueScore))
                LabeledContent("Confidence", value: qualitativeLabel(decision.confidence))
            }
            .padding(.top, 6)
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline) {
                    Text(decision.exerciseName)
                        .font(.headline)
                    Spacer()
                    Text(deltaLabel)
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.repveraAccent.opacity(0.12), in: Capsule())
                }
                HStack {
                    Text(decision.decisionType.label)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(decision.recordedAt.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(18)
        .background(Color.secondary.opacity(0.09), in: RoundedRectangle(cornerRadius: 20))
        .accessibilityElement(children: .contain)
    }

    private var deltaLabel: String {
        switch decision.decisionType {
        case .increaseLoad, .decreaseLoad:
            guard let previous = decision.previousWeightKilograms, let new = decision.newWeightKilograms else { return "—" }
            let delta = new - previous
            let sign = delta >= 0 ? "+" : ""
            return "\(sign)\(delta.formatted(.number.precision(.fractionLength(0...1)))) kg"
        case .increaseVolume, .decreaseVolume:
            let delta = decision.newSets - decision.previousSets
            let sign = delta >= 0 ? "+" : ""
            return "\(sign)\(delta) set\(abs(delta) == 1 ? "" : "s")"
        case .maintain:
            return "held"
        case .deload:
            return "paused"
        case .exerciseSwap:
            return "swapped"
        case .resetProgression, .custom:
            return "adjusted"
        }
    }

    private func qualitativeLabel(_ score: Double) -> String {
        switch score {
        case ..<0.4: "Low"
        case ..<0.7: "Medium"
        default: "High"
        }
    }
}

#Preview {
    List {
        DecisionHistoryRow(decision: TrainingDecisionLog(
            sessionID: UUID(),
            exerciseID: "barbell_bench_press",
            exerciseName: "Barbell bench press",
            decisionType: .increaseLoad,
            previousWeightKilograms: 60,
            newWeightKilograms: 62.5,
            previousReps: 6,
            newReps: 6,
            previousSets: 4,
            newSets: 4,
            averageRPE: 7.3,
            completionRate: 1.0,
            fatigueScore: 0.3,
            confidence: 0.9,
            reasoning: "Increase by 2.5 kg. You completed the target in two comparable sessions with manageable effort.",
            adaptationVersion: 1,
            notes: "ready to progress"
        ))
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
    }
}
