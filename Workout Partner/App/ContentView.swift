import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(TrainingStore.self) private var store

    var body: some View {
        TabView {
            TodayScreen()
                .tabItem { Label("Today", systemImage: "sparkles") }

            PlanScreen()
                .tabItem { Label("Plan", systemImage: "figure.strengthtraining.traditional") }

            ProgressScreen()
                .tabItem { Label("Progress", systemImage: "chart.line.uptrend.xyaxis") }

            ProfileScreen()
                .tabItem { Label("Profile", systemImage: "person.crop.circle") }
        }
        .tint(.repveraAccent)
        .fullScreenCover(isPresented: Binding(
            get: { !store.hasCompletedOnboarding },
            set: { _ in }
        )) {
            OnboardingView()
                .environment(store)
                .interactiveDismissDisabled()
        }
    }
}

#Preview {
    let container = try! RepveraSchema.makeContainer(inMemory: true)
    return ContentView()
        .environment(TrainingStore(context: container.mainContext))
        .modelContainer(container)
}
