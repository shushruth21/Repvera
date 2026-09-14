import Foundation
import SwiftData

enum RepveraSchema {
    static func makeContainer(inMemory: Bool = false) throws -> ModelContainer {
        let schema = Schema([
            UserProfileRecord.self,
            TrainingLimitationRecord.self,
            TrainingPlanRecord.self,
            PlannedWorkoutRecord.self,
            ExercisePrescriptionRecord.self,
            ExerciseRecord.self,
            ExerciseAlternativeRecord.self,
            WorkoutSessionRecord.self,
            SetLogRecord.self,
            TrainingDecisionRecord.self
        ])
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: inMemory,
            cloudKitDatabase: .none
        )
        return try ModelContainer(for: schema, configurations: [configuration])
    }
}
