import AppFeature
import ApplianceFeature
import ComposableArchitecture
import Models
import XCTest

typealias App = AppFeature.App

@MainActor
final class AppFeatureTests: XCTestCase {
    func testTimeChangedAndItIsPeakHour() async throws {
        let calendar = Calendar(identifier: .iso8601)
        let date = Date(timeIntervalSince1970: 12345689)
        let store = TestStore(initialState: App.State()) {
            App()
        } withDependencies: {
            $0.calendar = calendar
            $0.continuousClock = ImmediateClock()
            $0.dataManager = .mock()
            $0.date = .constant(date)
        }
        let offPeakRanges: [ClosedRange<Date>] = .offPeakRanges(store.state.periods, now: date, calendar: calendar)
        let closestOffPeak = try XCTUnwrap(offPeakRanges.first { date.distance(to: $0.lowerBound) > 0 })
        await store.send(.task) {
            $0.offPeakRanges = offPeakRanges
        }
        await store.send(.cancel)
        await store.send(.timeChanged(date)) {
            $0.currentPeakStatus = .peak(until: .seconds(date.distance(to: closestOffPeak.lowerBound)))
        }
        await store.finish()
    }

    func testTimeChangedAndItOffPeakHour() async throws {
        let calendar = Calendar(identifier: .iso8601)
        let date = Date(timeIntervalSince1970: 12345689 + 4 * 60 * 60)
        let store = TestStore(initialState: App.State()) {
            App()
        } withDependencies: {
            $0.calendar = calendar
            $0.continuousClock = ImmediateClock()
            $0.dataManager = .mock()
            $0.date = .constant(date)
        }

        let offPeakRanges: [ClosedRange<Date>] = .offPeakRanges(store.state.periods, now: date, calendar: calendar)
        let currentOffPeak = try XCTUnwrap(offPeakRanges.first { $0.contains(date) })
        await store.send(.task) {
            $0.offPeakRanges = offPeakRanges
        }
        await store.send(.cancel)
        await store.send(.timeChanged(date)) {
            $0.currentPeakStatus = .offPeak(until: .seconds(date.distance(to: currentOffPeak.upperBound)))
        }
        await store.finish()
    }

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
