import Foundation

public struct Device: Identifiable {
    public var id: UUID
    public var name: String
    public var type: DeviceType
    public var delay: Delay
    public var programs: [Program]
}

extension Device: Equatable {
    public static func ==(lhs: Self, rhs: Self) -> Bool { lhs.id == rhs.id }
}

public enum DeviceType: CaseIterable {
    case washingMachine
    case dishWasher
}

public enum Delay: CaseIterable, Hashable {
    case none
    case timers([(hour: Int, minute: Int)])
    case schedule

    static public var allCases: [Delay] { [.none, .timers([]), .schedule] }
    public func hash(into hasher: inout Hasher) {
        switch self {
        case .none: hasher.combine(0)
        case let .timers(timers): hasher.combine(1)
        case .schedule: hasher.combine(2)
        }
    }
}

public struct Program {
    var name: String
    var duration: Duration
}
