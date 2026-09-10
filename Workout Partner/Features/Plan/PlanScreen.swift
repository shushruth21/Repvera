import SwiftUI
import WorkoutPartnerCore

struct PlanScreen: View {
    var body: some View {
        NavigationStack {
            List {
                Section("CURRENT PLAN") {
                    ForEach(SampleTraining.week) { session in
                        PlanRow(session: session)
                    }
                }

                Section("DECISION HISTORY") {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Barbell bench press")
                            .font(.headline)
                        Text(SampleTraining.decision.coachExplanation)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                    .accessibilityElement(children: .combine)
                }

                Section("ADAPTIVE RULES") {
                    Label("Progress only after comparable performance", systemImage: "checkmark.shield")
                    Label("Show the reason for every change", systemImage: "text.document")
                    Label("Reduce or replace work when pain is reported", systemImage: "heart.text.square")
                }
            }
            .navigationTitle("Training plan")
        }
    }
}

private struct PlanRow: View {
    let session: SampleSession

    var body: some View {
        HStack {
            Text(session.dayLabel)
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)
                .frame(width: 34, alignment: .leading)
            VStack(alignment: .leading, spacing: 2) {
                Text(session.title)
                if session.status == .today, let changeSummary = session.changeSummary {
                    Text(changeSummary)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Text(session.status.rawValue)
                .font(.caption.weight(.semibold))
                .foregroundStyle(statusColor)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(session.dayLabel) \(session.title), \(session.status.rawValue)")
    }

    private var statusColor: Color {
        switch session.status {
        case .complete: .green
        case .today: .repveraAccent
        case .planned: .secondary
        }
    }
}

#Preview {
    PlanScreen()
}
