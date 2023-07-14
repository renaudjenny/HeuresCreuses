import Foundation

public struct Program: Identifiable, Equatable {
    public var id: UUID
    public var name: String
    public var duration: TimeInterval
}
