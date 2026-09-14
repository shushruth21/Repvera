import SwiftData
import SwiftUI

@main
struct RepveraApp: App {
    private let container: ModelContainer

    init() {
        do {
            container = try RepveraSchema.makeContainer()
        } catch {
            fatalError("Could not create the local Repvera store: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            TrainingRootView()
        }
        .modelContainer(container)
    }
}

private struct TrainingRootView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var store: TrainingStore?

    var body: some View {
        Group {
            if let store {
                ContentView()
                    .environment(store)
            } else {
                ProgressView("Loading plan")
                    .task {
                        store = TrainingStore(context: modelContext)
                    }
            }
        }
    }
}
