import ApplianceFeature
import ComposableArchitecture
import XCTest

@MainActor
final class ApplianceFormTests: XCTestCase {
    func testAddDelayButtonTapped() async throws {
        let store = TestStore(initialState: ApplianceForm.State(appliance: .dishwasher)) {
            ApplianceForm()
        }
        await store.send(.addDelayButtonTapped) {
            $0.appliance.delays.append(.seconds(2 * 60 * 60))
        }
    }
}
