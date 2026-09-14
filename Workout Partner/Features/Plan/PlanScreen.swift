import SwiftUI
import SwiftData
import WorkoutPartnerCore

struct PlanScreen: View {
    @Environment(TrainingStore.self) private var store

    private var todayWeekday: Int {
        Calendar.current.component(.weekday, from: .now)
    }

    var body: some View {
        NavigationStack {
            List {
                if let plan = store.plan, store.hasCompletedOnboarding {
                    Section("CURRENT PLAN · V\(plan.version)") {
                        ForEach(plan.workouts) { workout in
                            PlanRow(workout: workout, isToday: workout.weekday == todayWeekday)
                        }
                    }

                    Section("DECISION HISTORY") {
                        let history = store.decisionHistory()
                        if history.isEmpty {
                            Text("No adaptations yet. Log workouts and Repvera will record why the next session changes.")
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(history.prefix(10)) { decision in
                                DecisionHistoryRow(decision: decision)
                                    .listRowSeparator(.hidden)
                                    .listRowBackground(Color.clear)
                            }
                        }
                    }
                } else {
                    Section {
                        Text("Confirm a starter plan in setup to see this week’s sessions.")
                            .foregroundStyle(.secondary)
                    }
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
    let workout: PlannedWorkoutDraft
    let isToday: Bool

    var body: some View {
        HStack {
            Text(workout.dayLabel)
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)
                .frame(width: 34, alignment: .leading)
            VStack(alignment: .leading, spacing: 2) {
                Text(workout.title)
                Text(workout.detailLine)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(isToday ? "Today" : "Planned")
                .font(.caption.weight(.semibold))
                .foregroundStyle(isToday ? Color.repveraAccent : .secondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(workout.dayLabel) \(workout.title), \(isToday ? "Today" : "Planned")")
    }
}

#Preview {
    let container = try! RepveraSchema.makeContainer(inMemory: true)
    return PlanScreen()
        .environment(TrainingStore(context: container.mainContext))
        .modelContainer(container)
}
