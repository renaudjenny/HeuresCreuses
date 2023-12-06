import Combine
import DataManagerDependency
import Dependencies
import Foundation
import NotificationCenter
import UserNotificationsDependency

public struct UserNotificationsClient {
    public var notifications: () -> [UserNotification]
    public var stream: () -> AsyncStream<[UserNotification]>
    public var add: (UserNotification) async throws -> Void
    public var remove: (UserNotification) throws -> Void
}

private final class UserNotificationCombine {
    @Published var notifications: [UserNotification] = []

    @Dependency(\.dataManager.load) private var loadData
    @Dependency(\.userNotificationCenter) private var userNotificationCenter
    @Dependency(\.dataManager.save) private var saveData

    init() {
        notifications = (try? JSONDecoder().decode([UserNotification].self, from: loadData(.userNotifications))) ?? []
    }

    func add(notification: UserNotification) async throws {
        notifications.append(notification)

        let content = UNMutableNotificationContent()
        content.title = notification.title
        content.body = notification.body
        let timeInterval = TimeInterval(notification.duration.components.seconds)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
        try await userNotificationCenter.add(.init(identifier: notification.id, content: content, trigger: trigger))

        try save()
    }

    func remove(notification: UserNotification) throws {
        notifications.removeAll { notification.id == $0.id }
        userNotificationCenter.removePendingNotificationRequests(withIdentifiers: [notification.id])
        try save()
    }

    // TODO: auto remove notifications when they are out of dates?

    private func save() throws {
        try saveData(try JSONEncoder().encode(notifications), .userNotifications)
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

private extension URL {
    static let userNotifications = Self.documentsDirectory.appending(component: "userNotifications.json")
}
