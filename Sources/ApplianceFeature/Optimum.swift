import ComposableArchitecture
import Foundation
#if canImport(NotificationCenter)
import NotificationCenter
#endif
import UserNotificationsDependency

public struct Optimum: Reducer {
    public struct State: Equatable {
        let program: Program
        let appliance: Appliance
        var delay = Duration.zero
        var ratio: Double = 0
        var durationBeforeStart: Duration = .zero
        #if canImport(NotificationCenter)
        var sendNotificationAuthorizationStatus: UNAuthorizationStatus = .notDetermined
        var sendNotification: SendNotification.State {
            get {
                SendNotification.State(
                    program: program,
                    appliance: appliance,
                    delay: delay,
                    durationBeforeStart: durationBeforeStart,
                    notificationAuthorizationStatus: sendNotificationAuthorizationStatus
                )
            }
            set {
                sendNotificationAuthorizationStatus = newValue.notificationAuthorizationStatus
            }
        }
        #endif

        public init(program: Program, appliance: Appliance) {
            self.program = program
            self.appliance = appliance
        }
    }
    public enum Action: Equatable {
        case delaysTapped(Program)
        case computationFinished(delay: Duration, ratio: Double, durationBeforeStart: Duration)
        #if canImport(NotificationCenter)
        case sendNotification(SendNotification.Action)
        #endif
        case task
    }

    @Dependency(\.calendar) var calendar
    @Dependency(\.date) var date
    @Dependency(\.periodProvider) var periodProvider
    @Dependency(\.userNotificationCenter) var userNotificationCenter
    @Dependency(\.uuid) var uuid

    public var body: some ReducerOf<Self> {
        #if canImport(NotificationCenter)
        Scope(state: \.sendNotification, action: /Action.sendNotification) {
            SendNotification()
        }
        #endif

        Reduce { state, action in
            switch action {
            case .delaysTapped:
                return .none
            case let .computationFinished(delay, ratio, durationBeforeStart):
                state.delay = delay
                state.ratio = ratio
                state.durationBeforeStart = durationBeforeStart
                return .none
            #if canImport(NotificationCenter)
            case .sendNotification:
                return .none
            #endif
            case .task:
                return .run { [state] send in
                    let operations = [Operation].nextOperations(
                        periods: periodProvider(),
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
                        periods: periodProvider(),
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
