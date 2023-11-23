import Foundation

public extension [ClosedRange<Date>] {

    static func nextOffPeakRanges(_ periods: [Period], now: Date, calendar: Calendar) -> Self {
        let ranges = periods.flatMap { period -> [ClosedRange<Date>] in
            var periodRanges: [ClosedRange<Date>] = []
            var now = now

            if period.containsNow(now, calendar: calendar) {
                for range in period.ranges(from: now, calendar: calendar, direction: .backward) {
                    periodRanges.append(range)
                }
                if let lastRangeEndDate = periodRanges.last?.upperBound,
                   let end = calendar.date(byAdding: .minute, value: 1, to: lastRangeEndDate) {
                    now = end
                }
            }

            for range in period.ranges(from: now, calendar: calendar) {
                periodRanges.append(range)
            }

            return periodRanges
        }

        return ranges.sorted { $0.lowerBound < $1.lowerBound }
    }
}
