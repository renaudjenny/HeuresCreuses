import ComposableArchitecture
import SendNotification
@testable import UserNotification
import UserNotificationsClientDependency
import XCTest

@MainActor
final class UserNotificationsHomeWidgetTests: XCTestCase {
    func testTask() async throws {
        let testContent = UNMutableNotificationContent()
        testContent.body = "Test body"
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
        await store.send(.cancelTimer)
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
