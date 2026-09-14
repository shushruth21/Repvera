import Foundation
import SwiftData
import WorkoutPartnerCore

@Model
final class UserProfileRecord {
    var profileID: UUID
    var goalRaw: String
    var experienceRaw: String
    var unitPreference: String
    var sessionDurationMinutes: Int
    var availableWeekdays: [Int]
    var equipmentIDs: [String]
    var minimumLoadIncrementKilograms: Double
    var bodyMassKilograms: Double?
    var onboardingCompletedAt: Date?

    @Relationship(deleteRule: .cascade, inverse: \TrainingLimitationRecord.profile)
    var limitations: [TrainingLimitationRecord]

    @Relationship(deleteRule: .cascade, inverse: \TrainingPlanRecord.profile)
    var plans: [TrainingPlanRecord]

    init(
        profileID: UUID = UUID(),
        goal: TrainingGoal,
        experience: TrainingExperience,
        sessionDurationMinutes: Int,
        availableWeekdays: [Int],
        equipment: Set<EquipmentKind>,
        minimumLoadIncrementKilograms: Double,
        bodyMassKilograms: Double?,
        onboardingCompletedAt: Date?
    ) {
        self.profileID = profileID
        self.goalRaw = goal.rawValue
        self.experienceRaw = experience.rawValue
        self.unitPreference = "kg"
        self.sessionDurationMinutes = sessionDurationMinutes
        self.availableWeekdays = availableWeekdays
        self.equipmentIDs = equipment.map(\.rawValue).sorted()
        self.minimumLoadIncrementKilograms = minimumLoadIncrementKilograms
        self.bodyMassKilograms = bodyMassKilograms
        self.onboardingCompletedAt = onboardingCompletedAt
        self.limitations = []
        self.plans = []
    }

    var snapshot: UserProfileSnapshot {
        UserProfileSnapshot(
            goal: TrainingGoal(rawValue: goalRaw) ?? .generalFitness,
            experience: TrainingExperience(rawValue: experienceRaw) ?? .beginner,
            availableWeekdays: availableWeekdays,
            sessionDurationMinutes: sessionDurationMinutes,
            equipment: Set(equipmentIDs.compactMap(EquipmentKind.init(rawValue:))),
            limitedMovementPatterns: Set(limitations.filter(\.isActive).compactMap { MovementPattern(rawValue: $0.movementPatternRaw) }),
            minimumLoadIncrementKilograms: minimumLoadIncrementKilograms,
            bodyMassKilograms: bodyMassKilograms,
            onboardingCompletedAt: onboardingCompletedAt
        )
    }
}

@Model
final class TrainingLimitationRecord {
    var movementPatternRaw: String
    var severity: Int
    var userNote: String
    var isActive: Bool
    var profile: UserProfileRecord?

    init(movementPattern: MovementPattern, severity: Int = 1, userNote: String = "", isActive: Bool = true) {
        self.movementPatternRaw = movementPattern.rawValue
        self.severity = severity
        self.userNote = userNote
        self.isActive = isActive
    }
}

@Model
final class TrainingPlanRecord {
    var planID: UUID
    var version: Int
    var statusRaw: String
    var goalRaw: String
    var startDate: Date
    var endDate: Date?
    var profile: UserProfileRecord?

    @Relationship(deleteRule: .cascade, inverse: \PlannedWorkoutRecord.plan)
    var workouts: [PlannedWorkoutRecord]

    init(planID: UUID = UUID(), version: Int, goal: TrainingGoal, startDate: Date = .now, statusRaw: String = "active") {
        self.planID = planID
        self.version = version
        self.statusRaw = statusRaw
        self.goalRaw = goal.rawValue
        self.startDate = startDate
        self.workouts = []
    }

    var draft: TrainingPlanDraft {
        TrainingPlanDraft(
            version: version,
            goal: TrainingGoal(rawValue: goalRaw) ?? .generalFitness,
            workouts: workouts.sorted { $0.sortOrder < $1.sortOrder }.map(\.draft)
        )
    }
}

@Model
final class PlannedWorkoutRecord {
    var workoutID: UUID
    var scheduledWeekday: Int
    var title: String
    var focus: String
    var durationMinutes: Int
    var sortOrder: Int
    var plan: TrainingPlanRecord?

    @Relationship(deleteRule: .cascade, inverse: \ExercisePrescriptionRecord.workout)
    var prescriptions: [ExercisePrescriptionRecord]

    init(
        workoutID: UUID = UUID(),
        scheduledWeekday: Int,
        title: String,
        focus: String,
        durationMinutes: Int,
        sortOrder: Int
    ) {
        self.workoutID = workoutID
        self.scheduledWeekday = scheduledWeekday
        self.title = title
        self.focus = focus
        self.durationMinutes = durationMinutes
        self.sortOrder = sortOrder
        self.prescriptions = []
    }

    var draft: PlannedWorkoutDraft {
        PlannedWorkoutDraft(
            id: workoutID,
            weekday: scheduledWeekday,
            title: title,
            focus: focus,
            durationMinutes: durationMinutes,
            prescriptions: prescriptions.sorted { $0.orderIndex < $1.orderIndex }.map(\.domainValue)
        )
    }
}

@Model
final class ExercisePrescriptionRecord {
    var prescriptionID: UUID
    var exerciseID: String
    var movementPatternRaw: String
    var orderIndex: Int
    var sets: Int
    var targetReps: Int
    var loadKilograms: Double?
    var targetRPE: Double
    var restSeconds: Int?
    var workout: PlannedWorkoutRecord?

    init(orderIndex: Int, prescription: ExercisePrescription) {
        self.prescriptionID = prescription.id
        self.exerciseID = prescription.exerciseID
        self.movementPatternRaw = prescription.movementPattern.rawValue
        self.orderIndex = orderIndex
        self.sets = prescription.sets
        self.targetReps = prescription.targetReps
        self.loadKilograms = prescription.loadKilograms
        self.targetRPE = prescription.targetRPE
        self.restSeconds = prescription.restSeconds
    }

    var domainValue: ExercisePrescription {
        ExercisePrescription(
            id: prescriptionID,
            exerciseID: exerciseID,
            movementPattern: MovementPattern(rawValue: movementPatternRaw) ?? .isolation,
            sets: sets,
            targetReps: targetReps,
            loadKilograms: loadKilograms,
            targetRPE: targetRPE,
            restSeconds: restSeconds
        )
    }
}

@Model
final class ExerciseRecord {
    @Attribute(.unique) var catalogueID: String
    var name: String
    var movementPatternRaw: String
    var equipmentIDs: [String]
    var cues: String
    var safetyNotes: String
    var catalogueVersion: Int

    init(definition: ExerciseDefinition, catalogueVersion: Int) {
        self.catalogueID = definition.id
        self.name = definition.name
        self.movementPatternRaw = definition.movementPattern.rawValue
        self.equipmentIDs = definition.requiredEquipment.map(\.rawValue).sorted()
        self.cues = definition.cues
        self.safetyNotes = definition.safetyNotes
        self.catalogueVersion = catalogueVersion
    }
}

@Model
final class ExerciseAlternativeRecord {
    var sourceID: String
    var alternativeID: String
    var catalogueVersion: Int

    init(alternative: ExerciseAlternative, catalogueVersion: Int) {
        self.sourceID = alternative.sourceID
        self.alternativeID = alternative.alternativeID
        self.catalogueVersion = catalogueVersion
    }
}

// MARK: - Workout logging

@Model
final class WorkoutSessionRecord {
    var sessionID: UUID
    var plannedWorkoutID: UUID
    var statusRaw: String
    var startedAt: Date
    var completedAt: Date?

    @Relationship(deleteRule: .cascade, inverse: \SetLogRecord.session)
    var setLogs: [SetLogRecord]

    init(
        sessionID: UUID = UUID(),
        plannedWorkoutID: UUID,
        status: WorkoutSessionStatus = .inProgress,
        startedAt: Date = .now,
        completedAt: Date? = nil
    ) {
        self.sessionID = sessionID
        self.plannedWorkoutID = plannedWorkoutID
        self.statusRaw = status.rawValue
        self.startedAt = startedAt
        self.completedAt = completedAt
        self.setLogs = []
    }

    var domainValue: WorkoutSessionLog {
        WorkoutSessionLog(
            id: sessionID,
            plannedWorkoutID: plannedWorkoutID,
            status: WorkoutSessionStatus(rawValue: statusRaw) ?? .inProgress,
            startedAt: startedAt,
            completedAt: completedAt,
            loggedSets: setLogs.sorted { $0.loggedAt < $1.loggedAt }.map(\.domainValue)
        )
    }
}

@Model
final class SetLogRecord {
    var setLogID: UUID
    var prescriptionID: UUID
    var exerciseID: String
    var setIndex: Int
    var repsCompleted: Int
    var loadKilograms: Double?
    var rpe: Double?
    var loggedAt: Date
    var session: WorkoutSessionRecord?

    init(
        setLogID: UUID = UUID(),
        prescriptionID: UUID,
        exerciseID: String,
        setIndex: Int,
        repsCompleted: Int,
        loadKilograms: Double?,
        rpe: Double?,
        loggedAt: Date = .now
    ) {
        self.setLogID = setLogID
        self.prescriptionID = prescriptionID
        self.exerciseID = exerciseID
        self.setIndex = setIndex
        self.repsCompleted = repsCompleted
        self.loadKilograms = loadKilograms
        self.rpe = rpe
        self.loggedAt = loggedAt
    }

    var domainValue: LoggedSet {
        LoggedSet(
            id: setLogID,
            prescriptionID: prescriptionID,
            exerciseID: exerciseID,
            setIndex: setIndex,
            repsCompleted: repsCompleted,
            loadKilograms: loadKilograms,
            rpe: rpe,
            loggedAt: loggedAt
        )
    }
}

// MARK: - Decision ledger

/// One immutable entry recording why the adaptive engine made a decision
/// about an exercise. Nothing in `TrainingStore` ever updates or deletes
/// these — only inserts — so this is Repvera's permanent, append-only audit
/// trail. No `@Relationship` to `WorkoutSessionRecord`: a loose `sessionID`
/// reference (same pattern as `WorkoutSessionRecord.plannedWorkoutID`) so the
/// ledger can never be silently cascade-deleted.
@Model
final class TrainingDecisionRecord {
    var decisionID: UUID
    var sessionID: UUID
    var exerciseID: String
    var exerciseName: String
    var decisionTypeRaw: String
    var previousWeightKilograms: Double?
    var newWeightKilograms: Double?
    var previousReps: Int
    var newReps: Int
    var previousSets: Int
    var newSets: Int
    var averageRPE: Double
    var completionRate: Double
    var fatigueScore: Double
    var confidence: Double
    var reasoning: String
    var adaptationVersion: Int
    var notes: String
    var recordedAt: Date

    init(
        decisionID: UUID = UUID(),
        sessionID: UUID,
        exerciseID: String,
        exerciseName: String,
        decisionType: TrainingDecisionType,
        previousWeightKilograms: Double?,
        newWeightKilograms: Double?,
        previousReps: Int,
        newReps: Int,
        previousSets: Int,
        newSets: Int,
        averageRPE: Double,
        completionRate: Double,
        fatigueScore: Double,
        confidence: Double,
        reasoning: String,
        adaptationVersion: Int,
        notes: String,
        recordedAt: Date = .now
    ) {
        self.decisionID = decisionID
        self.sessionID = sessionID
        self.exerciseID = exerciseID
        self.exerciseName = exerciseName
        self.decisionTypeRaw = decisionType.rawValue
        self.previousWeightKilograms = previousWeightKilograms
        self.newWeightKilograms = newWeightKilograms
        self.previousReps = previousReps
        self.newReps = newReps
        self.previousSets = previousSets
        self.newSets = newSets
        self.averageRPE = averageRPE
        self.completionRate = completionRate
        self.fatigueScore = fatigueScore
        self.confidence = confidence
        self.reasoning = reasoning
        self.adaptationVersion = adaptationVersion
        self.notes = notes
        self.recordedAt = recordedAt
    }

    var domainValue: TrainingDecisionLog {
        TrainingDecisionLog(
            id: decisionID,
            sessionID: sessionID,
            exerciseID: exerciseID,
            exerciseName: exerciseName,
            decisionType: TrainingDecisionType(rawValue: decisionTypeRaw) ?? .custom,
            previousWeightKilograms: previousWeightKilograms,
            newWeightKilograms: newWeightKilograms,
            previousReps: previousReps,
            newReps: newReps,
            previousSets: previousSets,
            newSets: newSets,
            averageRPE: averageRPE,
            completionRate: completionRate,
            fatigueScore: fatigueScore,
            confidence: confidence,
            reasoning: reasoning,
            adaptationVersion: adaptationVersion,
            notes: notes,
            recordedAt: recordedAt
        )
    }
}
