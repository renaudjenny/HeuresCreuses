import Foundation
import Models

struct Operation: Identifiable, Equatable {
    let delay: Duration
    let startEnd: ClosedRange<Date>
    let offPeakPeriod: ClosedRange<Date>?

    var duration: Duration { startEnd.lowerBound.durationDistance(to: startEnd.upperBound) }

    var peakDuration: Duration {
        guard let offPeakPeriod else { return .zero }
        return offPeakPeriod.peakDuration(between: startEnd)
    }

    var minutesOffPeak: Int { Int(max(duration - peakDuration, .zero).components.seconds / 60) }
    var minutesInPeak: Int { Int(min(peakDuration, duration).components.seconds / 60) }
    var offPeakRatio: Double { max(duration - peakDuration, .zero)/duration }

    var offPeakRangeRatio: ClosedRange<Double> {
        guard let offPeakPeriod else { return 0...0 }
        let startDistance = max(startEnd.lowerBound.distance(to: offPeakPeriod.lowerBound), 0)
        let startRatio = min(startDistance / Double(duration.components.seconds), 1)

        let endDistance = max(offPeakPeriod.upperBound.distance(to: startEnd.upperBound), 0)
        let endRatio = max(1 - endDistance / Double(duration.components.seconds), 0)

        return startRatio...endRatio
    }

    var id: Int { delay.hashValue }
}

extension [Operation] {
    static func nextOperations(
        periods: [PeriodMinute],
        program: Program,
        delays: [Duration],
        now: Date,
        calendar: Calendar
    ) -> Self {
        let ranges = [ClosedRange<Date>].nextOffPeakRanges(periods, now: now, calendar: calendar)
        return delays.map {
            let start = now.addingTimeInterval(Double($0.components.seconds))
            let end = start.addingTimeInterval(Double(program.duration.components.seconds))
            let startEnd = start...end

            let bestOffPeakPeriod = ranges.max { a, b in
                let peakDurationA = a.peakDuration(between: startEnd)
                let peakDurationB = b.peakDuration(between: startEnd)
                return peakDurationA > peakDurationB
            }

            return Operation(delay: $0, startEnd: startEnd, offPeakPeriod: bestOffPeakPeriod)
        }
    }
}

private extension ClosedRange<Date> {
    func peakDuration(between range: ClosedRange<Date>) -> Duration {
        let distanceToOffPeakStart = range.lowerBound.durationDistance(to: lowerBound)
        let distanceFromOffPeakEnd = upperBound.durationDistance(to: range.upperBound)
        return Swift.max(distanceToOffPeakStart, .zero) + Swift.max(distanceFromOffPeakEnd, .zero)
    }
}
