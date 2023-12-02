import Foundation

public struct UserNotification: Equatable, Identifiable, Hashable, Codable {
    public let id: String
    // TODO: remove message
    public let message: String
    public let title: String
    public let body: String
    public let date: Date

    // TODO: remove this init
    public init(id: String, message: String, date: Date) {
        self.id = id
        self.message = message
        self.date = date

        self.title = ""
        self.body = ""
    }

    public init(id: String, title: String, body: String, date: Date) {
        self.id = id
        self.message = ""
        self.title = title
        self.body = body
        self.date = date
    }
}
