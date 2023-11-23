import Foundation
import Dependencies

public struct Period: Equatable, Hashable, Identifiable, CustomDebugStringConvertible {
    private let minuteRanges: [ClosedRange<Int>]

    public var debugDescription: String {
        ranges(from: .now, calendar: .autoupdatingCurrent).debugDescription
    }

    public var id: Int { hashValue }

    public init(start: (hour: Int, minute: Int), end: (hour: Int, minute: Int)) {
        let start = start.hour * 60 + start.minute
        let end = end.hour * 60 + end.minute

        guard start < end else {
            minuteRanges = [-(60 * 24 - start)...end, start...(end + 60 * 24)]
            return
        }

        minuteRanges = [start...end]
    }

    public func ranges(
        from date: Date,
        calendar: Calendar,
        direction: Calendar.SearchDirection = .forward
    ) -> [ClosedRange<Date>] {
        minuteRanges.compactMap { range(minuteRange: $0, from: date, calendar: calendar, direction: direction) }
    }

    private func range(
        minuteRange: ClosedRange<Int>,
        from date: Date,
        calendar: Calendar,
        direction: Calendar.SearchDirection = .forward
    ) -> ClosedRange<Date>? {
        guard minuteRange.lowerBound >= 0 else {
            return rangeWithNegativeStart(minuteRange: minuteRange, from: date, calendar: calendar, direction: direction)
        }
        guard
            let start = calendar.date(
                bySettingHour: minuteRange.lowerBound/60,
                minute: minuteRange.lowerBound % 60,
                second: 0,
                of: date,
                direction: direction
            ),
            let end = calendar.date(
                bySettingHour: minuteRange.upperBound/60,
                minute: minuteRange.upperBound % 60,
                second: 0,
                of: date,
                direction: direction
            )
        else { return nil }

        if end < date,
           let nextStart = calendar.date(byAdding: .day, value: 1, to: start),
           let nextEnd = calendar.date(byAdding: .day, value: 1, to: end) {
            return nextStart...nextEnd
        }

        return start...end
    }

    private func rangeWithNegativeStart(
        minuteRange: ClosedRange<Int>,
        from date: Date,
        calendar: Calendar,
        direction: Calendar.SearchDirection = .forward
    ) -> ClosedRange<Date>? {
        let start = 60 * 24 + minuteRange.lowerBound
        guard
            let start = calendar.date(
                bySettingHour: start/60,
                minute: start % 60,
                second: 0,
                of: date,
                direction: direction
            ),
            let tomorrow = calendar.date(byAdding: .day, value: 1, to: date),
            let end = calendar.date(
                bySettingHour: minuteRange.upperBound/60,
                minute: minuteRange.upperBound % 60,
                second: 0,
                of: tomorrow,
                direction: direction
            )
        else { return nil }
        return start...end
    }

    func containsNow(_ now: Date, calendar: Calendar) -> Bool {
        let currentDayMinutes = calendar.component(.hour, from: now) * 60 + calendar.component(.minute, from: now)
        return minuteRanges.contains { $0.contains(currentDayMinutes) }
    }
}

public extension [Period] {
    static let example: Self = [
        Period(start: (hour: 2, minute: 2), end: (hour: 8, minute: 2)),
        Period(start: (hour: 15, minute: 2), end: (hour: 17, minute: 2)),
    ]
}

public struct PeriodProvider {
    public var get: () -> [Period]

    public func callAsFunction() -> [Period] {
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
