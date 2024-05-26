import ComposableArchitecture
import Foundation

extension URL {
    static let userNotifications = Self.documentsDirectory.appending(component: "userNotifications.json")
}

public extension PersistenceKey where Self == PersistenceKeyDefault<FileStorageKey<IdentifiedArrayOf<UserNotification>>> {
    static var userNotifications: Self { PersistenceKeyDefault(.fileStorage(.userNotifications), []) }
}
