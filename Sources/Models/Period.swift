import Foundation
import Dependencies

@available(*, deprecated, message: "Replace by PeriodMinute")
public typealias Period = PeriodLegacy

public struct PeriodLegacy: Equatable, Hashable, Identifiable {
    public let start: DateComponents
    public let end: DateComponents
    public var id: Int { hashValue }

    public init(start: DateComponents, end: DateComponents) {
        self.start = start
        self.end = end
    }
}

public extension [PeriodMinute] {
    static let example: Self = [
        PeriodMinute(start: 2 * 60 + 2, end: 8 * 60 + 2),
        PeriodMinute(start: 15 * 60 + 2, end: 17 * 60 + 2),
    ]
}

public struct PeriodProvider {
    public var get: () -> [PeriodMinute]

    public func callAsFunction() -> [PeriodMinute] {
        return get()
    }
}

extension PeriodProvider: DependencyKey {
    static public var liveValue = PeriodProvider { .example }
}

public extension DependencyValues {
    var periodProvider: PeriodProvider {
        get { self[PeriodProvider.self] }
        set { self[PeriodProvider.self] = newValue }
    }
}
