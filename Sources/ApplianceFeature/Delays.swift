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

                    // TODO: refactor, add an extension ClosedRange<Date> to return minutesOffPeak
                    let bestOffPeakPeriod = offPeakPeriods.max { a, b in
                        let distanceToOffPeakStartA = start.distance(to: a.start)
                        let distanceFromOffPeakEndA = a.end.distance(to: end)
                        let peakDurationA = max(distanceToOffPeakStartA, 0) + max(distanceFromOffPeakEndA, 0)
                        let offPeakDurationA = start.distance(to: end) - peakDurationA

                        let distanceToOffPeakStartB = start.distance(to: b.start)
                        let distanceFromOffPeakEndB = b.end.distance(to: end)
                        let peakDurationB = max(distanceToOffPeakStartB, 0) + max(distanceFromOffPeakEndB, 0)
                        let offPeakDurationB = start.distance(to: end) - peakDurationB

                        return offPeakDurationA < offPeakDurationB
                    }

                    if let bestOffPeakPeriod {
                        let distanceToOffPeakStart = start.distance(to: bestOffPeakPeriod.start)
                        let distanceFromOffPeakEnd = bestOffPeakPeriod.end.distance(to: end)
                        let peakDuration = max(distanceToOffPeakStart, 0) + max(distanceFromOffPeakEnd, 0)
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
