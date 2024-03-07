import ApplianceFeature
import ComposableArchitecture
import XCTest

final class ApplianceHomeWidgetTests: XCTestCase {
    @MainActor
    func testNavigationToSelection() async throws {
        let appliances: IdentifiedArrayOf<Appliance> = [.dishwasher, .washingMachine]

        let store = TestStore(initialState: ApplianceHomeWidget.State(appliances: appliances)) {
            ApplianceHomeWidget()
        } withDependencies: {
            $0.continuousClock = ImmediateClock()
            $0.dataManager.save = { _, _ in }
        }

        await store.send(.widgetTapped) {
            $0.destination = ApplianceSelection.State(appliances: appliances)
        }
        await store.finish()
    }

    @MainActor
    func testSaveOnApplianceModification() async throws {
        let saveExpectation = expectation(description: "Save to be called")
        var appliance = Appliance(id: UUID(0))

        let store = TestStore(
            initialState: ApplianceHomeWidget.State(
                destination: ApplianceSelection.State(
                    destination: .addAppliance(ApplianceForm.State(appliance: appliance))
                )
            )
        ) {
            ApplianceHomeWidget()
        } withDependencies: {
            $0.continuousClock = ImmediateClock()
            $0.dataManager.save = { _, _ in saveExpectation.fulfill() }
        }

        appliance.name = "Test appliance"

        await store.send(
            .destination(.presented(.destination(.presented(.addAppliance(.binding(.set(\.appliance, appliance)))))))
        ) {
            $0.destination = ApplianceSelection.State(
                destination: .addAppliance(ApplianceForm.State(appliance: appliance))
            )
        }
        await fulfillment(of: [saveExpectation])
        await store.finish()
    }

    @MainActor
    func testTask() async throws {
        let savedAppliances: IdentifiedArrayOf<Appliance> = [
            .dishwasher,
            .washingMachine,
            Appliance(
                id: UUID(),
                name: "Test",
                type: .dishWasher,
                programs: [Program(id: UUID(), duration: .seconds(120 * 60))],
                delays: [.seconds(2 * 60 * 60), .seconds(4 * 60 * 60)]
            )
        ]
        let store = TestStore(initialState: ApplianceHomeWidget.State()) {
            ApplianceHomeWidget()
        } withDependencies: {
            $0.continuousClock = ImmediateClock()
            $0.dataManager.load = { _ in try JSONEncoder().encode(savedAppliances) }
        }

        await store.send(.task) {
            $0.appliances = savedAppliances
        }
        await store.finish()
    }
}
