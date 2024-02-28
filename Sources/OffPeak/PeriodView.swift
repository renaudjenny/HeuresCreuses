import Dependencies
import Models
import SwiftUI

struct PeriodView: View {
    let period: Period

    var body: some View {
        HStack {
            ZStack {
                Circle()
                    .stroke(Color.primary.opacity(25/100), lineWidth: 5)
                    .frame(width: 40, height: 40)
                Circle()
                    .rotation(.radians(-.pi/2))
                    .trim(from: period.relativeClockPosition.start, to: period.relativeClockPosition.end)
                    .stroke(Color.green, lineWidth: 5)
                    .frame(width: 40, height: 40)
            }
            Text(period.dateFormatted.start).monospacedDigit()
            Image(systemName: "arrowshape.forward")
            Text(period.dateFormatted.end).monospacedDigit()
        }
        .accessibilityLabel(
            Text("\(period.dateFormatted.start) to \(period.dateFormatted.end)", comment: "<Hour:Minutes> to <Hour:Minutes>")
        )
    }
}

extension Period {
    var dateFormatted: (start: String, end: String) {
        @Dependency(\.calendar) var calendar
        @Dependency(\.date.now) var now

        guard let range = ranges(from: now, calendar: calendar).first else { return ("", "") }
        return (
            start: range.lowerBound.formatted(date: .omitted, time: .shortened),
            end: range.upperBound.formatted(date: .omitted, time: .shortened)
        )
    }

    var relativeClockPosition: (start: Double, end: Double) {
        @Dependency(\.calendar) var calendar
        @Dependency(\.date.now) var now

        let maxMinutes = 24.0 * 60.0
        guard let range = ranges(from: now, calendar: calendar).first else { return (0, 0) }
        return (
            start: range.lowerBound.minutes(calendar: calendar)/maxMinutes,
            end: range.upperBound.minutes(calendar: calendar)/maxMinutes
        )
    }
}

private extension Date {
    func minutes(calendar: Calendar) -> Double {
        Double(calendar.component(.hour, from: self)) * 60 + Double(calendar.component(.minute, from: self))
    }
}
