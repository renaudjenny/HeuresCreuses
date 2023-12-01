import Foundation

public struct UserNotification: Equatable, Identifiable, Hashable, Codable {
    public let id: String
    public let message: String
    public let date: Date

    public init(id: String, message: String, date: Date) {
        self.id = id
        self.message = message
        self.date = date
    }
}
