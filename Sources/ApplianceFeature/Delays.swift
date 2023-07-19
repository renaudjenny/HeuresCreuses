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
                let offPeackPeriods = offPeakPeriods
                state.items = state.items.map {
                    var item = $0
                    // TODO: find minutes In/Off peak rules and apply that
                    item.minutesInPeak = 0
                    item.minutesOffPeak = 0
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
