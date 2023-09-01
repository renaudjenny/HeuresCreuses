#if canImport(NotificationCenter)
import ComposableArchitecture
import NotificationCenter
import Models

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
        case delegate(Delegate)
        case notificationStatusChanged(UNAuthorizationStatus)

        public enum Delegate: Equatable {
            case notificationAdded(UserNotification)
        }
    }

    @Dependency(\.date) var date
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
            case .delegate:
                return .none
            case let .notificationStatusChanged(status):
                state.notificationAuthorizationStatus = status
                if [.authorized, .ephemeral].contains(status) {
                    return .run { [state] send in
                        let identifier = uuid().uuidString
                        let content = UNMutableNotificationContent()
                        content.title = "Appliance to program"
                        content.body = """
                        \(state.appliance.name)
                        Program \(state.program.name)
                        Delay \(state.delay.hourMinute)
                        """
                        let timeInterval = TimeInterval(state.durationBeforeStart.components.seconds)
                        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)

                        try await self.userNotificationCenter.add(
                            .init(
                                identifier: identifier,
                                content: content,
                                trigger: trigger
                            )
                        )

                        let date = date().addingTimeInterval(timeInterval)
                        let notification = UserNotification(id: identifier, message: content.body, date: date)
                        await send(.delegate(.notificationAdded(notification)))
                    }
                } else {
                    return .none
                }
            }
        }
    }
}
#endif

