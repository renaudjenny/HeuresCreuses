import Foundation

public struct UserNotification: Equatable, Identifiable, Hashable, Codable {
    public let id: String
    public let title: String
    public let body: String
    public let creationDate: Date
    public let duration: Duration

    public var triggerDate: Date {
        Date(timeIntervalSince1970: creationDate.timeIntervalSince1970 + Double(duration.components.seconds))
    }

    public init(id: String, title: String, body: String, creationDate: Date, duration: Duration) {
        self.id = id
        self.title = title
        self.body = body
        self.creationDate = creationDate
        self.duration = duration
    }
}
