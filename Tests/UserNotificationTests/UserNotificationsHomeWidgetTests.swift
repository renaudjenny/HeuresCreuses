import ComposableArchitecture
import SendNotification
@testable import UserNotification
import UserNotificationsClientDependency
import XCTest

@MainActor
final class UserNotificationsHomeWidgetTests: XCTestCase {
    func testTask() async throws {
        let notification = UserNotification(
            id: "1234",
            title: "Test title",
            body: "Test body",
            creationDate: Date(timeIntervalSince1970: 0).addingTimeInterval(123456789),
            duration: .seconds(500)
        )

        let store = TestStore(initialState: UserNotificationHomeWidget.State()) {
            UserNotificationHomeWidget()
        } withDependencies: {
            $0.date = .constant(Date(timeIntervalSince1970: 0))
            $0.userNotifications.notifications = { [] }
            $0.userNotifications.stream = { AsyncStream { continuation in continuation.yield([notification]) } }
            $0.continuousClock = TestClock()
        }

        await store.send(.task)
        await store.receive(.notificationsUpdated([notification])) {
            $0.notifications = [notification]
        }
        await store.send(.cancel)
        await store.finish()
    }

    func testTaskWithOutdatedNotifications() async throws {
        let dateInThePast = Date().addingTimeInterval(-60 * 60 * 20)
        let notifications = [
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
        let store = TestStore(initialState: UserNotificationHomeWidget.State()) {
            UserNotificationHomeWidget()
        } withDependencies: {
            $0.date = .constant(.now)
            $0.userNotifications.notifications = { notifications }
            $0.userNotifications.stream = { AsyncStream { continuation in continuation.yield([lastNotification]) } }
            $0.userNotifications.remove = {
                XCTAssertEqual(["1234", "1235"], $0)
                removalExpectation.fulfill()
            }
            $0.continuousClock = TestClock()
        }

        await store.send(.task)
        await store.receive(.notificationsUpdated([lastNotification])) {
            $0.notifications = [lastNotification]
        }
        await fulfillment(of: [removalExpectation], timeout: 0.1)
        await store.send(.cancel)
        await store.finish()
    }

    func testNavigatingToList() async throws {
        let notifications: IdentifiedArrayOf<UserNotification> = [
            UserNotification(id: "1234", title: "Test", body: "Test", creationDate: Date(), duration: .zero),
            UserNotification(id: "1235", title: "Test", body: "Test 2", creationDate: Date(), duration: .zero)
        ]
        let store = TestStore(initialState: UserNotificationHomeWidget.State(notifications: notifications.elements)) {
            UserNotificationHomeWidget()
        }

        await store.send(.widgetTapped) {
            $0.destination = UserNotificationsList.State(notifications: notifications)
        }
    }
}
