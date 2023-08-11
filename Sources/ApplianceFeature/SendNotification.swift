#if canImport(NotificationCenter)
import ComposableArchitecture
import NotificationCenter

public struct SendNotification: Reducer {
    public struct State: Equatable {
        let program: Program
        let appliance: Appliance
        let delay: Duration
        let durationBeforeStart: Duration
        var notificationAuthorizationStatus: UNAuthorizationStatus
    }
    public enum Action: Equatable {
        case remindMeButtonTapped
        case notificationStatusChanged(UNAuthorizationStatus)
    }

    @Dependency(\.userNotificationCenter) var userNotificationCenter
    @Dependency(\.uuid) var uuid

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
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
            }
        }
    }
}
#endif

