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

    func testAddProgramButtonTapped() async throws {
        let store = TestStore(initialState: ApplianceForm.State(appliance: .dishwasher)) {
            ApplianceForm()
        } withDependencies: {
            $0.uuid = .incrementing
        }
        let program = Program(id: UUID(0))
        await store.send(.addProgramButtonTapped) {
            $0.appliance.programs.append(program)
            $0.programs.append(ProgramForm.State(program: program))
        }
    }
}
