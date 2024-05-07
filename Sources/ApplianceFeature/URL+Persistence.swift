import ComposableArchitecture
import Foundation

extension URL {
    static let appliances = Self.documentsDirectory.appending(component: "appliances.json")
}

extension PersistenceKey where Self == PersistenceKeyDefault<FileStorageKey<IdentifiedArrayOf<Appliance>>> {
    static var appliances: Self { PersistenceKeyDefault(.fileStorage(.appliances), [.washingMachine, .dishwasher]) }
}
