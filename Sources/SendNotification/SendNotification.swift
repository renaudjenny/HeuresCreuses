#if canImport(NotificationCenter)
import ComposableArchitecture
import NotificationCenter
import Models
import UserNotificationsDependency

public struct SendNotification: Reducer {
    public struct State: Equatable {
        var intent: Intent?
        var notificationAuthorizationStatus: UNAuthorizationStatus = .notDetermined

        public init(intent: Intent? = nil) {
            self.intent = intent
        }
    }

    public enum Action: Equatable {
        case buttonTapped(Intent?)
        case delegate(Delegate)
        case notificationStatusChanged(UNAuthorizationStatus)

        public enum Delegate: Equatable {
            case notificationAdded(UserNotification)
        }
    }

    public enum Intent: Equatable {
        case applianceToProgram(body: String, delay: Duration, durationBeforeStart: Duration)
        case offPeakStart(durationBeforeOffPeak: Duration)
    }

    @Dependency(\.date) var date
    @Dependency(\.userNotificationCenter) var userNotificationCenter
    @Dependency(\.uuid) var uuid

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .buttonTapped(intent):
                state.intent = intent
                return checkAuthorization()
            case .delegate:
                return .none
            case let .notificationStatusChanged(status):
                state.notificationAuthorizationStatus = status
                guard  [.authorized, .ephemeral].contains(status) else { return .none }
                switch state.intent {
                case let .applianceToProgram(body, delay, durationBeforeStart):
                    return sendApplianceToProgramNotification(
                        body: body,
                        delay: delay,
                        durationBeforeStart: durationBeforeStart
                    )
                case let .offPeakStart(durationBeforeOffPeak):
                    return sendOffPeakStartNotification(durationBeforeOffPeak: durationBeforeOffPeak)
                case .none:
                    // TODO: log an error?
                    return .none
                }
            }
        }
    }

    private func checkAuthorization() -> Effect<Action> {
        .run { send in
            let notificationSettings = await userNotificationCenter.notificationSettings()
            let status = notificationSettings.authorizationStatus
            await send(.notificationStatusChanged(status))

            if status == .notDetermined {
                guard try await self.userNotificationCenter.requestAuthorization(options: [.alert])
                else { return }
                await send(.notificationStatusChanged(userNotificationCenter.notificationSettings().authorizationStatus))
            }
        }
    }

    private func sendApplianceToProgramNotification(
        body: String,
        delay: Duration,
        durationBeforeStart: Duration
    ) -> Effect<Action> {
        .run { send in
            let identifier = uuid().uuidString
            let content = UNMutableNotificationContent()
            content.title = "Appliance to program"
            content.body = body
            let timeInterval = TimeInterval(durationBeforeStart.components.seconds)
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
    }

    private func sendOffPeakStartNotification(durationBeforeOffPeak: Duration) -> Effect<Action> {
        .run { send in
            let identifier = "com.renaudjenny.heures-creuses.notification.next-off-peak"
            let requests = await userNotificationCenter.pendingNotificationRequests()
            guard !requests.contains(where: { $0.identifier == identifier }) else { return }

            let content = UNMutableNotificationContent()
            content.title = "Off peak period is starting"
            content.body = "Optimise your electricity bill by starting your appliance now."
            let timeInterval = TimeInterval(durationBeforeOffPeak.components.seconds)
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
    }
}
#else
import ComposableArchitecture
public typealias SendNotification = EmptyReducer
#endif
