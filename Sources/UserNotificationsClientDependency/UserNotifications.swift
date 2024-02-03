import Combine
import ComposableArchitecture
import DataManagerDependency
import Dependencies
import Foundation
#if canImport(NotificationCenter)
import NotificationCenter
#endif
import UserNotificationsDependency

public struct UserNotificationsClient {
    public var notifications: () -> [UserNotification]
    public var stream: () -> AsyncStream<[UserNotification]>
    public var add: (UserNotification) async throws -> Void
    public var remove: ([UserNotification.ID]) async throws -> Void
    public var authorizationStatus: () async throws -> UserNotificationAuthorizationStatus
    public var checkAuthorization: () async throws -> UserNotificationAuthorizationStatus
}

private final class UserNotificationCombine {
    @Published var notifications: [UserNotification] = []

    @Dependency(\.continuousClock) var clock
    @Dependency(\.dataManager.load) private var loadData
    @Dependency(\.userNotificationCenter) private var userNotificationCenter
    @Dependency(\.dataManager.save) private var saveData

    init() {
        notifications = (try? JSONDecoder().decode([UserNotification].self, from: loadData(.userNotifications))) ?? []
    }

    func add(notification: UserNotification) async throws {
        try await remove(ids: [notification.id])
        notifications.append(notification)

        #if canImport(NotificationCenter) && os(iOS)
        let content = UNMutableNotificationContent()
        content.title = notification.title
        content.body = notification.body
        let timeInterval = TimeInterval(notification.duration.components.seconds)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
        try await userNotificationCenter.add(.init(identifier: notification.id, content: content, trigger: trigger))
        #endif

        try await save()
    }

    func remove(ids: [UserNotification.ID]) async throws {
        notifications.removeAll { ids.contains($0.id) }
        userNotificationCenter.removePendingNotificationRequests(withIdentifiers: ids)
        try await save()
    }

    private func save() async throws {
        enum CancelID { case saveDebounce }
        try await withTaskCancellation(id: CancelID.saveDebounce, cancelInFlight: true) { [self] in
            try await clock.sleep(for: .seconds(1))
            try saveData(try JSONEncoder().encode(notifications), .userNotifications)
        }
    }

    func checkAuthorization() async throws -> UserNotificationAuthorizationStatus {
        let notificationSettings = await userNotificationCenter.notificationSettings()
        if notificationSettings.authorizationStatus == .notDetermined {
            guard try await self.userNotificationCenter.requestAuthorization(options: [.alert])
            else { return .unavailable }
            return await authorizationStatus(userNotificationCenter.notificationSettings().authorizationStatus)
        } else {
            return authorizationStatus(notificationSettings.authorizationStatus)
        }
    }

    private func authorizationStatus(_ authorizationStatus: UNAuthorizationStatus) -> UserNotificationAuthorizationStatus {
        switch authorizationStatus {
        case .authorized: .authorized
        case .denied: .denied
        case .ephemeral: .ephemeral
        case .provisional: .provisional
        case .notDetermined: .notDetermined
        @unknown default: .unavailable
        }
    }
}

extension UserNotificationsClient: DependencyKey {
    public static let liveValue: UserNotificationsClient = {
        let combine = UserNotificationCombine()
        return UserNotificationsClient(
            notifications: { combine.notifications },
            stream: { combine.$notifications.values.eraseToStream() },
            add: combine.add(notification:),
            remove: combine.remove(ids:),
            authorizationStatus: unimplemented("UserNotificationClient.authorizationStatus"),
            checkAuthorization: unimplemented("UserNotificationClient.checkAuthorization")
        )
    }()

    public static var testValue: UserNotificationsClient {
        UserNotificationsClient(
            notifications: unimplemented("UserNotificationClient.notifications"),
            stream: unimplemented("UserNotificationClient.stream"),
            add: unimplemented("UserNotificationClient.add"),
            remove: unimplemented("UserNotificationClient.remove"),
            authorizationStatus: unimplemented("UserNotificationClient.authorizationStatus"),
            checkAuthorization: unimplemented("UserNotificationClient.checkAuthorization")
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
