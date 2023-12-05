import Foundation

public struct UserNotification: Equatable, Identifiable, Hashable, Codable {
    public let id: String
    // TODO: remove message
    public let message: String
    public let title: String
    public let body: String
    public let creationDate: Date
    public let duration: Duration

    public var triggerDate: Date {
        Date(timeIntervalSince1970: creationDate.timeIntervalSince1970 + Double(duration.components.seconds))
    }

    // TODO: remove this init
    public init(id: String, message: String, date: Date) {
        self.id = id
        self.message = message
        self.creationDate = date
        self.duration = .zero

        self.title = ""
        self.body = ""
    }

    public init(id: String, title: String, body: String, creationDate: Date, duration: Duration) {
        self.id = id
        self.message = ""
        self.title = title
        self.body = body
        self.creationDate = creationDate
        self.duration = duration
    }
}
