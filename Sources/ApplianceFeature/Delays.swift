import ComposableArchitecture
import Foundation
import Models

public struct Delays: Reducer {
    public struct State: Equatable {
        var program: Program
        var appliance: Appliance
        var items: [Item] = []
        var isOffPeakOnlyFilterOn = false

        public init(program: Program, appliance: Appliance) {
            self.program = program
            self.appliance = appliance
        }
    }
    public enum Action: Equatable {
        case task
        case onlyShowOffPeakTapped
    }

    @Dependency(\.date) var date
    @Dependency(\.calendar) var calendar
    @Dependency(\.periodProvider) var periodProvider

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .task:
                return refreshItems(&state)
            case .onlyShowOffPeakTapped:
                state.isOffPeakOnlyFilterOn.toggle()
                return refreshItems(&state)
            }
        }
    }

    private func refreshItems(_ state: inout State) -> Effect<Action> {
        let offPeakPeriods = Offpeak.dateRanges(periodProvider.get(), now: date(), calendar: calendar)
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
        .filter {
            guard state.isOffPeakOnlyFilterOn else { return true }
            return $0.minutesOffPeak > 0
        }
        return .none
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
}

private extension ClosedRange<Date> {
    func peakDuration(between range: ClosedRange<Date>) -> TimeInterval {
        let distanceToOffPeakStart = range.lowerBound.distance(to: lowerBound)
        let distanceFromOffPeakEnd = upperBound.distance(to: range.upperBound)
        return Swift.max(distanceToOffPeakStart, 0) + Swift.max(distanceFromOffPeakEnd, 0)
    }
}
