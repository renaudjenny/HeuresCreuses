import AppFeature
import ApplianceFeature
import ComposableArchitecture
import Models
import XCTest

typealias App = AppFeature.App

@MainActor
final class AppFeatureTests: XCTestCase {
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
