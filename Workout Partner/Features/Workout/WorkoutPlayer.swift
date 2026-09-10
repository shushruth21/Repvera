import SwiftUI

struct WorkoutPlayer: View {
    @Environment(\.dismiss) private var dismiss
    let session: SampleSession
    @State private var loggedExerciseIDs: Set<String> = []

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(session.title)
                            .font(.title2.bold())
                        Text("\(session.durationMinutes) minutes · Rest when needed")
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }

                ForEach(Array(session.exercises.enumerated()), id: \.element.id) { index, exercise in
                    Section("\(index + 1) · \(exercise.name.uppercased())") {
                        LabeledContent("Prescription", value: exercise.prescriptionLine)
                        LabeledContent("Target effort", value: "RPE \(exercise.targetRPE.formatted(.number.precision(.fractionLength(0))))")
                        Button {
                            loggedExerciseIDs.insert(exercise.id)
                        } label: {
                            Text(loggedExerciseIDs.contains(exercise.id) ? "Set 1 logged" : "Log set 1")
                                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                        }
                        .foregroundStyle(loggedExerciseIDs.contains(exercise.id) ? .green : .repveraAccent)
                        .accessibilityLabel("\(exercise.name), \(loggedExerciseIDs.contains(exercise.id) ? "set 1 logged" : "log set 1"), \(exercise.prescriptionLine)")
                    }
                }
            }
            .navigationTitle("Workout")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    WorkoutPlayer(session: SampleTraining.featuredSession)
}
