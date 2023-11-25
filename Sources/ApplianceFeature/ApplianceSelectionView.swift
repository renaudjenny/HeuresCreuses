import ComposableArchitecture
import SwiftUI

public struct ApplianceSelectionView: View {
    let store: StoreOf<ApplianceSelection>

    struct ViewState: Equatable {
        let appliances: IdentifiedArrayOf<Appliance>

        init(_ state: ApplianceSelection.State) {
            self.appliances = state.appliances
        }
    }

    public init(store: StoreOf<ApplianceSelection>) {
        self.store = store
    }

    public var body: some View {
        WithViewStore(store, observe: ViewState.init) { viewStore in
            List {
                ForEach(viewStore.appliances) { appliance in
                    Button { viewStore.send(.applianceTapped(appliance)) } label: {
                        Label(appliance.name, systemImage: appliance.systemImage)
                    }
                }
                .navigationDestination(
                    store: store.scope(state: \.$destination, action: { .destination($0) }),
                    state: \.selection,
                    action: { .selection($0) },
                    destination: ProgramSelectionView.init
                )
                #if os(iOS) || os(macOS)
                .sheet(
                    store: store.scope(state: \.$destination, action: { .destination($0) }),
                    state: \.addAppliance,
                    action: { .addAppliance($0) }) { store in
                        NavigationStack {
                            ApplianceFormView(store: store)
                                .navigationTitle("New appliance")
                                .toolbar {
                                    ToolbarItem {
                                        Button { viewStore.send(.addApplianceSaveButtonTapped) } label: {
                                            Text("Save")
                                        }
                                    }
                                    ToolbarItem(placement: .cancellationAction) {
                                        Button { viewStore.send(.addApplianceCancelButtonTapped) } label: {
                                            Text("Cancel")
                                        }
                                    }
                                }
                        }
                    }
                #endif
            }
            .navigationTitle("Choose your appliance")
            #if os(iOS) || os(macOS)
            .toolbar {
                ToolbarItem {
                    Button { viewStore.send(.addApplianceButtonTapped) } label: {
                        Label("Add appliance", systemImage: "plus.app")
                    }
                }
            }
            #endif
        }
    }
}

extension Appliance {
    var systemImage: String {
        switch type {
        case .dishWasher: return "dishwasher"
        case .washingMachine: return "washer"
        }
    }
}

#if DEBUG
struct ApplianceSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ApplianceSelectionView(
                store: Store(initialState: ApplianceSelection.State(appliances: [.dishwasher, .washingMachine])) {
                    ApplianceSelection()
                }
            )
        }
    }
}
#endif
