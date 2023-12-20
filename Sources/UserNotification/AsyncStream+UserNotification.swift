#if DEBUG
import Foundation
import UserNotificationsClientDependency

public extension AsyncStream where Element == [UserNotification] {
    static let example: Self = AsyncStream { continuation in
        continuation.yield([
            UserNotification(
                id: "1234",
                title: "White Dishwasher",
                body: "White Dishwasher\nProgram Eco\nDelay 3 hour",
                creationDate: Date.now.addingTimeInterval(-50),
                duration: .seconds(60)
            ),
            UserNotification(
                id: "1235",
                title: "Gray Washing machine",
                body: "Gray Washing machine\nProgram Intense\nDelay 4 hours",
                creationDate: Date.now.addingTimeInterval(-123),
                duration: .seconds(500)
            )
        ])
    }
}
#endif
