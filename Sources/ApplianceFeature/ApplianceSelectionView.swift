import ComposableArchitecture
import SwiftUI

public struct ApplianceSelectionView: View {
    @Bindable var store: StoreOf<ApplianceSelection>

    public init(store: StoreOf<ApplianceSelection>) {
        self.store = store
    }

    public var body: some View {
        List {
            ForEach(store.appliances) { appliance in
                Button { store.send(.applianceTapped(appliance)) } label: {
                    Label(appliance.name, systemImage: appliance.systemImage)
                }
            }
            #if os(iOS) || os(macOS)
            .sheet(item: $store.scope(state: \.destination?.addAppliance, action: \.destination.addAppliance)) { store in
                NavigationStack {
                    ApplianceFormView(store: store)
                        .navigationTitle("New appliance")
                        .toolbar {
                            ToolbarItem {
                                Button { self.store.send(.addApplianceSaveButtonTapped) } label: {
                                    Text("Save")
                                }
                            }
                            ToolbarItem(placement: .cancellationAction) {
                                Button { self.store.send(.addApplianceCancelButtonTapped) } label: {
                                    Text("Cancel")
                                }
                            }
                        }
                }
            }
            #endif
        }
        .navigationDestination(
            item: $store.scope(state: \.destination?.selection, action: \.destination.selection),
            destination: ProgramSelectionView.init
        )
        .navigationTitle("Choose your appliance")
        #if os(iOS) || os(macOS)
        .toolbar {
            ToolbarItem {
                Button { store.send(.addApplianceButtonTapped) } label: {
                    Label("Add appliance", systemImage: "plus.app")
                }
            }
        }
        #endif
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
