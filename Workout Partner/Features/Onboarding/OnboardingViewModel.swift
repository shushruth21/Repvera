import SwiftUI
import WorkoutPartnerCore

@Observable
final class OnboardingViewModel {
    enum Step: Int, CaseIterable {
        case goal
        case schedule
        case equipment
        case baseline
        case health
        case review
    }

    var step: Step = .goal
    var goal: TrainingGoal = .buildStrength
    var experience: TrainingExperience = .intermediate
    var selectedWeekdays: Set<Int> = [2, 3, 5, 7]
    var sessionDurationMinutes = 60
    var equipmentPreset: EquipmentPreset = .commercialGym
    var limitedPatterns: Set<MovementPattern> = []
    var bodyMassText = ""
    var generatedPlan: TrainingPlanDraft?
    var errorMessage: String?

    var canAdvance: Bool {
        switch step {
        case .schedule: !selectedWeekdays.isEmpty
        case .review: generatedPlan?.workouts.isEmpty == false
        default: true
        }
    }

    var input: PlanGenerationInput {
        PlanGenerationInput(
            profile: TrainingProfile(goal: goal, experience: experience),
            availableWeekdays: Array(selectedWeekdays),
            sessionDurationMinutes: sessionDurationMinutes,
            equipment: equipmentPreset.equipment,
            limitedMovementPatterns: limitedPatterns
        )
    }

    var bodyMassKilograms: Double? {
        let trimmed = bodyMassText.replacingOccurrences(of: ",", with: ".")
        guard let value = Double(trimmed), value > 0 else { return nil }
        return value
    }

    func advance() {
        if step == .health {
            generatedPlan = StarterPlanGenerator().generate(input: input)
        }
        if let next = Step(rawValue: step.rawValue + 1) {
            step = next
        }
    }

    func back() {
        if let previous = Step(rawValue: step.rawValue - 1) {
            step = previous
        }
    }

    func confirm(using store: TrainingStore) -> Bool {
        do {
            try store.completeOnboarding(input, bodyMassKilograms: bodyMassKilograms)
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}
