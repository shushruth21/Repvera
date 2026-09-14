import SwiftData
import Testing
import WorkoutPartnerCore
@testable import Repvera

struct OnboardingPersistenceTests {
    @MainActor
    @Test func completingOnboardingPersistsPlanVersionOne() throws {
        let container = try RepveraSchema.makeContainer(inMemory: true)
        let store = TrainingStore(context: container.mainContext)
        let input = PlanGenerationInput(
            profile: TrainingProfile(goal: .buildStrength, experience: .intermediate),
            availableWeekdays: [2, 4, 6],
            sessionDurationMinutes: 45,
            equipment: EquipmentKind.homeGym
        )

        try store.completeOnboarding(input, bodyMassKilograms: 82)

        #expect(store.hasCompletedOnboarding)
        #expect(store.plan?.version == 1)
        #expect(store.plan?.workouts.count == 3)
        #expect(store.profile?.goal == .buildStrength)
        #expect(store.profile?.bodyMassKilograms == 82)
        #expect(store.plan?.workouts.allSatisfy { !$0.prescriptions.isEmpty } == true)
    }
}
