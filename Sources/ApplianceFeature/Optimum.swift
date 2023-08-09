import ComposableArchitecture
import Foundation
import NotificationCenter
import UserNotificationsDependency

public struct Optimum: Reducer {
    public struct State: Equatable {
        let program: Program
        let appliance: Appliance
        var delay = Duration.zero
        var ratio: Double = 0
        var durationBeforeStart: Duration = .zero
        var notificationAuthorizationStatus: UNAuthorizationStatus = .notDetermined

        public init(program: Program, appliance: Appliance) {
            self.program = program
            self.appliance = appliance
        }
    }
    public enum Action: Equatable {
        case delaysTapped(Program)
        case computationFinished(delay: Duration, ratio: Double, durationBeforeStart: Duration)
        case remindMeButtonTapped
        case notificationStatusChanged(UNAuthorizationStatus)
        case task
    }

    @Dependency(\.calendar) var calendar
    @Dependency(\.date) var date
    @Dependency(\.periodProvider) var periodProvider
    @Dependency(\.userNotificationCenter) var userNotificationCenter
    @Dependency(\.uuid) var uuid

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
            case .remindMeButtonTapped:
                return .run { send in
                    let notificationSettings = await userNotificationCenter.notificationSettings()
                    let status = notificationSettings.authorizationStatus
                    await send(.notificationStatusChanged(status))

                    if status == .notDetermined {
                        guard try await self.userNotificationCenter.requestAuthorization(options: [.alert])
                        else { return }
                        await send(.notificationStatusChanged(userNotificationCenter.notificationSettings().authorizationStatus))
                    }
                }
            case let .notificationStatusChanged(status):
                state.notificationAuthorizationStatus = status
                if [.authorized, .ephemeral].contains(status) {
                    return .run { [state] _ in
                        let identifier = uuid().uuidString
                        let content = UNMutableNotificationContent()
                        content.title = "Appliance to program"
                        content.body = "\(state.appliance.name)\nProgram \(state.program.name)\nDelay \(state.delay.hourMinute)"
                        let timeInterval = TimeInterval(state.durationBeforeStart.components.seconds)
                        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
                        try await self.userNotificationCenter.add(
                            .init(
                                identifier: identifier,
                                content: content,
                                trigger: trigger
                            )
                        )
                    }
                }
                return .none
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
