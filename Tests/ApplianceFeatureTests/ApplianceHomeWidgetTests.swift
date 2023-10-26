import ApplianceFeature
import ComposableArchitecture
import XCTest

@MainActor
final class ApplianceHomeWidgetTests: XCTestCase {
    func testNavigationToSelection() async throws {
        let appliances: IdentifiedArrayOf<Appliance> = [.dishwasher, .washingMachine]

        let store = TestStore(initialState: ApplianceHomeWidget.State(appliances: appliances)) {
            ApplianceHomeWidget()
        }

        await store.send(.widgetTapped) {
            $0.destination = ApplianceSelection.State(appliances: appliances)
        }
    }

    func testSaveOnApplianceModification() {
        // TODO
    }
}
