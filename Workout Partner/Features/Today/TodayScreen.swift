import SwiftUI
import WorkoutPartnerCore

struct TodayScreen: View {
    @State private var showingWorkout = false
    private let session = SampleTraining.featuredSession
    private let isTrainingDay = SampleTraining.todaySession != nil

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(Date.now.formatted(.dateTime.weekday(.wide).month(.wide).day()).uppercased())
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Text(isTrainingDay ? "Ready to train?" : "Recovery day")
                            .font(.title.bold())
                        Text(isTrainingDay
                             ? "Your plan is adapted from your last bench session and today’s check-in."
                             : "No session is scheduled today. Review the next workout and keep the plan as written.")
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
                                if let changeSummary = session.changeSummary {
                                    Label(changeSummary, systemImage: "arrow.up.right")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(.green)
                                }
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

                    CoachExplanationCard(
                        decision: SampleTraining.decision,
                        exerciseName: "Bench press",
                        previousLoadKilograms: SampleTraining.previousBenchLoadKilograms
                    )

                    VStack(alignment: .leading, spacing: 12) {
                        Text("THIS WEEK")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.secondary)
                        HStack(spacing: 12) {
                            MetricTile(value: "\(SampleTraining.completedThisWeek) / \(SampleTraining.week.count)", label: "workouts")
                            MetricTile(value: "Energy 8", label: "check-in")
                            MetricTile(value: "Sleep 8", label: "self-report")
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Repvera")
            .sheet(isPresented: $showingWorkout) {
                WorkoutPlayer(session: session)
            }
        }
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
                Text("Good recovery")
                    .font(.headline)
                Text("Sleep, energy, and soreness support training as planned today.")
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
    TodayScreen()
}
