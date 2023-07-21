import ComposableArchitecture
import Foundation
import Models

public struct Delays: Reducer {
    public struct State: Equatable {
        var program: Program
        var appliance: Appliance
        var items: [Item]

        public init(program: Program, appliance: Appliance) {
            self.program = program
            self.appliance = appliance
            self.items = ([Delay(hour: 0, minute: 0)] + appliance.delays).map {
                Item(delay: $0, minutesOffPeak: 0, minutesInPeak: 0)
            }
        }
    }
    public enum Action: Equatable {
        case task
    }

    @Dependency(\.date) var date
    @Dependency(\.calendar) var calendar
    @Dependency(\.periodProvider) var periodProvider

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .task:
                let offPeakPeriods = offPeakPeriods
                state.items = state.items.map {
                    var item = $0
                    let hour = TimeInterval($0.delay.hour)
                    let minute = TimeInterval($0.delay.minute)
                    let start = date().addingTimeInterval(hour * 60 * 60 + minute * 60)
                    let end = start.addingTimeInterval(state.program.duration)

                    let bestOffPeakPeriod = offPeakPeriods.max { a, b in
                        let peakDurationA = (a.start...a.end).peakDuration(betweenStart: start, end: end)
                        let peakDurationB = (b.start...b.end).peakDuration(betweenStart: start, end: end)
                        return peakDurationA > peakDurationB
                    }

                    if let bestOffPeakPeriod {
                        let peakDuration = (bestOffPeakPeriod.start...bestOffPeakPeriod.end)
                            .peakDuration(betweenStart: start, end: end)
                        let offPeakDuration = state.program.duration - peakDuration

                        item.minutesInPeak = Int(min(peakDuration, state.program.duration) / 60)
                        item.minutesOffPeak = Int(max(offPeakDuration, 0) / 60)
                    } else {
                        item.minutesInPeak = 0
                        item.minutesOffPeak = 0
                    }
                    return item
                }
                return .none
            }
        }
    }

    private var offPeakPeriods: [(start: Date, end: Date)] {
        periodProvider.get().flatMap { period in
            var start = period.start
            start.year = calendar.component(.year, from: date())
            start.month = calendar.component(.month, from: date())
            start.day = calendar.component(.day, from: date())
            var end = period.end
            end.year = calendar.component(.year, from: date())
            end.month = calendar.component(.month, from: date())
            end.day = calendar.component(.day, from: date())

            return (-1...1).compactMap { day -> (start: Date, end: Date)? in
                let day = TimeInterval(day)
                guard let offPeakStartDate = calendar.date(from: start)?.addingTimeInterval(day * 60 * 60 * 24),
                      let offPeakEndDate = calendar.date(from: end)?.addingTimeInterval(day * 60 * 60 * 24)
                else { return nil }
                if offPeakEndDate > offPeakStartDate {
                    return (start: offPeakStartDate, end: offPeakEndDate)
                } else {
                    let offPeakEndDate = offPeakEndDate.addingTimeInterval(60 * 60 * 24)
                    return (start: offPeakStartDate, end: offPeakEndDate)
                }
            }
        }
    }
}

extension Delays.State {
    struct Item: Identifiable, Equatable {
        let delay: Delay
        var minutesOffPeak: Int
        var minutesInPeak: Int

        var id: Delay.ID { delay.id }
    }
}

private extension ClosedRange<Date> {
    func peakDuration(betweenStart start: Date, end: Date) -> TimeInterval {
        let distanceToOffPeakStart = start.distance(to: lowerBound)
        let distanceFromOffPeakEnd = upperBound.distance(to: end)
        return Swift.max(distanceToOffPeakStart, 0) + Swift.max(distanceFromOffPeakEnd, 0)
    }
}
