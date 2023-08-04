import Foundation
import Models

struct Operation: Identifiable, Equatable {
    let delay: Delay
    let startEnd: ClosedRange<Date>
    let offPeakPeriod: ClosedRange<Date>?

    var duration: TimeInterval { startEnd.lowerBound.distance(to: startEnd.upperBound) }

    var peakDuration: TimeInterval {
        guard let offPeakPeriod else { return 0 }
        return offPeakPeriod.peakDuration(between: startEnd)
    }

    var minutesOffPeak: Int { Int(max(duration - peakDuration, 0) / 60) }
    var minutesInPeak: Int { Int(min(peakDuration, duration) / 60) }
    var offPeakRatio: Double { max(duration - peakDuration, 0)/duration }

    var offPeakRangeRatio: ClosedRange<Double> {
        guard let offPeakPeriod else { return 0...0 }
        let startDistance = max(startEnd.lowerBound.distance(to: offPeakPeriod.lowerBound), 0)
        let startRatio = startDistance / duration

        let endDistance = max(offPeakPeriod.upperBound.distance(to: startEnd.upperBound), 0)
        let endRatio = 1 - endDistance / duration

        return startRatio...endRatio
    }

    var id: Delay.ID { delay.id }
}

extension [Operation] {
    static func nextOperations(
        periods: [Period],
        program: Program,
        delays: [Delay],
        now: Date,
        calendar: Calendar
    ) -> Self {
        let ranges = dateRanges(periods, now: now, calendar: calendar)
        return delays.map {
            let hour = TimeInterval($0.hour)
            let minute = TimeInterval($0.minute)
            let start = now.addingTimeInterval(hour * 60 * 60 + minute * 60)
            let end = start.addingTimeInterval(program.duration)
            let startEnd = start...end

            let bestOffPeakPeriod = ranges.max { a, b in
                let peakDurationA = a.peakDuration(between: startEnd)
                let peakDurationB = b.peakDuration(between: startEnd)
                return peakDurationA > peakDurationB
            }

            return Operation(delay: $0, startEnd: startEnd, offPeakPeriod: bestOffPeakPeriod)
        }
    }

    private static func dateRanges(_ periods: [Period], now: Date, calendar: Calendar) -> [ClosedRange<Date>] {
        periods.flatMap { period in
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

private extension ClosedRange<Date> {
    func peakDuration(between range: ClosedRange<Date>) -> TimeInterval {
        let distanceToOffPeakStart = range.lowerBound.distance(to: lowerBound)
        let distanceFromOffPeakEnd = upperBound.distance(to: range.upperBound)
        return Swift.max(distanceToOffPeakStart, 0) + Swift.max(distanceFromOffPeakEnd, 0)
    }
}
