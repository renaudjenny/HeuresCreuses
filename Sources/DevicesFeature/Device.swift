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

public enum DeviceType {
    case washingMachine
    case dishWasher
}

public enum Delay {
    case none
    case timers([(hour: Int, minute: Int)])
    case schedule
}

public struct Program {
    var name: String
    var duration: Duration
}
