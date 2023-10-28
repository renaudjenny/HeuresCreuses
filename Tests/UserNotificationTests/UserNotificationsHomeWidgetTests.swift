import ComposableArchitecture
import SendNotification
@testable import UserNotification
import XCTest

@MainActor
final class UserNotificationsHomeWidgetTests: XCTestCase {
    func testTask() async throws {
        let testContent = UNMutableNotificationContent()
        testContent.body = "Test body"
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 123456789, repeats: false)
        let notification = UNNotificationRequest(
            identifier: "1234",
            content: testContent,
            trigger: trigger
        )

        let store = TestStore(initialState: UserNotificationHomeWidget.State()) {
            UserNotificationHomeWidget()
        } withDependencies: {
            $0.date = .constant(Date(timeIntervalSince1970: 0))
            $0.userNotificationCenter.$pendingNotificationRequests = { @Sendable in
                [notification]
            }
            $0.continuousClock = TestClock()
        }

        await store.send(.task)
        await store.receive(.notificationsUpdated([notification])) {
            $0.notifications = [
                UserNotification(
                    id: "1234",
                    message: "Test body",
                    date: Date(timeIntervalSince1970: 0).addingTimeInterval(123456789)
                )
            ]
        }
        await store.send(.cancelTimer)
        await store.finish()
    }

    func testNavigatingToList() async throws {
        let notifications: IdentifiedArrayOf<UserNotification> = [
            UserNotification(id: "1234", message: "Test", date: Date()),
            UserNotification(id: "1235", message: "Test 2", date: Date())
        ]
        let store = TestStore(initialState: UserNotificationHomeWidget.State(notifications: notifications.elements)) {
            UserNotificationHomeWidget()
        }

        await store.send(.widgetTapped) {
            $0.destination = UserNotificationsList.State(notifications: notifications)
        }
    }
}