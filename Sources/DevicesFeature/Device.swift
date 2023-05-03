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

public enum Delay: CaseIterable, Equatable, Hashable {
    case none
    case timers([Timer])
    case schedule

    static public var allCases: [Delay] { [.none, .timers([]), .schedule] }
    public func hash(into hasher: inout Hasher) {
        switch self {
        case .none: hasher.combine(0)
        case .timers: hasher.combine(1)
        case .schedule: hasher.combine(2)
        }
    }
    public static func ==(lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.none, .none): return true
        case let (.timers(lhsTimers), .timers(rhsTimers)): return lhsTimers == rhsTimers
        case (.schedule, .schedule): return true
        default: return false
        }
    }
}

public extension Delay {
    struct Timer: Equatable {
        public let hour: Int
        public let minute: Int

        public init(hour: Int, minute: Int) {
            self.hour = hour
            self.minute = minute
        }
    }
}

public struct Program: Equatable, Identifiable {
    public let id: UUID
    public var name: String
    public var duration: TimeInterval
}
