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

    public var body: some View {
        WithViewStore(store, observe: ViewState.init) { viewState in
            List {
                ForEach(viewState.appliances) { appliance in
                    Button { viewState.send(.applianceTapped(appliance)) } label: {
                        Label(appliance.name, systemImage: appliance.systemImage)
                    }
                }
                .navigationDestination(
                    store: store.scope(
                        state: \.$programSelectionDestination,
                        action: ApplianceSelection.Action.programSelectionDestination
                    ),
                    destination: ProgramSelectionView.init
                )
            }
            .navigationTitle("Choose your appliance")
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
                store: Store(
                    initialState: ApplianceSelection.State(
                        appliances: [.dishwasher, .washingMachine]
                    ),
                    reducer: ApplianceSelection()
                )
            )
        }
    }
}
#endif
