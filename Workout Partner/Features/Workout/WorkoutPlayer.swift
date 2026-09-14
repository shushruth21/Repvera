import SwiftData
import SwiftUI
import WorkoutPartnerCore

// MARK: - Workout player

/// Runs one planned workout: shows each prescribed exercise and lets the
/// user log every set as it happens. Logging persists immediately through
/// `TrainingStore` so the adaptive engine has real data for the next
/// decision — nothing here is held only in memory.
struct WorkoutPlayer: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(TrainingStore.self) private var store
    let session: PlannedWorkoutDraft
    @State private var sessionID: UUID?

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

                ForEach(Array(session.prescriptions.enumerated()), id: \.element.id) { index, prescription in
                    let name = ExerciseCatalogue.name(id: prescription.exerciseID)
                    Section("\(index + 1) · \(name.uppercased())") {
                        LabeledContent("Prescription", value: prescriptionLine(prescription))
                        LabeledContent("Target effort", value: "RPE \(prescription.targetRPE.formatted(.number.precision(.fractionLength(0))))")
                        if let rest = prescription.restSeconds {
                            LabeledContent("Rest", value: "\(rest)s")
                        }

                        ForEach(1...prescription.sets, id: \.self) { setIndex in
                            if let sessionID {
                                SetLogRow(
                                    prescription: prescription,
                                    setIndex: setIndex,
                                    sessionID: sessionID,
                                    store: store
                                )
                            }
                        }
                    }
                }
            }
            .navigationTitle("Workout")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        if let sessionID {
                            try? store.completeSession(sessionID: sessionID)
                        }
                        dismiss()
                    }
                }
            }
            .task {
                guard sessionID == nil else { return }
                sessionID = store.startSession(for: session)
            }
        }
    }

    private func prescriptionLine(_ prescription: ExercisePrescription) -> String {
        if let load = prescription.loadKilograms {
            return "\(prescription.sets) × \(prescription.targetReps) at \(load.formatted(.number.precision(.fractionLength(0...1)))) kg"
        }
        return "\(prescription.sets) × \(prescription.targetReps)"
    }
}

// MARK: - Set log row

/// One set's input row: reps, optional load, and RPE, pre-filled from the
/// prescription so logging an as-prescribed set only takes one tap.
private struct SetLogRow: View {
    let prescription: ExercisePrescription
    let setIndex: Int
    let sessionID: UUID
    let store: TrainingStore

    @State private var reps: Int
    @State private var loadText: String
    @State private var rpe: Double
    @State private var isLogged = false

    init(prescription: ExercisePrescription, setIndex: Int, sessionID: UUID, store: TrainingStore) {
        self.prescription = prescription
        self.setIndex = setIndex
        self.sessionID = sessionID
        self.store = store
        _reps = State(initialValue: prescription.targetReps)
        _loadText = State(initialValue: prescription.loadKilograms.map {
            $0.formatted(.number.precision(.fractionLength(0...1)))
        } ?? "")
        _rpe = State(initialValue: prescription.targetRPE)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Set \(setIndex)")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                if isLogged {
                    Label("Logged", systemImage: "checkmark.circle.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.green)
                        .accessibilityLabel("Set \(setIndex) logged")
                }
            }

            Stepper("Reps: \(reps)", value: $reps, in: 0...50)

            TextField("Load in kilograms (optional)", text: $loadText)
                .keyboardType(.decimalPad)
                .textFieldStyle(.roundedBorder)

            Stepper(
                "Effort: RPE \(rpe.formatted(.number.precision(.fractionLength(1))))",
                value: $rpe,
                in: 6...10,
                step: 0.5
            )

            Button {
                logSet()
            } label: {
                Text(isLogged ? "Update set" : "Log set")
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(.bordered)
            .tint(.repveraAccent)
        }
        .padding(.vertical, 6)
    }

    private func logSet() {
        try? store.logSet(
            sessionID: sessionID,
            prescription: prescription,
            setIndex: setIndex,
            repsCompleted: reps,
            loadKilograms: Double(loadText),
            rpe: rpe
        )
        isLogged = true
    }
}

#Preview {
    let container = try! RepveraSchema.makeContainer(inMemory: true)
    return WorkoutPlayer(
        session: PlannedWorkoutDraft(
            weekday: 5,
            title: "Upper Strength",
            focus: "Strength",
            durationMinutes: 60,
            prescriptions: [
                ExercisePrescription(
                    exerciseID: "barbell_bench_press",
                    movementPattern: .horizontalPush,
                    sets: 4,
                    targetReps: 6,
                    loadKilograms: 60,
                    targetRPE: 8
                )
            ]
        )
    )
    .environment(TrainingStore(context: container.mainContext))
    .modelContainer(container)
}
