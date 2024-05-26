#if canImport(NotificationCenter) && os(iOS)
import ComposableArchitecture
import Models
import UserNotificationsClientDependency

@Reducer
public struct SendNotification {
    @ObservableState
    public struct State: Equatable {
        public var intent: Intent?
        @Shared(.userNotifications) var userNotifications: IdentifiedArrayOf<UserNotification>
        var notificationAuthorizationStatus: UserNotificationAuthorizationStatus = .notDetermined
        var userNotificationStatus: UserNotificationStatus = .loading

        public init(intent: Intent? = nil, userNotifications: IdentifiedArrayOf<UserNotification> = []) {
            self.intent = intent
            self._userNotifications = Shared(wrappedValue: userNotifications, .userNotifications)
        }
    }

    public enum Action: Equatable {
        case buttonTapped(Intent?)
        case notificationStatusChanged(UserNotificationAuthorizationStatus)
        case updateUserNotificationStatus(
            UserNotificationStatus,
            authorizationStatus: UserNotificationAuthorizationStatus
        )
        case task
    }

    public enum Intent: Equatable {
        case applianceToProgram(body: String, delay: Duration, durationBeforeStart: Duration)
        case offPeakStart(durationBeforeOffPeak: Duration)
        case offPeakEnd(durationBeforePeak: Duration)
    }

    public enum UserNotificationStatus {
        case loading
        case notSent
        case alreadySent
    }

    @Dependency(\.date) var date
    @Dependency(\.userNotificationCenter) var userNotificationCenter
    @Dependency(\.userNotifications) var userNotifications
    @Dependency(\.uuid) var uuid

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .buttonTapped(intent):
                state.intent = intent
                return .run { send in
                    let authorization = try await userNotifications.checkAuthorization()
                    await send(.notificationStatusChanged(authorization))
                }

            case let .notificationStatusChanged(status):
                state.notificationAuthorizationStatus = status
                guard ![.denied, .notDetermined].contains(status) else { return .none }
                state.userNotificationStatus = .alreadySent
                switch state.intent {
                case let .applianceToProgram(body, delay, durationBeforeStart):
                    return sendApplianceToProgramNotification(
                        body: body,
                        delay: delay,
                        durationBeforeStart: durationBeforeStart
                    )
                case let .offPeakStart(durationBeforeOffPeak):
                    return sendOffPeakStartNotification(durationBeforeOffPeak: durationBeforeOffPeak)
                case let .offPeakEnd(durationBeforePeak):
                    return sendOffPeakEndNotification(durationBeforePeak: durationBeforePeak)
                case .none:
                    // TODO: log an error?
                    return .none
                }

            case let .updateUserNotificationStatus(userNotificationStatus, authorizationStatus):
                state.userNotificationStatus = userNotificationStatus
                state.notificationAuthorizationStatus = authorizationStatus
                return .none

            case .task:
                return .run { [state] send in
                    let status: UserNotificationStatus
                    switch state.intent {
                    case .applianceToProgram:
                        // TODO: also sent an ID from the callsite, so we can avoid reprogramming the same notification
                        status = .notSent

                    case .offPeakStart:
                        status = state.userNotifications
                            .contains { $0.id == .nextOffPeakIdentifier } ? .alreadySent : .notSent

                    case .offPeakEnd:
                        status = state.userNotifications
                            .contains { $0.id == .offPeakEndIdentifier } ? .alreadySent : .notSent

                    case .none:
                        status = .notSent
                    }

                    let authorizationStatus = await userNotifications.authorizationStatus()
                    await send(.updateUserNotificationStatus(status, authorizationStatus: authorizationStatus))
                }
            }
        }
    }

    private func sendApplianceToProgramNotification(
        body: String,
        delay: Duration,
        durationBeforeStart: Duration
    ) -> Effect<Action> {
        .run { _ in
            // TODO: ideally the id shouldn't be a uuid but deterministic so we can know if the notification has already been programmed
            try await userNotifications.add(UserNotification(
                id: uuid().uuidString,
                title: String(localized: "Appliance to program"),
                body: body,
                creationDate: date.now,
                duration: durationBeforeStart
            ))
        }
    }

    private func sendOffPeakStartNotification(durationBeforeOffPeak: Duration) -> Effect<Action> {
        .run { _ in
            try await userNotifications.add(UserNotification(
                id: .nextOffPeakIdentifier,
                title: String(localized: "Off peak period is starting"),
                body: String(localized: "Optimise your electricity bill by starting your appliance now."),
                creationDate: date.now,
                duration: durationBeforeOffPeak
            ))
        }
    }

    private func sendOffPeakEndNotification(durationBeforePeak: Duration) -> Effect<Action> {
        .run { _ in
            try await userNotifications.add(UserNotification(
                id: .offPeakEndIdentifier,
                title: String(localized: "Off peak period is ending"),
                body: String(localized: "If some of your consuming devices are still, it's time to shut them down."),
                creationDate: date.now,
                duration: durationBeforePeak
            ))
        }
    }
}

private extension String {
    static let nextOffPeakIdentifier = "com.renaudjenny.heures-creuses.notification.next-off-peak"
    static let offPeakEndIdentifier = "com.renaudjenny.heures-creuses.notification.off-peak-end"
}
#else
import ComposableArchitecture

@Reducer
public struct SendNotification {
    public struct State: Equatable {
        public var intent: Intent?

        public init(intent: Intent? = nil) {
            self.intent = intent
        }
    }

    public enum Intent: Equatable {
        case applianceToProgram(body: String, delay: Duration, durationBeforeStart: Duration)
        case offPeakStart(durationBeforeOffPeak: Duration)
        case offPeakEnd(durationBeforePeak: Duration)
    }

    public enum Action: Equatable {}

    public init() {}

    public var body: some ReducerOf<Self> {
        EmptyReducer()
    }
}
#endif
