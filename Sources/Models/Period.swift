import Foundation
import Dependencies

public struct Period: Equatable, Hashable, Identifiable {
    public let start: DateComponents
    public let end: DateComponents
    public var id: Int { hashValue }

    public init(start: DateComponents, end: DateComponents) {
        self.start = start
        self.end = end
    }
}

public extension [Period] {
    static let example: Self = [
        Period(start: DateComponents(hour: 2, minute: 2), end: DateComponents(hour: 8, minute: 2)),
        Period(start: DateComponents(hour: 15, minute: 2), end: DateComponents(hour: 17, minute: 2)),
    ]
}

public struct PeriodProvider {
    public var get: () -> [Period]

    public func callAsFunction() -> [Period] {
        return get()
    }
}

extension PeriodProvider: DependencyKey {
    static public var liveValue = PeriodProvider {
        [
            Period(start: DateComponents(hour: 2, minute: 2), end: DateComponents(hour: 8, minute: 2)),
            Period(start: DateComponents(hour: 15, minute: 2), end: DateComponents(hour: 17, minute: 2)),
        ]
    }
}

public extension DependencyValues {
    var periodProvider: PeriodProvider {
        get { self[PeriodProvider.self] }
        set { self[PeriodProvider.self] = newValue }
    }
}
