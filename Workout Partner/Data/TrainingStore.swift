import Foundation
import SwiftData
import WorkoutPartnerCore

@Observable
final class TrainingStore {
    private let context: ModelContext
    private let generator = StarterPlanGenerator()

    private(set) var profile: UserProfileSnapshot?
    private(set) var plan: TrainingPlanDraft?
    private(set) var activeSession: WorkoutSessionLog?

    var hasCompletedOnboarding: Bool {
        profile?.onboardingCompletedAt != nil && plan != nil
    }

    init(context: ModelContext) {
        self.context = context
        // Every mutation below already calls `context.save()` explicitly, so
        // the background autosave timer is disabled to avoid it racing with
        // those manual saves.
        self.context.autosaveEnabled = false
        seedCatalogueIfNeeded()
        refresh()
    }

    func refresh() {
        seedCatalogueIfNeeded()
        let profiles = (try? context.fetch(FetchDescriptor<UserProfileRecord>())) ?? []
        profile = profiles.first?.snapshot
        plan = profiles.first?.plans
            .filter { $0.statusRaw == "active" }
            .sorted { $0.version > $1.version }
            .first?
            .draft
    }

    func completeOnboarding(_ input: PlanGenerationInput, bodyMassKilograms: Double?) throws {
        guard input.isValid else { throw TrainingStoreError.invalidProfile }

        seedCatalogueIfNeeded()
        let draft = generator.generate(input: input)

        let existing = (try? context.fetch(FetchDescriptor<UserProfileRecord>())) ?? []
        for record in existing {
            context.delete(record)
        }

        let profileRecord = UserProfileRecord(
            goal: input.profile.goal,
            experience: input.profile.experience,
            sessionDurationMinutes: input.sessionDurationMinutes,
            availableWeekdays: input.availableWeekdays,
            equipment: input.equipment,
            minimumLoadIncrementKilograms: input.profile.minimumLoadIncrementKilograms,
            bodyMassKilograms: bodyMassKilograms,
            onboardingCompletedAt: .now
        )

        for pattern in input.limitedMovementPatterns.sorted(by: { $0.rawValue < $1.rawValue }) {
            let limitation = TrainingLimitationRecord(movementPattern: pattern)
            limitation.profile = profileRecord
            profileRecord.limitations.append(limitation)
        }

        let planRecord = TrainingPlanRecord(version: draft.version, goal: draft.goal)
        planRecord.profile = profileRecord
        for (index, workout) in draft.workouts.enumerated() {
            let workoutRecord = PlannedWorkoutRecord(
                scheduledWeekday: workout.weekday,
                title: workout.title,
                focus: workout.focus,
                durationMinutes: workout.durationMinutes,
                sortOrder: index
            )
            workoutRecord.plan = planRecord
            for (order, prescription) in workout.prescriptions.enumerated() {
                let prescriptionRecord = ExercisePrescriptionRecord(orderIndex: order, prescription: prescription)
                prescriptionRecord.workout = workoutRecord
                workoutRecord.prescriptions.append(prescriptionRecord)
            }
            planRecord.workouts.append(workoutRecord)
        }
        profileRecord.plans.append(planRecord)

        context.insert(profileRecord)
        try context.save()
        refresh()
    }

    // MARK: - Workout logging

    /// Starts a new in-progress session for the given planned workout and
    /// returns its id. Call `logSet` and `completeSession` against that id.
    @discardableResult
    func startSession(for workout: PlannedWorkoutDraft) -> UUID {
        let record = WorkoutSessionRecord(plannedWorkoutID: workout.id, status: .inProgress, startedAt: .now)
        context.insert(record)
        try? context.save()
        activeSession = record.domainValue
        return record.sessionID
    }

    /// Persists one completed set against an in-progress session. Sets are
    /// append-only — logging the same `setIndex` twice adds a new row rather
    /// than overwriting, preserving an honest history of what happened.
    func logSet(
        sessionID: UUID,
        prescription: ExercisePrescription,
        setIndex: Int,
        repsCompleted: Int,
        loadKilograms: Double?,
        rpe: Double?
    ) throws {
        guard let record = fetchSession(sessionID) else { throw TrainingStoreError.sessionNotFound }
        let setLog = SetLogRecord(
            prescriptionID: prescription.id,
            exerciseID: prescription.exerciseID,
            setIndex: setIndex,
            repsCompleted: repsCompleted,
            loadKilograms: loadKilograms,
            rpe: rpe
        )
        setLog.session = record
        record.setLogs.append(setLog)
        try context.save()
        activeSession = record.domainValue
    }

    /// Marks a session complete. Completed sessions are the only ones
    /// considered by `recentPerformances`, so an abandoned/in-progress
    /// session never influences the coach. Recording ledger entries here
    /// (rather than wherever a decision is merely displayed) is what keeps
    /// the ledger honest: it only ever grows on a deliberate, one-time user
    /// action, never on a view redraw.
    func completeSession(sessionID: UUID) throws {
        guard let record = fetchSession(sessionID) else { throw TrainingStoreError.sessionNotFound }
        record.statusRaw = WorkoutSessionStatus.completed.rawValue
        record.completedAt = .now
        recordDecisions(forCompletedSession: record)
        try context.save()
        activeSession = nil
    }

    // MARK: - Decision ledger

    /// For each exercise with logged sets in this session, asks the engine
    /// what should happen next and inserts one immutable ledger entry. Never
    /// updates or deletes an existing entry — this is the only place new
    /// entries are created.
    private func recordDecisions(forCompletedSession session: WorkoutSessionRecord) {
        guard let profile else { return }
        let engine = AdaptiveTrainingEngine()
        let prescriptionIDs = Set(session.setLogs.map(\.prescriptionID))

        for prescriptionID in prescriptionIDs {
            guard let prescriptionRecord = fetchPrescription(prescriptionID) else { continue }
            let prescription = prescriptionRecord.domainValue
            let sessionSets = session.setLogs
                .filter { $0.prescriptionID == prescriptionID }
                .map(\.domainValue)
            guard let sessionPerformance = ExercisePerformance.summarizing(sessionSets, against: prescription) else { continue }

            let recent = recentPerformances(exerciseID: prescription.exerciseID, prescription: prescription)
            let decision = engine.decide(
                profile: profile.trainingProfile,
                context: ExerciseContext(
                    prescription: prescription,
                    recentPerformances: recent,
                    readiness: .defaultOptimistic
                )
            )

            let averageRPEThisSession = sessionSets.compactMap(\.rpe).isEmpty
                ? 0
                : sessionSets.compactMap(\.rpe).reduce(0, +) / Double(sessionSets.compactMap(\.rpe).count)
            let completionRate = min(Double(sessionPerformance.completedSets) / Double(max(prescription.sets, 1)), 1.0)

            let decisionRecord = TrainingDecisionRecord(
                sessionID: session.sessionID,
                exerciseID: prescription.exerciseID,
                exerciseName: ExerciseCatalogue.name(id: prescription.exerciseID),
                decisionType: .from(decision.action),
                previousWeightKilograms: prescription.loadKilograms,
                newWeightKilograms: decision.prescription?.loadKilograms ?? prescription.loadKilograms,
                previousReps: prescription.targetReps,
                newReps: decision.prescription?.targetReps ?? prescription.targetReps,
                previousSets: prescription.sets,
                newSets: decision.prescription?.sets ?? prescription.sets,
                averageRPE: averageRPEThisSession,
                completionRate: completionRate,
                fatigueScore: min(averageRPEThisSession / 10, 1.0),
                confidence: decision.confidenceScore,
                reasoning: decision.coachExplanation,
                adaptationVersion: 1,
                notes: decision.reasons.map(\.label).joined(separator: ", ")
            )
            context.insert(decisionRecord)
        }
    }

    /// Most recent decision recorded, across all exercises.
    func latestDecision() -> TrainingDecisionLog? {
        decisionHistory().first
    }

    /// Full decision history, newest first.
    func decisionHistory() -> [TrainingDecisionLog] {
        let descriptor = FetchDescriptor<TrainingDecisionRecord>(sortBy: [SortDescriptor(\.recordedAt, order: .reverse)])
        return ((try? context.fetch(descriptor)) ?? []).map(\.domainValue)
    }

    /// Decision history for one exercise, newest first.
    func decisionHistory(for exerciseID: String) -> [TrainingDecisionLog] {
        decisionHistory().filter { $0.exerciseID == exerciseID }
    }

    /// Aggregate counts for decisions recorded since the start of the
    /// current calendar week.
    func weeklyDecisionSummary() -> DecisionSummary {
        let calendar = Calendar.current
        guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: .now)?.start else {
            return DecisionSummary.summarizing([])
        }
        let thisWeek = decisionHistory().filter { $0.recordedAt >= weekStart }
        return DecisionSummary.summarizing(thisWeek)
    }

    // MARK: - Decision analytics

    func numberOfProgressions() -> Int { WorkoutPartnerCore.numberOfProgressions(decisionHistory()) }
    func numberOfDeloads() -> Int { WorkoutPartnerCore.numberOfDeloads(decisionHistory()) }
    func adaptationFrequency() -> Double { WorkoutPartnerCore.adaptationFrequency(decisionHistory()) }
    func averageIncrease() -> Double { WorkoutPartnerCore.averageIncrease(decisionHistory()) }
    func averageRPE() -> Double { WorkoutPartnerCore.averageRPE(decisionHistory()) }

    /// The most recent comparable performances for one exercise, oldest
    /// first, drawn only from completed sessions — the input the adaptive
    /// engine expects.
    func recentPerformances(exerciseID: String, prescription: ExercisePrescription, limit: Int = 3) -> [ExercisePerformance] {
        let descriptor = FetchDescriptor<WorkoutSessionRecord>(
            predicate: #Predicate { $0.statusRaw == "completed" },
            sortBy: [SortDescriptor(\.completedAt)]
        )
        let sessions = (try? context.fetch(descriptor)) ?? []
        let performances = sessions.compactMap { session -> ExercisePerformance? in
            let sets = session.setLogs
                .filter { $0.exerciseID == exerciseID }
                .sorted { $0.setIndex < $1.setIndex }
                .map(\.domainValue)
            return ExercisePerformance.summarizing(sets, against: prescription)
        }
        return Array(performances.suffix(limit))
    }

    /// Number of sessions completed since the start of the current calendar
    /// week, for the "workouts this week" summary tiles.
    func completedSessionsThisWeek() -> Int {
        let calendar = Calendar.current
        guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: .now)?.start else { return 0 }
        let descriptor = FetchDescriptor<WorkoutSessionRecord>(
            predicate: #Predicate { $0.statusRaw == "completed" && $0.startedAt >= weekStart }
        )
        return (try? context.fetchCount(descriptor)) ?? 0
    }

    private func fetchSession(_ sessionID: UUID) -> WorkoutSessionRecord? {
        var descriptor = FetchDescriptor<WorkoutSessionRecord>(predicate: #Predicate { $0.sessionID == sessionID })
        descriptor.fetchLimit = 1
        return (try? context.fetch(descriptor))?.first
    }

    private func fetchPrescription(_ prescriptionID: UUID) -> ExercisePrescriptionRecord? {
        var descriptor = FetchDescriptor<ExercisePrescriptionRecord>(predicate: #Predicate { $0.prescriptionID == prescriptionID })
        descriptor.fetchLimit = 1
        return (try? context.fetch(descriptor))?.first
    }

    private func seedCatalogueIfNeeded() {
        let existing = (try? context.fetch(FetchDescriptor<ExerciseRecord>())) ?? []
        guard existing.isEmpty else { return }

        for definition in ExerciseCatalogue.standard {
            context.insert(ExerciseRecord(definition: definition, catalogueVersion: ExerciseCatalogue.version))
        }
        for alternative in ExerciseCatalogue.alternatives {
            context.insert(ExerciseAlternativeRecord(alternative: alternative, catalogueVersion: ExerciseCatalogue.version))
        }
    }
}

enum TrainingStoreError: LocalizedError {
    case invalidProfile
    case sessionNotFound

    var errorDescription: String? {
        switch self {
        case .invalidProfile:
            "Choose at least one training day and a set of equipment before confirming a plan."
        case .sessionNotFound:
            "This workout session could not be found. Start a new session and try again."
        }
    }
}
