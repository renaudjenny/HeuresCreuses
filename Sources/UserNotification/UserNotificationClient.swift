import Combine
import SendNotification
import UserNotificationsDependency

struct UserNotificationClient {
    var notifications: AsyncStream<[UserNotification]>
    var add: (UserNotification) -> Void
    var remove: (UserNotification) -> Void
}

private final class UserNotificationCombine {
    @Published var notifications: [UserNotification] = []

    init() {
        // TODO: load from JSON
    }

    func add(notification: UserNotification) {
        notifications.append(notification)
        save()
    }

    func remove(notification: UserNotification) {
        notifications.removeAll { notification.id == $0.id }
        save()
    }

    private func save() {
        // TODO: save to JSON
    }
}
