import SwiftUI

struct ProgressScreen: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Your progress is built from completed sessions—not promises.")
                        .font(.title3.weight(.semibold))

                    HStack(spacing: 12) {
                        MetricTile(value: "+2.5 kg", label: "bench trend")
                        MetricTile(value: "\(SampleTraining.completedThisWeek) / \(SampleTraining.week.count)", label: "this week")
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("NEXT WEEKLY REVIEW")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.secondary)
                        Text("Complete the remaining sessions this week, then Repvera will review strength, volume, recovery, and adherence.")
                            .foregroundStyle(.secondary)
                    }
                    .padding(18)
                    .background(Color.secondary.opacity(0.09), in: RoundedRectangle(cornerRadius: 20))
                }
                .padding()
            }
            .navigationTitle("Progress")
        }
    }
}

#Preview {
    ProgressScreen()
}
