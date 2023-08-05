import ComposableArchitecture
import Foundation

public struct Optimum: Reducer {
    public struct State: Equatable {
        let program: Program
        let appliance: Appliance
        var delay = Delay(hour: 0, minute: 0)
        var ratio: Double = 0
        var durationBeforeStart: TimeInterval = 0

        public init(program: Program, appliance: Appliance) {
            self.program = program
            self.appliance = appliance
        }
    }
    public enum Action: Equatable {
        case delaysTapped(Program)
        case computationFinished(delay: Delay, ratio: Double, durationBeforeStart: TimeInterval)
        case task
    }

    @Dependency(\.calendar) var calendar
    @Dependency(\.date) var date
    @Dependency(\.periodProvider) var periodProvider

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .delaysTapped:
                return .none
            case let .computationFinished(delay, ratio, durationBeforeStart):
                state.delay = delay
                state.ratio = ratio
                state.durationBeforeStart = durationBeforeStart
                return .none
            case .task:
                return .run { [state] send in
                    let operation = [Operation].nextOperations(
                        periods: periodProvider(),
                        program: state.program,
                        delays: state.appliance.delays,
                        now: date(),
                        calendar: calendar
                    ).max {
                        if $0.delay.hour == 2 && $1.delay.hour == 4 {
                            print($0.offPeakRangeRatio.upperBound == 1 && $1.offPeakRangeRatio.upperBound < 1)
                            print($0.offPeakRatio < $1.offPeakRatio)
                        }
                        if $0.offPeakRangeRatio.upperBound == 1 && $1.offPeakRangeRatio.upperBound < 1 {
                            return false
                        }
                        return $0.offPeakRatio < $1.offPeakRatio
                    }
                    guard let operation, let offPeakPeriodStart = operation.offPeakPeriod?.lowerBound else { return }
                    let durationBeforeStart = operation.startEnd.lowerBound.distance(to: offPeakPeriodStart)

                    let bestOperation: Operation
                    if durationBeforeStart > 0,
                       let operation = [Operation].nextOperations(periods: periodProvider(), program: state.program, delays: state.appliance.delays, now: date().addingTimeInterval(durationBeforeStart), calendar: calendar).first(where: { $0.delay == operation.delay }) {
                        bestOperation = operation
                    } else {
                        bestOperation = operation
                    }
                    await send(.computationFinished(
                        delay: bestOperation.delay,
                        ratio: bestOperation.offPeakRatio,
                        durationBeforeStart: durationBeforeStart
                    ))
                }
            }
        }
    }
}
