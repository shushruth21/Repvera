import Foundation

public enum EquipmentKind: String, Sendable, Codable, CaseIterable, Identifiable {
    case barbell
    case dumbbell
    case cable
    case machine
    case bench
    case pullUpBar
    case bodyweight
    case kettlebell
    case trapBar

    public var id: String { rawValue }

    public var label: String {
        switch self {
        case .barbell: "Barbell"
        case .dumbbell: "Dumbbells"
        case .cable: "Cables"
        case .machine: "Machines"
        case .bench: "Bench"
        case .pullUpBar: "Pull-up bar"
        case .bodyweight: "Bodyweight"
        case .kettlebell: "Kettlebell"
        case .trapBar: "Trap bar"
        }
    }

    public static let commercialGym: Set<EquipmentKind> = Set(allCases)
    public static let homeGym: Set<EquipmentKind> = [.barbell, .dumbbell, .bench, .pullUpBar, .bodyweight, .kettlebell]
    public static let dumbbellsOnly: Set<EquipmentKind> = [.dumbbell, .bench, .bodyweight]
    public static let bodyweightOnly: Set<EquipmentKind> = [.bodyweight, .pullUpBar]
}

public enum EquipmentPreset: String, Sendable, CaseIterable, Identifiable {
    case commercialGym
    case homeGym
    case dumbbells
    case bodyweight

    public var id: String { rawValue }

    public var label: String {
        switch self {
        case .commercialGym: "Commercial gym"
        case .homeGym: "Home gym"
        case .dumbbells: "Dumbbells"
        case .bodyweight: "Bodyweight"
        }
    }

    public var equipment: Set<EquipmentKind> {
        switch self {
        case .commercialGym: EquipmentKind.commercialGym
        case .homeGym: EquipmentKind.homeGym
        case .dumbbells: EquipmentKind.dumbbellsOnly
        case .bodyweight: EquipmentKind.bodyweightOnly
        }
    }
}
