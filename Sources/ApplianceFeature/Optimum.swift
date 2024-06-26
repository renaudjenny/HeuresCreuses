import ComposableArchitecture
import Foundation
import Models
import SendNotification

@Reducer
public struct Optimum {
    @ObservableState
    public struct State: Equatable {
        let program: Program
        let appliance: Appliance
        @Shared(.periods) var periods: IdentifiedArrayOf<Period>
        var delay = Duration.zero
        var ratio: Double = 0
        var durationBeforeStart: Duration = .zero
        var sendNotification = SendNotification.State()

        public init(
            program: Program,
            appliance: Appliance,
            periods: IdentifiedArrayOf<Period> = IdentifiedArray(uniqueElements: [Period].example)
        ) {
            self.program = program
            self.appliance = appliance
            self._periods = Shared(wrappedValue: periods, .periods)
        }
    }
    public enum Action: Equatable {
        case delaysTapped(Program)
        case computationFinished(delay: Duration, ratio: Double, durationBeforeStart: Duration)
        case sendNotification(SendNotification.Action)
        case task
    }

    @Dependency(\.calendar) var calendar
    @Dependency(\.date) var date
    @Dependency(\.uuid) var uuid

    public var body: some ReducerOf<Self> {
        Scope(state: \.sendNotification, action: \.sendNotification) {
            SendNotification()
        }

        Reduce { state, action in
            switch action {
            case .delaysTapped:
                return .none
            case let .computationFinished(delay, ratio, durationBeforeStart):
                state.delay = delay
                state.ratio = ratio
                state.durationBeforeStart = durationBeforeStart
                state.sendNotification = SendNotification.State(intent: .applianceToProgram(
                    body: """
                    \(state.appliance.name)
                    Program \(state.program.name)
                    Delay \(state.delay.hourMinute)
                    """,
                    delay: state.delay,
                    durationBeforeStart: state.durationBeforeStart
                ))
                return .none
            case .sendNotification:
                return .none
            case .task:
                return .run { [state] send in
                    let operations = [Operation].nextOperations(
                        periods: state.periods.elements,
                        program: state.program,
                        delays: state.appliance.delays,
                        now: date(),
                        calendar: calendar
                    )
                    let operation = operations.max {
                        if $0.offPeakRangeRatio.upperBound == 1 && $1.offPeakRangeRatio.upperBound < 1 {
                            return false
                        }
                        return $0.offPeakRatio < $1.offPeakRatio
                    }
                    guard let operation, let offPeakPeriodStart = operation.offPeakPeriod?.lowerBound else { return }
                    let durationBeforeStart = operation.startEnd.lowerBound.durationDistance(to: offPeakPeriodStart)

                    let bestOperation: Operation
                    if durationBeforeStart > .zero,
                       let operation = [Operation].nextOperations(
                        periods: state.periods.elements,
                        program: state.program,
                        delays: state.appliance.delays,
                        now: date().addingTimeInterval(TimeInterval(durationBeforeStart.components.seconds)),
                        calendar: calendar
                       ).first(where: { $0.delay == operation.delay }) {
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
