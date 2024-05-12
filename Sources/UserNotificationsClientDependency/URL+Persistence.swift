import ComposableArchitecture
import Foundation

extension URL {
    static let userNotifications = Self.documentsDirectory.appending(component: "userNotifications.json")
}

extension PersistenceKey where Self == PersistenceKeyDefault<FileStorageKey<[UserNotification]>> {
    static var userNotifications: Self { PersistenceKeyDefault(.fileStorage(.userNotifications), []) }
}
