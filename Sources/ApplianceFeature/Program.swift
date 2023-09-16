import Foundation

public struct Program: Identifiable, Equatable, Hashable {
    public var id: UUID
    public var name: String
    public var duration: Duration

    public init(
        id: UUID,
        name: String = "",
        duration: Duration = .seconds(2 * 60 * 60)
    ) {
        self.id = id
        self.name = name
        self.duration = duration
    }
}
