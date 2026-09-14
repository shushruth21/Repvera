import Foundation

public struct ExerciseDefinition: Sendable, Codable, Equatable, Identifiable {
    public let id: String
    public let name: String
    public let movementPattern: MovementPattern
    public let requiredEquipment: Set<EquipmentKind>
    public let cues: String
    public let safetyNotes: String
    public let beginnerLoadKilograms: Double?
    public let intermediateLoadKilograms: Double?
    public let advancedLoadKilograms: Double?

    public init(
        id: String,
        name: String,
        movementPattern: MovementPattern,
        requiredEquipment: Set<EquipmentKind>,
        cues: String,
        safetyNotes: String,
        beginnerLoadKilograms: Double? = nil,
        intermediateLoadKilograms: Double? = nil,
        advancedLoadKilograms: Double? = nil
    ) {
        self.id = id
        self.name = name
        self.movementPattern = movementPattern
        self.requiredEquipment = requiredEquipment
        self.cues = cues
        self.safetyNotes = safetyNotes
        self.beginnerLoadKilograms = beginnerLoadKilograms
        self.intermediateLoadKilograms = intermediateLoadKilograms
        self.advancedLoadKilograms = advancedLoadKilograms
    }

    public func load(for experience: TrainingExperience) -> Double? {
        switch experience {
        case .beginner: beginnerLoadKilograms
        case .intermediate: intermediateLoadKilograms
        case .advanced: advancedLoadKilograms
        }
    }
}

public struct ExerciseAlternative: Sendable, Codable, Equatable {
    public let sourceID: String
    public let alternativeID: String

    public init(sourceID: String, alternativeID: String) {
        self.sourceID = sourceID
        self.alternativeID = alternativeID
    }
}

public enum ExerciseCatalogue {
    public static let version = 1

    public static func definition(id: String) -> ExerciseDefinition? {
        lookup[id]
    }

    public static func name(id: String) -> String {
        lookup[id]?.name ?? id.replacingOccurrences(of: "_", with: " ").capitalized
    }

    public static let alternatives: [ExerciseAlternative] = [
        .init(sourceID: "barbell_bench_press", alternativeID: "dumbbell_bench_press"),
        .init(sourceID: "barbell_bench_press", alternativeID: "machine_chest_press"),
        .init(sourceID: "barbell_bench_press", alternativeID: "push_up"),
        .init(sourceID: "back_squat", alternativeID: "goblet_squat"),
        .init(sourceID: "back_squat", alternativeID: "leg_press"),
        .init(sourceID: "back_squat", alternativeID: "bodyweight_squat"),
        .init(sourceID: "barbell_row", alternativeID: "dumbbell_row"),
        .init(sourceID: "barbell_row", alternativeID: "seated_cable_row"),
        .init(sourceID: "overhead_press", alternativeID: "dumbbell_shoulder_press"),
        .init(sourceID: "pull_up", alternativeID: "lat_pulldown"),
        .init(sourceID: "romanian_deadlift", alternativeID: "dumbbell_rdl"),
        .init(sourceID: "romanian_deadlift", alternativeID: "kettlebell_swing")
    ]

    public static let standard: [ExerciseDefinition] = [
        exercise("barbell_bench_press", "Barbell bench press", .horizontalPush, [.barbell, .bench], "Lower with control; press without bouncing.", "Keep the bar path over the chest.", 40, 60, 80),
        exercise("dumbbell_bench_press", "Dumbbell bench press", .horizontalPush, [.dumbbell, .bench], "Lower until elbows are just below the bench.", "Do not drop the bells at the bottom.", 16, 24, 32),
        exercise("machine_chest_press", "Machine chest press", .horizontalPush, [.machine], "Press until elbows are nearly straight.", "Stay in a pain-free range.", 30, 45, 60),
        exercise("push_up", "Push-up", .horizontalPush, [.bodyweight], "Body in one line; chest to the floor.", "Elevate the hands if the floor version breaks down."),
        exercise("incline_dumbbell_press", "Incline dumbbell press", .horizontalPush, [.dumbbell, .bench], "Press up and slightly together.", "Keep the bench at a moderate incline.", 12, 20, 28),
        exercise("cable_fly", "Cable fly", .isolation, [.cable], "Hands meet in front of the chest with a slight elbow bend.", "Do not stretch into shoulder pain.", 8, 12, 16),
        exercise("overhead_press", "Overhead press", .verticalPush, [.barbell], "Press the bar over mid-foot.", "Skip if overhead range is painful.", 30, 40, 50),
        exercise("dumbbell_shoulder_press", "Dumbbell shoulder press", .verticalPush, [.dumbbell], "Press without shrugging the traps.", "Stop short of pain at the top.", 12, 18, 24),
        exercise("pike_push_up", "Pike push-up", .verticalPush, [.bodyweight], "Hips high; lower the head between the hands.", "Use a box if the floor version is too hard."),
        exercise("dumbbell_lateral_raise", "Dumbbell lateral raise", .isolation, [.dumbbell], "Lead with the elbows to shoulder height.", "Keep the weight light enough to control.", 4, 6, 8),
        exercise("cable_lateral_raise", "Cable lateral raise", .isolation, [.cable], "Raise to just below shoulder height.", "Brace the torso; do not swing.", 4, 6, 8),
        exercise("triceps_pressdown", "Triceps pressdown", .isolation, [.cable], "Elbows stay by the sides.", "Do not let the elbows flare wide.", 15, 22, 30),
        exercise("overhead_triceps_extension", "Overhead triceps extension", .isolation, [.dumbbell], "Keep elbows pointing up.", "Reduce range if the shoulders complain.", 8, 12, 16),
        exercise("dip", "Dip", .verticalPush, [.bodyweight], "Lean slightly forward; lower under control.", "Stop if the front of the shoulder hurts."),
        exercise("barbell_row", "Barbell row", .horizontalPull, [.barbell], "Pull to the lower ribs; torso stays still.", "Do not yank with the lower back.", 40, 55, 70),
        exercise("chest_supported_row", "Chest-supported row", .horizontalPull, [.dumbbell, .bench], "Squeeze the shoulder blades, then lower slowly.", "Let the chest stay on the pad.", 16, 22, 28),
        exercise("dumbbell_row", "Dumbbell row", .horizontalPull, [.dumbbell], "Pull the bell to the hip.", "Do not rotate the torso to cheat.", 16, 24, 32),
        exercise("seated_cable_row", "Seated cable row", .horizontalPull, [.cable], "Sit tall and pull to the ribs.", "Do not round the lower back.", 25, 40, 50),
        exercise("machine_row", "Machine row", .horizontalPull, [.machine], "Pull with the elbows, not the wrists.", "Use a range that stays comfortable.", 30, 45, 55),
        exercise("lat_pulldown", "Lat pulldown", .verticalPull, [.cable], "Pull the bar to the upper chest.", "Avoid yanking the neck forward.", 30, 40, 50),
        exercise("pull_up", "Pull-up", .verticalPull, [.pullUpBar], "Chest to the bar; lower to a hang.", "Use a band or machine if needed."),
        exercise("face_pull", "Face pull", .isolation, [.cable], "Pull toward the face with elbows high.", "Keep the ribs down.", 10, 15, 20),
        exercise("rear_delt_fly", "Rear delt fly", .isolation, [.dumbbell], "Sweep the arms out without shrugging.", "Use a light load.", 4, 6, 8),
        exercise("barbell_curl", "Barbell curl", .isolation, [.barbell], "Elbows stay by the sides.", "Do not swing the torso.", 20, 30, 40),
        exercise("dumbbell_curl", "Dumbbell curl", .isolation, [.dumbbell], "Supinate as the bells rise.", "Control the lowering.", 8, 12, 16),
        exercise("back_squat", "Back squat", .squat, [.barbell], "Sit between the hips; knees track over the toes.", "Stay in a pain-free depth.", 50, 70, 90),
        exercise("front_squat", "Front squat", .squat, [.barbell], "Elbows high; torso stays tall.", "Reduce load if the wrists or elbows limit you.", 40, 55, 70),
        exercise("goblet_squat", "Goblet squat", .squat, [.dumbbell], "Hold the bell at the chest and sit between the hips.", "Heels stay down.", 12, 20, 28),
        exercise("bodyweight_squat", "Bodyweight squat", .squat, [.bodyweight], "Sit back and down with control.", "Use a box if balance is limited."),
        exercise("leg_press", "Leg press", .squat, [.machine], "Press through the mid-foot; do not lock out harshly.", "Do not let the lower back round.", 60, 90, 120),
        exercise("romanian_deadlift", "Romanian deadlift", .hinge, [.barbell], "Push the hips back; bar stays close.", "Stop if the lower back rounds.", 50, 70, 90),
        exercise("dumbbell_rdl", "Dumbbell Romanian deadlift", .hinge, [.dumbbell], "Hinge until the hamstrings load, then stand.", "Keep a long spine.", 16, 24, 32),
        exercise("hip_thrust", "Hip thrust", .hinge, [.barbell, .bench], "Drive through the heels; pause at the top.", "Do not hyperextend the lower back.", 40, 60, 80),
        exercise("glute_bridge", "Glute bridge", .hinge, [.bodyweight], "Squeeze the glutes at the top.", "Keep ribs down."),
        exercise("kettlebell_swing", "Kettlebell swing", .hinge, [.kettlebell], "Hinge, then snap the hips; arms stay loose.", "This is not a squat.", 12, 16, 24),
        exercise("trap_bar_deadlift", "Trap-bar deadlift", .hinge, [.trapBar], "Push the floor away; stand tall.", "Keep the bar path close.", 60, 80, 100),
        exercise("walking_lunge", "Walking lunge", .singleLeg, [.dumbbell], "Long enough stride to feel the back-leg hip stretch.", "Knee tracks over the toes.", 8, 12, 16),
        exercise("bulgarian_split_squat", "Bulgarian split squat", .singleLeg, [.dumbbell], "Most of the load stays on the front leg.", "Use a shorter range if the hip flexor cramps.", 8, 12, 16),
        exercise("step_up", "Step-up", .singleLeg, [.dumbbell], "Drive through the whole front foot.", "Choose a box you can control.", 8, 12, 16),
        exercise("leg_curl", "Leg curl", .isolation, [.machine], "Curl without lifting the hips.", "Use a smooth tempo.", 20, 30, 40),
        exercise("leg_extension", "Leg extension", .isolation, [.machine], "Extend without snapping the knees.", "Stay in a comfortable range.", 20, 30, 40),
        exercise("calf_raise", "Calf raise", .isolation, [.machine], "Pause at the top; lower through a full stretch.", "Hold the machine lightly for balance.", 40, 60, 80),
        exercise("bodyweight_calf_raise", "Bodyweight calf raise", .isolation, [.bodyweight], "Pause at the top of each rep.", "Use a step if you have one."),
        exercise("farmer_carry", "Farmer carry", .carry, [.dumbbell], "Walk tall; ribs stacked over the pelvis.", "Choose a load you can carry without leaning.", 16, 24, 32),
        exercise("plank", "Plank", .isolation, [.bodyweight], "Brace as if preparing for a tap.", "Stop if the lower back sags."),
        exercise("hamstring_walkout", "Hamstring walkout", .hinge, [.bodyweight], "From a bridge, take small steps out and back.", "Keep the hips from dropping.")
    ]

    private static let lookup: [String: ExerciseDefinition] = Dictionary(uniqueKeysWithValues: standard.map { ($0.id, $0) })

    private static func exercise(
        _ id: String,
        _ name: String,
        _ pattern: MovementPattern,
        _ equipment: Set<EquipmentKind>,
        _ cues: String,
        _ safety: String,
        _ beginner: Double? = nil,
        _ intermediate: Double? = nil,
        _ advanced: Double? = nil
    ) -> ExerciseDefinition {
        ExerciseDefinition(
            id: id,
            name: name,
            movementPattern: pattern,
            requiredEquipment: equipment,
            cues: cues,
            safetyNotes: safety,
            beginnerLoadKilograms: beginner,
            intermediateLoadKilograms: intermediate,
            advancedLoadKilograms: advanced
        )
    }
}
