import ComposableArchitecture
import Foundation

extension URL {
    static let periods = Self.documentsDirectory.appending(component: "periods.json")
}

public extension PersistenceKey where Self == PersistenceKeyDefault<FileStorageKey<IdentifiedArrayOf<Period>>> {
    static var periods: Self {
        PersistenceKeyDefault(.fileStorage(.periods), IdentifiedArray(uniqueElements: [Period].example))
    }
}
