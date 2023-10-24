import ComposableArchitecture
import SendNotification
import UserNotification
import XCTest

@MainActor
final class UserNotificationsHomeWidgetTests: XCTestCase {
    // TODO: replace this test with just the one for `task` and wait for its result
    func testNotificationsUpdated() async throws {
        let store = TestStore(initialState: UserNotificationHomeWidget.State()) {
            UserNotificationHomeWidget()
        } withDependencies: {
            $0.date = .constant(Date(timeIntervalSince1970: 0))
        }

        let testContent = UNMutableNotificationContent()
        testContent.body = "Test body"
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 123456789, repeats: false)
        let notification = UNNotificationRequest(
            identifier: "1234",
            content: testContent,
            trigger: trigger
        )

        await store.send(.notificationsUpdated([notification])) {
            $0.notifications = [
                UserNotification(
                    id: "1234",
                    message: "Test body",
                    date: Date(timeIntervalSince1970: 0).addingTimeInterval(123456789)
                )
            ]
        }
    }
}
