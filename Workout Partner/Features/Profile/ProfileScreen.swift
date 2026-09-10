import SwiftUI

struct ProfileScreen: View {
    var body: some View {
        NavigationStack {
            List {
                Section("TRAINING PROFILE") {
                    LabeledContent("Goal", value: "Build strength")
                    LabeledContent("Experience", value: "Intermediate")
                    LabeledContent("Schedule", value: "4 days per week")
                    LabeledContent("Equipment", value: "Commercial gym")
                }
                Section("DATA") {
                    Label("Health connection", systemImage: "heart")
                    Label("Daily check-in", systemImage: "checkmark.circle")
                    Label("Measurements", systemImage: "ruler")
                }
            }
            .navigationTitle("Profile")
        }
    }
}

#Preview {
    ProfileScreen()
}
