import ComposableArchitecture
import HomeWidget
import SwiftUI

@Reducer
public struct ApplianceHomeWidget {
    @ObservableState
    public struct State: Equatable {
        @Shared public var appliances: IdentifiedArrayOf<Appliance>
        @Presents public var destination: ApplianceSelection.State?

        public init(
            appliances: IdentifiedArrayOf<Appliance> = [.dishwasher, .washingMachine],
            destination: ApplianceSelection.State? = nil
        ) {
            self._appliances = Shared(wrappedValue: appliances, .appliances)
            self.destination = destination
        }
    }
    public enum Action: Equatable {
        case destination(PresentationAction<ApplianceSelection.Action>)
        case widgetTapped
    }

    @Dependency(\.continuousClock) var clock

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .destination(.dismiss):
                return .none
            case .destination(.presented):
                return .none
            case .destination:
                return .none

            case .widgetTapped:
                state.destination = ApplianceSelection.State(appliances: state.appliances)
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination) {
            ApplianceSelection()
        }
    }
}

public struct AppliancesHomeWidgetView: View {
    @Bindable var store: StoreOf<ApplianceHomeWidget>

    public init(store: StoreOf<ApplianceHomeWidget>) {
        self.store = store
    }

    public var body: some View {
        Button { store.send(.widgetTapped) } label: {
            HomeWidgetView(title: "Your appliances", icon: Image(systemName: "washer")) {
                Text("^[**\(store.appliances.count)** appliances](inflect: true)")
            }
        }
        .buttonStyle(.plain)
        .sheet(item: $store.scope(state: \.destination, action: \.destination)) { store in
            NavigationStack {
                ApplianceSelectionView(store: store)
            }
        }
    }
}

#Preview {
    NavigationStack {
        List {
            AppliancesHomeWidgetView(
                store: Store(initialState: ApplianceHomeWidget.State(appliances: [.dishwasher, .washingMachine])) {
                    ApplianceHomeWidget()
                }
            )
        }
    }
}
