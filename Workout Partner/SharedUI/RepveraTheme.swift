import SwiftUI
import WorkoutPartnerCore

extension Color {
    static let repveraAccent = Color(red: 0.34, green: 0.25, blue: 0.82)
}

extension DecisionReason {
    var label: String {
        switch self {
        case .severePainReported: "pain reported"
        case .equipmentUnavailable: "equipment change"
        case .lowReadiness: "low readiness"
        case .targetMissed: "target missed"
        case .highPerceivedExertion: "high effort"
        case .repeatedEasyCompletion: "ready to progress"
        case .noComparableHistory: "baseline session"
        case .performanceOnTarget: "on target"
        }
    }
}
