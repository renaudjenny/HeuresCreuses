import ApplianceFeature
import ComposableArchitecture
import XCTest

@MainActor
final class ApplianceSelectionTests: XCTestCase {
    func testAddAppliance() async throws {
        let store = TestStore(initialState: ApplianceSelection.State()) {
            ApplianceSelection()
        } withDependencies: {
            $0.uuid = .incrementing
        }
        await store.send(.addApplianceButtonTapped) {
            $0.destination = .addAppliance(ApplianceForm.State(appliance: Appliance(id: UUID(0))))
        }
    }

    func testAddApplianceCancel() async throws {
        let store = TestStore(
            initialState: ApplianceSelection.State(
                destination: .addAppliance(ApplianceForm.State(appliance: Appliance(id: UUID(0))))
            )
        ) {
            ApplianceSelection()
        }
        await store.send(.addApplianceCancelButtonTapped) {
            $0.destination = nil
        }
    }
}
