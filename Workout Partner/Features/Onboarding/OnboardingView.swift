import SwiftUI
import WorkoutPartnerCore

struct OnboardingView: View {
    @Environment(TrainingStore.self) private var store
    @State private var model = OnboardingViewModel()

    var body: some View {
        @Bindable var model = model
        NavigationStack {
            VStack(spacing: 0) {
                ProgressView(value: Double(model.step.rawValue + 1), total: Double(OnboardingViewModel.Step.allCases.count))
                    .tint(.repveraAccent)
                    .padding(.horizontal)
                    .padding(.top, 8)

                Group {
                    switch model.step {
                    case .goal: goalStep
                    case .schedule: scheduleStep
                    case .equipment: equipmentStep
                    case .baseline: baselineStep
                    case .health: healthStep
                    case .review: reviewStep
                    }
                }
                .animation(.easeInOut, value: model.step)

                controls
                    .padding()
            }
            .background(Color(.systemBackground))
            .navigationTitle("Set up Repvera")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if model.step != .goal {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Back") { model.back() }
                    }
                }
            }
            .alert("Could not save plan", isPresented: Binding(
                get: { model.errorMessage != nil },
                set: { if !$0 { model.errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) { model.errorMessage = nil }
            } message: {
                Text(model.errorMessage ?? "")
            }
        }
    }

    private var controls: some View {
        Button {
            if model.step == .review {
                _ = model.confirm(using: store)
            } else {
                model.advance()
            }
        } label: {
            Text(model.step == .review ? "Confirm plan" : "Continue")
                .frame(maxWidth: .infinity, minHeight: 44)
        }
        .buttonStyle(.borderedProminent)
        .tint(.repveraAccent)
        .disabled(!model.canAdvance)
        .accessibilityHint(model.step == .review ? "Saves your starter plan on this device" : "Goes to the next setup step")
    }

    private var goalStep: some View {
        OnboardingStepLayout(
            title: "What should this block train toward?",
            subtitle: "Repvera uses this to choose a starter split. You can change it later."
        ) {
            Picker("Goal", selection: $model.goal) {
                ForEach(TrainingGoal.allCases) { goal in
                    Text(goal.label).tag(goal)
                }
            }
            .pickerStyle(.inline)

            Picker("Experience", selection: $model.experience) {
                ForEach(TrainingExperience.allCases) { experience in
                    Text(experience.label).tag(experience)
                }
            }
            .pickerStyle(.inline)
        }
    }

    private var scheduleStep: some View {
        OnboardingStepLayout(
            title: "When can you train?",
            subtitle: "Pick the days you actually have. Session length caps how many exercises appear."
        ) {
            WeekdayPicker(selection: $model.selectedWeekdays)
            Picker("Session length", selection: $model.sessionDurationMinutes) {
                Text("30 min").tag(30)
                Text("45 min").tag(45)
                Text("60 min").tag(60)
                Text("75 min").tag(75)
            }
            .pickerStyle(.segmented)
            .accessibilityLabel("Session length")
        }
    }

    private var equipmentStep: some View {
        OnboardingStepLayout(
            title: "What can you load?",
            subtitle: "The starter plan only uses this equipment. Avoid a pattern if you need it left out."
        ) {
            Picker("Equipment", selection: $model.equipmentPreset) {
                ForEach(EquipmentPreset.allCases) { preset in
                    Text(preset.label).tag(preset)
                }
            }
            .pickerStyle(.inline)

            Text("Leave out for now")
                .font(.headline)
            ForEach([MovementPattern.squat, .hinge, .verticalPush, .singleLeg], id: \.self) { pattern in
                Toggle(pattern.label, isOn: Binding(
                    get: { model.limitedPatterns.contains(pattern) },
                    set: { isOn in
                        if isOn { model.limitedPatterns.insert(pattern) }
                        else { model.limitedPatterns.remove(pattern) }
                    }
                ))
            }
        }
    }

    private var baselineStep: some View {
        OnboardingStepLayout(
            title: "Optional starting weight",
            subtitle: "Skip this if you would rather not store it. It is not required for a plan."
        ) {
            TextField("Body mass in kilograms", text: $model.bodyMassText)
                .keyboardType(.decimalPad)
                .textFieldStyle(.roundedBorder)
                .accessibilityLabel("Body mass in kilograms, optional")
        }
    }

    private var healthStep: some View {
        OnboardingStepLayout(
            title: "Apple Health can wait",
            subtitle: "Your plan works from what you log in the app. Connect Health later from Profile if you want optional sleep and activity context."
        ) {
            Label("No permission sheet during setup", systemImage: "checkmark.shield")
            Label("Denied or limited access will never break the coach", systemImage: "heart")
        }
    }

    private var reviewStep: some View {
        OnboardingStepLayout(
            title: "Starter plan v1",
            subtitle: "This is a conservative first block, not an AI-written programme. Confirm it to start."
        ) {
            if let plan = model.generatedPlan {
                ForEach(plan.workouts) { workout in
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(workout.dayLabel) · \(workout.title)")
                            .font(.headline)
                        Text(workout.detailLine)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(workout.prescriptions.map { ExerciseCatalogue.name(id: $0.exerciseID) }.joined(separator: " · "))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 4)
                    .accessibilityElement(children: .combine)
                }
            }
        }
    }
}

private struct OnboardingStepLayout<Content: View>: View {
    let title: String
    let subtitle: String
    @ViewBuilder var content: Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(title)
                    .font(.title2.bold())
                Text(subtitle)
                    .foregroundStyle(.secondary)
                content
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct WeekdayPicker: View {
    @Binding var selection: Set<Int>

    private let days: [(Int, String)] = [
        (2, "Mon"), (3, "Tue"), (4, "Wed"), (5, "Thu"), (6, "Fri"), (7, "Sat"), (1, "Sun")
    ]

    var body: some View {
        HStack(spacing: 8) {
            ForEach(days, id: \.0) { weekday, label in
                let selected = selection.contains(weekday)
                Button {
                    if selected { selection.remove(weekday) }
                    else { selection.insert(weekday) }
                } label: {
                    Text(label)
                        .font(.caption.weight(.semibold))
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(selected ? Color.repveraAccent : Color.secondary.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
                        .foregroundStyle(selected ? .white : .primary)
                }
                .accessibilityLabel(label)
                .accessibilityAddTraits(selected ? .isSelected : [])
                .buttonStyle(.plain)
            }
        }
    }
}
