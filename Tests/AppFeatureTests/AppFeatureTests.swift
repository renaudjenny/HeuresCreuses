import AppFeature
import ApplianceFeature
import ComposableArchitecture
import Models
import XCTest

typealias App = AppFeature.App

@MainActor
final class AppFeatureTests: XCTestCase {
    func testNotificationHasBeenSet() async throws {
        let appliance = Appliance.dishwasher
        let program = try XCTUnwrap(appliance.programs.first)
        let store = TestStore(
            initialState: App.State(
                destination: .applianceSelection(ApplianceSelection.State(
                    destination: .selection(ProgramSelection.State(
                        appliance: appliance,
                        destination: .optimum(Optimum.State(
                            program: program,
                            appliance: appliance
                        ))
                    ))
                ))
            )
        ) {
            App()
        } withDependencies: {
            $0.continuousClock = ImmediateClock()
            $0.dataManager = .mock()
        }
        let notification = UserNotification(id: "1234", message: "Test notification", date: .now)
        await store.send(.destination(.presented(
            .applianceSelection(.destination(.presented(
                .selection(.destination(.presented(
                    .optimum(.sendNotification(.delegate(.notificationAdded(notification))))
                )))
            )))
        ))) {
            $0.notifications.append(notification)
        }
        await store.finish()
    }

    func testDeleteNotification() async throws {
        let notification = UserNotification(id: "1234", message: "Test notification", date: .now)
        let store = TestStore(
            initialState: App.State(
                notifications: [notification]
            )
        ) {
            App()
        } withDependencies: {
            $0.continuousClock = ImmediateClock()
            $0.dataManager = .mock()
            $0.userNotificationCenter.$removePendingNotificationRequests = { @Sendable ids in
                XCTAssertEqual(ids, ["1234"])
            }
        }
        await store.send(.deleteNotifications(IndexSet(integer: 0))) {
            $0.notifications.remove(at: 0)
        }
        await store.finish()
    }

    func testNavigateToApplianceSelection() async throws {
        let store = TestStore(initialState: App.State()) {
            App()
        } withDependencies: {
            $0.continuousClock = ImmediateClock()
            $0.dataManager = .mock()
        }
        await store.send(.appliancesButtonTapped) {
            $0.destination = .applianceSelection(ApplianceSelection.State())
        }
        await store.finish()
    }
}
