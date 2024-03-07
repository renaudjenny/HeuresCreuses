import ApplianceFeature
import ComposableArchitecture
import XCTest

final class ApplianceFormTests: XCTestCase {
    @MainActor
    func testAddDelayButtonTapped() async throws {
        let store = TestStore(initialState: ApplianceForm.State(appliance: .dishwasher)) {
            ApplianceForm()
        }
        await store.send(.addDelayButtonTapped) {
            $0.appliance.delays.append(.seconds(2 * 60 * 60))
        }
    }

    @MainActor
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

    @MainActor
    func testDeleteDelays() async throws {
        let store = TestStore(initialState: ApplianceForm.State(appliance: .dishwasher)) {
            ApplianceForm()
        }
        await store.send(.deleteDelays(IndexSet(integersIn: 0..<1))) {
            $0.appliance.delays.remove(at: 0)
        }
    }

    @MainActor
    func testDeletePrograms() async throws {
        let store = TestStore(initialState: ApplianceForm.State(appliance: .dishwasher)) {
            ApplianceForm()
        }
        await store.send(.deletePrograms(IndexSet(integersIn: 0..<1))) {
            $0.programs.remove(at: 0)
            $0.appliance.programs.remove(at: 0)
        }
    }
}
