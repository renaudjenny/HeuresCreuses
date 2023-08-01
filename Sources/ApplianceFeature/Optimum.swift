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
                return .run { send in
                    let delay = Delay(hour: 2, minute: 0)
                    let ratio = 1.0
                    let durationBeforeStart = 23.0 * 60
                    await send(.computationFinished(
                        delay: delay,
                        ratio: ratio,
                        durationBeforeStart: durationBeforeStart
                    ))
                }
            }
        }
    }
}
