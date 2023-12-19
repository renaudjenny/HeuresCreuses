import ComposableArchitecture
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
        let lastNotification = try XCTUnwrap(notifications.last)

        let removalExpectation = expectation(description: "Remove old notifications")
        let store = TestStore(initialState: UserNotificationsList.State()) {
            UserNotificationsList()
        } withDependencies: {
            $0.continuousClock = TestClock()
            $0.date = .constant(.now)
            $0.userNotifications.notifications = { notifications }
            $0.userNotifications.stream = { AsyncStream { continuation in continuation.yield([lastNotification]) } }
            $0.userNotifications.remove = {
                XCTAssertEqual(["1234", "1235"], $0)
                removalExpectation.fulfill()
            }
        }

        await store.send(.task)
        await store.receive(.notificationsUpdated([lastNotification])) {
            $0.notifications = [lastNotification]
        }
        await fulfillment(of: [removalExpectation], timeout: 0.1)
        await store.send(.cancel)
        await store.finish()
    }
}
