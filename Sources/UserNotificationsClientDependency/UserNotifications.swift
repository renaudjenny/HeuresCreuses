import ComposableArchitecture
import Dependencies
import Foundation
#if canImport(NotificationCenter)
import NotificationCenter
#endif
import UserNotificationsDependency

public struct UserNotificationsClient {
    public var add: (UserNotification) async throws -> Void
    public var remove: ([UserNotification.ID]) async throws -> Void
    public var checkAuthorization: () async throws -> UserNotificationAuthorizationStatus
    public var authorizationStatus: () async -> UserNotificationAuthorizationStatus
}

private final class SharedUserNotifications {
    @Shared(.userNotifications) var notifications: IdentifiedArrayOf<UserNotification> = []

    @Dependency(\.continuousClock) var clock
    @Dependency(\.userNotificationCenter) private var userNotificationCenter

    func add(notification: UserNotification) async throws {
        try await remove(ids: [notification.id])

        #if canImport(NotificationCenter) && os(iOS)
        let content = UNMutableNotificationContent()
        content.title = notification.title
        content.body = notification.body
        let timeInterval = TimeInterval(notification.duration.components.seconds)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
        try await userNotificationCenter.add(.init(identifier: notification.id, content: content, trigger: trigger))
        #endif
    }

    func remove(ids: [UserNotification.ID]) async throws {
        userNotificationCenter.removePendingNotificationRequests(withIdentifiers: ids)
    }

    func checkAuthorization() async throws -> UserNotificationAuthorizationStatus {
        #if canImport(NotificationCenter)
        let notificationSettings = await userNotificationCenter.notificationSettings()
        if notificationSettings.authorizationStatus == .notDetermined {
            guard try await self.userNotificationCenter.requestAuthorization(options: [.alert])
            else { return .unavailable }
            return await userNotificationCenter.notificationSettings()
                .authorizationStatus.userNotificationAuthorizationStatus
        } else {
            return notificationSettings.authorizationStatus.userNotificationAuthorizationStatus
        }
        #else
        return .unavailable
        #endif
    }

    func authorizationStatus() async -> UserNotificationAuthorizationStatus {
        #if canImport(NotificationCenter)
        await userNotificationCenter.notificationSettings().authorizationStatus.userNotificationAuthorizationStatus
        #else
        return .unavailable
        #endif
    }
}

extension UserNotificationsClient: DependencyKey {
    public static let liveValue: UserNotificationsClient = {
        let shared = SharedUserNotifications()
        return UserNotificationsClient(
            add: shared.add(notification:),
            remove: shared.remove(ids:),
            checkAuthorization: shared.checkAuthorization,
            authorizationStatus: shared.authorizationStatus
        )
    }()

    public static var testValue: UserNotificationsClient {
        UserNotificationsClient(
            add: unimplemented("UserNotificationClient.add"),
            remove: unimplemented("UserNotificationClient.remove"),
            checkAuthorization: unimplemented("UserNotificationClient.checkAuthorization"),
            authorizationStatus: unimplemented("UserNotificationClient.authorizationStatus")
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

#if canImport(NotificationCenter)
private extension UNAuthorizationStatus {
    var userNotificationAuthorizationStatus: UserNotificationAuthorizationStatus {
        switch self {
        case .authorized: .authorized
        case .denied: .denied
        case .ephemeral: .ephemeral
        case .provisional: .provisional
        case .notDetermined: .notDetermined
        @unknown default: .unavailable
        }
    }
}
#endif
