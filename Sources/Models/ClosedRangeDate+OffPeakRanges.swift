import Foundation

// TODO: dance of PeriodLegacy and rename this one to Period
public struct PeriodMinute {
    public let start: Int
    public let end: Int

    func range(
        from date: Date,
        calendar: Calendar,
        direction: Calendar.SearchDirection = .forward
    ) -> ClosedRange<Date>? {
        guard 
            let start = calendar.date(
                bySettingHour: start/60,
                minute: start % 60,
                second: 0,
                of: date,
                direction: direction
            ),
            let end = calendar.date(
                bySettingHour: end/60,
                minute: end % 60,
                second: 0,
                of: date,
                direction: direction
            )
        else { return nil }
        return start...end
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

    static func nextOffPeakRanges(_ periods: [Period], now: Date, calendar: Calendar) -> Self {
        let currentDayMinutes = calendar.component(.hour, from: now) * 60 + calendar.component(.minute, from: now)
        let periodsMinutes = periods.flatMap(\.periodMinutes)

        let ranges = periodsMinutes.flatMap { period -> [ClosedRange<Date>] in
            guard period.end > currentDayMinutes else { return [] }
            var periodRanges: [ClosedRange<Date>] = []

            if (period.start...period.end).contains(currentDayMinutes) {
                period.range(from: now, calendar: calendar, direction: .backward).map { periodRanges.append($0) }
            }

            period.range(from: now, calendar: calendar).map { periodRanges.append($0) }

            return periodRanges
        }

        return Self(ranges.prefix(2))
    }
}

extension Period {
    var periodMinutes: [PeriodMinute] {
        guard let startHour = start.hour, let startMinute = start.minute,
              let endHour = end.hour, let endMinute = end.minute
        else { return [] }
        let startMinutes = startHour * 60 + startMinute
        let endMinutes = endHour * 60 + endMinute

        guard endMinutes > startMinutes else {
            return [
                PeriodMinute(start: -(60 * 24 - startMinutes) , end: endMinutes),
                PeriodMinute(start: startMinutes, end: endMinutes + 60 * 24)
            ]
        }
        
        return [PeriodMinute(start: startMinutes, end: endMinutes)]
    }
}
