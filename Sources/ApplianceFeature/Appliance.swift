import Foundation

public struct Appliance: Identifiable {
    public var id: UUID
    public var name: String
    public var type: ApplianceType
    public var programs: [Program]
    public var delays: [Duration]

    public init(
        id: UUID,
        name: String = "",
        type: ApplianceType = .dishWasher,
        programs: [Program] = [],
        delays: [Duration] = []
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.programs = programs
        self.delays = delays
    }
}

public enum ApplianceType {
    case washingMachine
    case dishWasher
}

extension Appliance: Equatable {
    public static func ==(lhs: Self, rhs: Self) -> Bool { lhs.id == rhs.id }
}
