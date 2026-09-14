import SwiftUI
import SwiftData
import WorkoutPartnerCore

struct TodayScreen: View {
    @Environment(TrainingStore.self) private var store
    @State private var showingWorkout = false

    private var todayWeekday: Int {
        Calendar.current.component(.weekday, from: .now)
    }

    private var session: PlannedWorkoutDraft? {
        store.plan?.workout(onWeekday: todayWeekday) ?? store.plan?.nextWorkout(afterWeekday: todayWeekday)
    }

    private var isTrainingDay: Bool {
        store.plan?.workout(onWeekday: todayWeekday) != nil
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                if let session, store.hasCompletedOnboarding {
                    populatedToday(session: session)
                } else {
                    emptyToday
                }
            }
            .navigationTitle("Repvera")
            .sheet(isPresented: $showingWorkout) {
                if let session {
                    WorkoutPlayer(session: session)
                }
            }
        }
    }

    private var emptyToday: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("No plan yet")
                .font(.title.bold())
            Text("Confirm a starter plan in setup. Today stays empty until there is a Training Plan v1 to start.")
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func populatedToday(session: PlannedWorkoutDraft) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 6) {
                Text(Date.now.formatted(.dateTime.weekday(.wide).month(.wide).day()).uppercased())
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(isTrainingDay ? "Ready to train?" : "No session today")
                    .font(.title.bold())
                Text(isTrainingDay
                     ? "This is your confirmed starter plan. Log work so later changes have evidence."
                     : "Review the next workout. The plan stays as written until you log a session.")
                    .foregroundStyle(.secondary)
            }

            ReadinessCard()

            VStack(alignment: .leading, spacing: 12) {
                Text(isTrainingDay ? "TODAY'S SESSION" : "NEXT SESSION")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)

                HStack(alignment: .top, spacing: 14) {
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.title2)
                        .foregroundStyle(.white)
                        .frame(width: 48, height: 48)
                        .background(Color.repveraAccent, in: RoundedRectangle(cornerRadius: 14))
                        .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: 5) {
                        Text(session.title)
                            .font(.headline)
                        Text(session.detailLine)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }

                Button {
                    showingWorkout = true
                } label: {
                    Label(isTrainingDay ? "Start workout" : "Preview workout", systemImage: "play.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.repveraAccent)
                .controlSize(.large)
                .frame(minHeight: 44)
            }
            .padding(18)
            .background(Color.secondary.opacity(0.09), in: RoundedRectangle(cornerRadius: 20))

            if let decision = baselineDecision(for: session) {
                CoachExplanationCard(
                    decision: decision,
                    exerciseName: ExerciseCatalogue.name(id: session.prescriptions.first?.exerciseID ?? ""),
                    previousLoadKilograms: session.prescriptions.first?.loadKilograms
                )
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("THIS WEEK")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
                HStack(spacing: 12) {
                    MetricTile(value: "\(store.completedSessionsThisWeek()) / \(store.plan?.workouts.count ?? 0)", label: "workouts")
                    MetricTile(value: "Plan v\(store.plan?.version ?? 1)", label: "active")
                    MetricTile(value: "Self-report", label: "readiness")
                }
            }
        }
        .padding()
    }

    private func baselineDecision(for session: PlannedWorkoutDraft) -> TrainingDecision? {
        guard let prescription = session.prescriptions.first, let profile = store.profile else { return nil }
        return AdaptiveTrainingEngine().decide(
            profile: profile.trainingProfile,
            context: ExerciseContext(
                prescription: prescription,
                recentPerformances: store.recentPerformances(exerciseID: prescription.exerciseID, prescription: prescription),
                readiness: .defaultOptimistic
            )
        )
    }
}

private struct ReadinessCard: View {
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: "heart.text.clipboard")
                .font(.title2)
                .foregroundStyle(.white)
                .frame(width: 48, height: 48)
                .background(Color.repveraAccent, in: RoundedRectangle(cornerRadius: 14))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 6) {
                Text("Starter readiness")
                    .font(.headline)
                Text("No check-in is stored yet. The plan stays conservative until you log sessions.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Label("Coaching signal, not a medical score", systemImage: "info.circle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(18)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20))
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    let container = try! RepveraSchema.makeContainer(inMemory: true)
    return TodayScreen()
        .environment(TrainingStore(context: container.mainContext))
        .modelContainer(container)
}
