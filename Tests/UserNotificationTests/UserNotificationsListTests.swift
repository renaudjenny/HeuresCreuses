import ComposableArchitecture
import SendNotification
@testable import UserNotification
import UserNotificationsClientDependency
import XCTest

@MainActor
final class UserNotificationsListTests: XCTestCase {
    func testOutdatedNotifications() async throws {
        let dateInThePast = Date().addingTimeInterval(-60 * 60 * 20)
        let notifications: [UserNotification] = [
            UserNotification(
                id: "1234",
                title: "Test",
                body: "Test",
                creationDate: dateInThePast,
                duration: .seconds(5)
            ),
            UserNotification(
                id: "1235",
                title: "Test",
                body: "Test 2",
                creationDate: dateInThePast,
                duration: .seconds(6)
            ),
            UserNotification(
                id: "1236",
                title: "Test",
                body: "Test 3",
                creationDate: Date(),
                duration: .seconds(6)
            ),
        ]
        let store = TestStore(initialState: UserNotificationsList.State()) {
            UserNotificationsList()
        } withDependencies: {
            $0.userNotifications.notifications = { notifications }
            $0.userNotifications.stream = { AsyncStream { continuation in continuation.yield(notifications) } }
        }

        // TODO: fix this test
        let lastNotification = try XCTUnwrap(notifications.last)
        await store.send(.task)
        await store.receive(.notificationsUpdated([lastNotification])) {
            $0.notifications = [lastNotification]
        }
        await store.send(.cancel)
        await store.finish()
    }
}
