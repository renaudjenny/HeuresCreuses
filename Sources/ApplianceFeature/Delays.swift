import ComposableArchitecture
import Foundation
import Models

public struct Delays: Reducer {
    public struct State: Equatable {
        var program: Program
        var appliance: Appliance
        var items: [Item] = []

        public init(program: Program, appliance: Appliance) {
            self.program = program
            self.appliance = appliance
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
                state.items = ([Delay(hour: 0, minute: 0)] + state.appliance.delays).map {
                    let hour = TimeInterval($0.hour)
                    let minute = TimeInterval($0.minute)
                    let start = date().addingTimeInterval(hour * 60 * 60 + minute * 60)
                    let end = start.addingTimeInterval(state.program.duration)
                    let startEnd = start...end

                    let bestOffPeakPeriod = offPeakPeriods.max { a, b in
                        let peakDurationA = a.peakDuration(between: startEnd)
                        let peakDurationB = b.peakDuration(between: startEnd)
                        return peakDurationA > peakDurationB
                    }

                    return State.Item(delay: $0, startEnd: startEnd, offPeakPeriod: bestOffPeakPeriod)
                }
                return .none
            }
        }
    }

    private var offPeakPeriods: [ClosedRange<Date>] {
        periodProvider.get().flatMap { period in
            var start = period.start
            start.year = calendar.component(.year, from: date())
            start.month = calendar.component(.month, from: date())
            start.day = calendar.component(.day, from: date())
            var end = period.end
            end.year = calendar.component(.year, from: date())
            end.month = calendar.component(.month, from: date())
            end.day = calendar.component(.day, from: date())

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

extension Delays.State {
    struct Item: Identifiable, Equatable {
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
}

private extension ClosedRange<Date> {
    func peakDuration(between range: ClosedRange<Date>) -> TimeInterval {
        let distanceToOffPeakStart = range.lowerBound.distance(to: lowerBound)
        let distanceFromOffPeakEnd = upperBound.distance(to: range.upperBound)
        return Swift.max(distanceToOffPeakStart, 0) + Swift.max(distanceFromOffPeakEnd, 0)
    }
}
