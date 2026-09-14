import SwiftUI
import SwiftData
import WorkoutPartnerCore

struct ProgressScreen: View {
    @Environment(TrainingStore.self) private var store

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Your progress is built from completed sessions—not promises.")
                        .font(.title3.weight(.semibold))

                    if store.hasCompletedOnboarding {
                        HStack(spacing: 12) {
                            MetricTile(value: "\(store.completedSessionsThisWeek())", label: "sessions this week")
                            MetricTile(value: "v\(store.plan?.version ?? 1)", label: "plan")
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            Text("NEXT WEEKLY REVIEW")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.secondary)
                            Text("Log workouts first. A weekly summary can appear later; the plan will not rewrite itself until ATI weekly adaptation exists.")
                                .foregroundStyle(.secondary)
                        }
                        .padding(18)
                        .background(Color.secondary.opacity(0.09), in: RoundedRectangle(cornerRadius: 20))

                        VStack(alignment: .leading, spacing: 12) {
                            Text("ADAPTATION SUMMARY")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.secondary)
                            let summary = store.weeklyDecisionSummary()
                            HStack(spacing: 12) {
                                MetricTile(value: "\(summary.progressions)", label: "progressions")
                                MetricTile(value: "\(summary.deloadsOrHolds)", label: "deloads / holds")
                            }
                        }
                    } else {
                        Text("Confirm a starter plan to begin tracking strength, volume, and adherence.")
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
            }
            .navigationTitle("Progress")
        }
    }
}

#Preview {
    let container = try! RepveraSchema.makeContainer(inMemory: true)
    return ProgressScreen()
        .environment(TrainingStore(context: container.mainContext))
        .modelContainer(container)
}
