import Foundation

public struct PlanGenerationInput: Sendable, Equatable {
    public let profile: TrainingProfile
    public let availableWeekdays: [Int]
    public let sessionDurationMinutes: Int
    public let equipment: Set<EquipmentKind>
    public let limitedMovementPatterns: Set<MovementPattern>

    public init(
        profile: TrainingProfile,
        availableWeekdays: [Int],
        sessionDurationMinutes: Int,
        equipment: Set<EquipmentKind>,
        limitedMovementPatterns: Set<MovementPattern> = []
    ) {
        self.profile = profile
        self.availableWeekdays = Array(Set(availableWeekdays)).sorted()
        self.sessionDurationMinutes = sessionDurationMinutes
        self.equipment = equipment
        self.limitedMovementPatterns = limitedMovementPatterns
    }

    public var isValid: Bool {
        !availableWeekdays.isEmpty
            && (30...90).contains(sessionDurationMinutes)
            && !equipment.isEmpty
            && availableWeekdays.allSatisfy { (1...7).contains($0) }
    }
}

public struct PlannedWorkoutDraft: Sendable, Equatable, Identifiable {
    public let id: UUID
    public let weekday: Int
    public let title: String
    public let focus: String
    public let durationMinutes: Int
    public let prescriptions: [ExercisePrescription]

    public init(
        id: UUID = UUID(),
        weekday: Int,
        title: String,
        focus: String,
        durationMinutes: Int,
        prescriptions: [ExercisePrescription]
    ) {
        self.id = id
        self.weekday = weekday
        self.title = title
        self.focus = focus
        self.durationMinutes = durationMinutes
        self.prescriptions = prescriptions
    }

    public var dayLabel: String {
        Calendar.current.shortWeekdaySymbols[safe: weekday - 1] ?? "Day"
    }

    public var detailLine: String {
        "\(prescriptions.count) exercises · \(durationMinutes) min · \(focus)"
    }
}

public struct TrainingPlanDraft: Sendable, Equatable {
    public let version: Int
    public let goal: TrainingGoal
    public let workouts: [PlannedWorkoutDraft]

    public init(version: Int, goal: TrainingGoal, workouts: [PlannedWorkoutDraft]) {
        self.version = version
        self.goal = goal
        self.workouts = workouts
    }

    public func workout(onWeekday weekday: Int) -> PlannedWorkoutDraft? {
        workouts.first { $0.weekday == weekday }
    }

    public func nextWorkout(afterWeekday weekday: Int) -> PlannedWorkoutDraft? {
        workouts.first { $0.weekday > weekday } ?? workouts.first
    }
}

public struct UserProfileSnapshot: Sendable, Equatable {
    public let goal: TrainingGoal
    public let experience: TrainingExperience
    public let availableWeekdays: [Int]
    public let sessionDurationMinutes: Int
    public let equipment: Set<EquipmentKind>
    public let limitedMovementPatterns: Set<MovementPattern>
    public let minimumLoadIncrementKilograms: Double
    public let bodyMassKilograms: Double?
    public let onboardingCompletedAt: Date?

    public init(
        goal: TrainingGoal,
        experience: TrainingExperience,
        availableWeekdays: [Int],
        sessionDurationMinutes: Int,
        equipment: Set<EquipmentKind>,
        limitedMovementPatterns: Set<MovementPattern>,
        minimumLoadIncrementKilograms: Double,
        bodyMassKilograms: Double?,
        onboardingCompletedAt: Date?
    ) {
        self.goal = goal
        self.experience = experience
        self.availableWeekdays = availableWeekdays
        self.sessionDurationMinutes = sessionDurationMinutes
        self.equipment = equipment
        self.limitedMovementPatterns = limitedMovementPatterns
        self.minimumLoadIncrementKilograms = minimumLoadIncrementKilograms
        self.bodyMassKilograms = bodyMassKilograms
        self.onboardingCompletedAt = onboardingCompletedAt
    }

    public var trainingProfile: TrainingProfile {
        TrainingProfile(
            goal: goal,
            experience: experience,
            minimumLoadIncrementKilograms: minimumLoadIncrementKilograms
        )
    }

    public var equipmentLabel: String {
        if equipment == EquipmentKind.commercialGym { return EquipmentPreset.commercialGym.label }
        if equipment == EquipmentKind.homeGym { return EquipmentPreset.homeGym.label }
        if equipment == EquipmentKind.dumbbellsOnly { return EquipmentPreset.dumbbells.label }
        if equipment == EquipmentKind.bodyweightOnly { return EquipmentPreset.bodyweight.label }
        return "\(equipment.count) equipment types"
    }

    public var scheduleLabel: String {
        "\(availableWeekdays.count) days per week"
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
