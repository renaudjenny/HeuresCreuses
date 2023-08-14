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
                    state: /ApplianceSelection.Destination.State.selection,
                    action: { .selection($0) },
                    destination: ProgramSelectionView.init
                )
            }
            .navigationTitle("Choose your appliance")
            .toolbar {
                ToolbarItem {
                    Button { viewStore.send(.addApplianceButtonTapped) } label: {
                        Label("Add appliance", systemImage: "plus.app")
                    }
                }
            }
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
