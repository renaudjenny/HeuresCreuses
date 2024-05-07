import Dependencies
import Foundation

/// TODO: remove this dependency and start using `@Shared`
public struct DataManager: Sendable {
    public var load: @Sendable (URL) throws -> Data
    public var save: @Sendable (Data, URL) throws -> Void
}

extension DataManager: DependencyKey {
    public static let liveValue = Self(
        load: { url in try Data(contentsOf: url) },
        save: { data, url in try data.write(to: url) }
    )

    public static let previewValue = Self.mock()

    public static func mock(initialData: Data? = nil) -> Self {
      let data = LockIsolated(initialData)
      return Self(
        load: { _ in
          guard let data = data.value
          else {
            struct FileNotFound: Error {}
            throw FileNotFound()
          }
          return data
        },
        save: { newData, _ in data.setValue(newData) }
      )
    }
}

public extension DependencyValues {
    var dataManager: DataManager {
        get { self[DataManager.self] }
        set { self[DataManager.self] = newValue }
    }
}
