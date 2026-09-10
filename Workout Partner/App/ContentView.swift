import SwiftUI

struct ContentView: View {
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
    }
}

#Preview {
    ContentView()
}
