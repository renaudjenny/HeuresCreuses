import Combine
import Dependencies
import UserNotificationsDependency

public struct UserNotificationsClient {
    public var notifications: () -> [UserNotification]
    public var stream: () -> AsyncStream<[UserNotification]>
    public var add: (UserNotification) -> Void
    public var remove: (UserNotification) -> Void
}

private final class UserNotificationCombine {
    @Published var notifications: [UserNotification] = []

    init() {
        // TODO: load from JSON
    }

    func add(notification: UserNotification) {
        notifications.append(notification)
        // TODO: add a notification in notification center
        save()
    }

    func remove(notification: UserNotification) {
        notifications.removeAll { notification.id == $0.id }
        // TODO: remove the notification from notification center
        save()
    }

    private func save() {
        // TODO: save to JSON
    }
}

extension UserNotificationsClient: DependencyKey {
    public static let liveValue: UserNotificationsClient = {
        let combine = UserNotificationCombine()
        return UserNotificationsClient(
            notifications: { combine.notifications },
            stream: { combine.$notifications.values.eraseToStream() },
            add: combine.add(notification:),
            remove: combine.remove(notification:)
        )
    }()

    public static var testValue: UserNotificationsClient {
        UserNotificationsClient(
            notifications: unimplemented("UserNotificationClient.notifications"),
            stream: unimplemented("UserNotificationClient.stream"),
            add: unimplemented("UserNotificationClient.add"),
            remove: unimplemented("UserNotificationClient.remove")
        )
    }

    public static var previewValue: UserNotificationsClient {
        return .liveValue
    }
}

public extension DependencyValues {
    var userNotifications: UserNotificationsClient {
        get { self[UserNotificationsClient.self] }
        set { self[UserNotificationsClient.self] = newValue }
    }
}
