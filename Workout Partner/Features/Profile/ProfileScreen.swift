import SwiftUI
import SwiftData
import WorkoutPartnerCore

struct ProfileScreen: View {
    @Environment(TrainingStore.self) private var store

    var body: some View {
        NavigationStack {
            List {
                if let profile = store.profile, store.hasCompletedOnboarding {
                    Section("TRAINING PROFILE") {
                        LabeledContent("Goal", value: profile.goal.label)
                        LabeledContent("Experience", value: profile.experience.label)
                        LabeledContent("Schedule", value: profile.scheduleLabel)
                        LabeledContent("Equipment", value: profile.equipmentLabel)
                        if !profile.limitedMovementPatterns.isEmpty {
                            LabeledContent(
                                "Limitations",
                                value: profile.limitedMovementPatterns.map(\.label).joined(separator: ", ")
                            )
                        }
                        if let mass = profile.bodyMassKilograms {
                            LabeledContent("Body mass", value: "\(mass.formatted(.number.precision(.fractionLength(0...1)))) kg")
                        }
                    }
                } else {
                    Section {
                        Text("Finish setup to store a training profile on this device.")
                            .foregroundStyle(.secondary)
                    }
                }

                Section("DATA") {
                    Label("Health connection", systemImage: "heart")
                    Text("Optional and later. The current plan does not need Apple Health.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Label("Daily check-in", systemImage: "checkmark.circle")
                    Label("Measurements", systemImage: "ruler")
                }
            }
            .navigationTitle("Profile")
        }
    }
}

#Preview {
    let container = try! RepveraSchema.makeContainer(inMemory: true)
    return ProfileScreen()
        .environment(TrainingStore(context: container.mainContext))
        .modelContainer(container)
}
