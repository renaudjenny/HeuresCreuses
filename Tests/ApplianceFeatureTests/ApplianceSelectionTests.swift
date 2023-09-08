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

    func testAddApplianceSave() async throws {
        var appliance = Appliance(id: UUID(0))
        let store = TestStore(
            initialState: ApplianceSelection.State(
                destination: .addAppliance(ApplianceForm.State(appliance: appliance))
            )
        ) {
            ApplianceSelection()
        }
        appliance.name = "Test appliance"
        await store.send(.destination(.presented(.addAppliance(.set(\.$appliance, appliance))))) {
            $0.destination = .addAppliance(ApplianceForm.State(appliance: appliance))
        }

        await store.send(.addApplianceSaveButtonTapped) {
            $0.appliances.append(appliance)
            $0.destination = nil
        }
    }

    func testApplianceNavigation() async throws {
        let appliance = Appliance(id: UUID(0))
        func testAddApplianceCancel() async throws {
            let store = TestStore(
                initialState: ApplianceSelection.State(
                    appliances: [appliance]
                )
            ) {
                ApplianceSelection()
            }
            await store.send(.applianceTapped(appliance)) {
                $0.destination = .selection(ProgramSelection.State(appliance: appliance))
            }
        }
    }

    func testUpdateAppliance() async throws {
        var appliance = Appliance(id: UUID(0))
        let store = TestStore(
            initialState: ApplianceSelection.State(
                appliances: [appliance],
                destination: .selection(ProgramSelection.State(
                    appliance: appliance,
                    destination: .edit(ApplianceForm.State(appliance: appliance))
                ))
            )
        ) {
            ApplianceSelection()
        } withDependencies: {
            $0.uuid = .incrementing
        }
        appliance.name = "Updated appliance name"
        await store.send(.destination(.presented(.selection(.delegate(.applianceUpdated(appliance)))))) {
            $0.appliances[id: appliance.id] = appliance
        }
    }

    func testDeletateAppliance() async throws {
        let appliance = Appliance(id: UUID(0))
        let store = TestStore(
            initialState: ApplianceSelection.State(
                appliances: [appliance],
                destination: .selection(ProgramSelection.State(
                    appliance: appliance,
                    destination: .edit(ApplianceForm.State(appliance: appliance))
                ))
            )
        ) {
            ApplianceSelection()
        } withDependencies: {
            $0.uuid = .incrementing
        }
        await store.send(.destination(.presented(.selection(.delegate(.deleteAppliance(id: appliance.id)))))) {
            $0.appliances.remove(appliance)
        }
    }
}
