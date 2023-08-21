import Foundation

public struct Program: Identifiable, Equatable, Hashable {
    public var id: UUID
    public var name: String = ""
    public var duration: Duration = .zero
}
