import Foundation
import Dependencies

public struct Period: Equatable {
    public let start: DateComponents
    public let end: DateComponents

    public init(start: DateComponents, end: DateComponents) {
        self.start = start
        self.end = end
    }
}

public extension [ClosedRange<Date>] {
    static func offPeakRanges(_ periods: [Period], now: Date, calendar: Calendar) -> Self {
        periods.flatMap { period -> [ClosedRange<Date>] in
            var start = period.start
            start.year = calendar.component(.year, from: now)
            start.month = calendar.component(.month, from: now)
            start.day = calendar.component(.day, from: now)
            var end = period.end
            end.year = calendar.component(.year, from: now)
            end.month = calendar.component(.month, from: now)
            end.day = calendar.component(.day, from: now)

            return (-1...1).compactMap { day -> ClosedRange<Date>? in
                let day = TimeInterval(day)
                guard let offPeakStartDate = calendar.date(from: start)?.addingTimeInterval(day * 60 * 60 * 24),
                      let offPeakEndDate = calendar.date(from: end)?.addingTimeInterval(day * 60 * 60 * 24)
                else { return nil }
                if offPeakEndDate > offPeakStartDate {
                    return offPeakStartDate...offPeakEndDate
                } else {
                    let offPeakEndDate = offPeakEndDate.addingTimeInterval(60 * 60 * 24)
                    return offPeakStartDate...offPeakEndDate
                }
            }
        }
    }
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
