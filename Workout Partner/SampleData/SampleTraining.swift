import Foundation
import WorkoutPartnerCore

enum SampleTraining {
    static let profile = TrainingProfile(goal: .buildStrength, experience: .intermediate)
    static let readiness = ReadinessSnapshot(energy: 8, sleepQuality: 8, stress: 3, soreness: 3)
    static let previousBenchLoadKilograms = 100.0

    static let benchPrescription = ExercisePrescription(
        exerciseID: "barbell_bench_press",
        movementPattern: .horizontalPush,
        sets: 4,
        targetReps: 8,
        loadKilograms: previousBenchLoadKilograms,
        targetRPE: 8
    )

    static let decision: TrainingDecision = {
        let easy = ExercisePerformance(completedSets: 4, lowestCompletedReps: 8, highestRPE: 6)
        let context = ExerciseContext(
            prescription: benchPrescription,
            recentPerformances: [easy, easy],
            readiness: readiness
        )
        return AdaptiveTrainingEngine().decide(profile: profile, context: context)
    }()

    static var week: [SampleSession] {
        let todayWeekday = Calendar.current.component(.weekday, from: .now)
        return baseWeek.map { session in
            var copy = session
            copy.status = status(for: session.weekday, todayWeekday: todayWeekday)
            if copy.status != .complete,
               copy.exercises.contains(where: { $0.name == "Barbell bench press" }),
               decision.action == .increaseLoad {
                copy.changeSummary = "Bench press progressed"
            }
            return copy
        }
    }

    static var todaySession: SampleSession? {
        week.first { $0.status == .today }
    }

    static var featuredSession: SampleSession {
        todaySession ?? week.first { $0.status == .planned } ?? week[0]
    }

    static var completedThisWeek: Int {
        week.filter { $0.status == .complete }.count
    }

    private static func status(for weekday: Int, todayWeekday: Int) -> SessionStatus {
        if weekday < todayWeekday { return .complete }
        if weekday == todayWeekday { return .today }
        return .planned
    }

    private static let baseWeek: [SampleSession] = [
        SampleSession(
            weekday: 2,
            dayLabel: "Mon",
            title: "Upper Strength A",
            durationMinutes: 52,
            focus: "Strength",
            exercises: [
                SampleExercise(name: "Barbell bench press", sets: 4, reps: 8, loadKilograms: 100, targetRPE: 8),
                SampleExercise(name: "Chest-supported row", sets: 4, reps: 8, loadKilograms: 70, targetRPE: 8),
                SampleExercise(name: "Overhead press", sets: 3, reps: 10, loadKilograms: 45, targetRPE: 8),
                SampleExercise(name: "Cable lateral raise", sets: 3, reps: 12, loadKilograms: 10, targetRPE: 8),
                SampleExercise(name: "Triceps pressdown", sets: 3, reps: 12, loadKilograms: 25, targetRPE: 8)
            ]
        ),
        SampleSession(
            weekday: 3,
            dayLabel: "Tue",
            title: "Lower Strength A",
            durationMinutes: 55,
            focus: "Strength",
            exercises: [
                SampleExercise(name: "Back squat", sets: 4, reps: 5, loadKilograms: 120, targetRPE: 8),
                SampleExercise(name: "Romanian deadlift", sets: 3, reps: 8, loadKilograms: 100, targetRPE: 8),
                SampleExercise(name: "Walking lunge", sets: 3, reps: 10, loadKilograms: 20, targetRPE: 8),
                SampleExercise(name: "Leg curl", sets: 3, reps: 12, loadKilograms: 40, targetRPE: 8),
                SampleExercise(name: "Calf raise", sets: 3, reps: 15, loadKilograms: 80, targetRPE: 8)
            ]
        ),
        SampleSession(
            weekday: 5,
            dayLabel: "Thu",
            title: "Upper Hypertrophy",
            durationMinutes: 50,
            focus: "Hypertrophy",
            exercises: [
                SampleExercise(name: "Barbell bench press", sets: 4, reps: 8, loadKilograms: 102.5, targetRPE: 8),
                SampleExercise(name: "Chest-supported row", sets: 4, reps: 10, loadKilograms: 65, targetRPE: 8),
                SampleExercise(name: "Overhead press", sets: 3, reps: 12, loadKilograms: 40, targetRPE: 8),
                SampleExercise(name: "Cable lateral raise", sets: 3, reps: 15, loadKilograms: 8, targetRPE: 8),
                SampleExercise(name: "Face pull", sets: 3, reps: 15, loadKilograms: 20, targetRPE: 8)
            ]
        ),
        SampleSession(
            weekday: 7,
            dayLabel: "Sat",
            title: "Lower Hypertrophy",
            durationMinutes: 50,
            focus: "Hypertrophy",
            exercises: [
                SampleExercise(name: "Front squat", sets: 4, reps: 8, loadKilograms: 80, targetRPE: 8),
                SampleExercise(name: "Hip thrust", sets: 3, reps: 10, loadKilograms: 100, targetRPE: 8),
                SampleExercise(name: "Leg press", sets: 3, reps: 12, loadKilograms: 180, targetRPE: 8),
                SampleExercise(name: "Leg curl", sets: 3, reps: 15, loadKilograms: 35, targetRPE: 8),
                SampleExercise(name: "Calf raise", sets: 3, reps: 15, loadKilograms: 80, targetRPE: 8)
            ]
        )
    ]
}

enum SessionStatus: String {
    case complete = "Complete"
    case today = "Today"
    case planned = "Planned"
}

struct SampleSession: Identifiable {
    var id: String { "\(weekday)-\(title)" }
    let weekday: Int
    let dayLabel: String
    let title: String
    let durationMinutes: Int
    let focus: String
    let exercises: [SampleExercise]
    var status: SessionStatus = .planned
    var changeSummary: String?

    var detailLine: String {
        "\(exercises.count) exercises · \(durationMinutes) min · \(focus)"
    }
}

struct SampleExercise: Identifiable {
    var id: String { name }
    let name: String
    let sets: Int
    let reps: Int
    let loadKilograms: Double?
    let targetRPE: Double

    var prescriptionLine: String {
        if let loadKilograms {
            return "\(sets) × \(reps) at \(loadKilograms.formatted(.number.precision(.fractionLength(0...1)))) kg"
        }
        return "\(sets) × \(reps)"
    }
}
