import Foundation
import Dependencies

public struct Period: Equatable, Hashable, Identifiable, CustomDebugStringConvertible {
    public var id: UUID
    public var startHour: Int
    public var startMinute: Int
    public var endHour: Int
    public var endMinute: Int

    private var minuteRanges: [ClosedRange<Int>] {
        let start = startHour * 60 + startMinute
        let end = endHour * 60 + endMinute

        return start < end
        ? [start...end]
        : [-(60 * 24 - start)...end, start...(end + 60 * 24)]

    }

    public var debugDescription: String {
        ranges(from: .now, calendar: .autoupdatingCurrent).debugDescription
    }

    public init(id: UUID, startHour: Int, startMinute: Int, endHour: Int, endMinute: Int) {
        self.id = id
        self.startHour = startHour
        self.startMinute = startMinute
        self.endHour = endHour
        self.endMinute = endMinute
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
        Period(id: UUID(uuidString: "8706623F-0215-4706-94F0-FD363533CBEC") ?? UUID(), startHour: 2, startMinute: 2, endHour: 8, endMinute: 2),
        Period(id: UUID(uuidString: "93335C31-0ACF-46B7-98FD-F564B8E15B54") ?? UUID(), startHour: 15, startMinute: 2, endHour: 17, endMinute: 2),
    ]
}

// TODO: could be a shared state when available
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
