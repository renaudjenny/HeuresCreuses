import ComposableArchitecture
import DataManagerDependency
import HomeWidget
import SwiftUI

@Reducer
public struct ApplianceHomeWidget {
    @ObservableState
    public struct State: Equatable {
        public var appliances: IdentifiedArrayOf<Appliance>
        @Presents public var destination: ApplianceSelection.State?

        public init(
            appliances: IdentifiedArrayOf<Appliance> = [.washingMachine, .dishwasher],
            destination: ApplianceSelection.State? = nil
        ) {
            self.appliances = appliances
            self.destination = destination
        }
    }
    public enum Action: Equatable {
        case destination(PresentationAction<ApplianceSelection.Action>)
        case task
        case widgetTapped
    }

    @Dependency(\.continuousClock) var clock
    @Dependency(\.dataManager.load) var loadData
    @Dependency(\.dataManager.save) var saveData

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

            case .task:
                // TODO: add logs and error screen if it fails?
                state.appliances = (try? JSONDecoder().decode(
                    IdentifiedArrayOf<Appliance>.self,
                    from: loadData(.appliances)
                )) ?? state.appliances
                return .none

            case .widgetTapped:
                state.destination = ApplianceSelection.State(appliances: state.appliances)
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination) {
            ApplianceSelection()
        }
        .onChange(of: \.destination?.appliances) { oldValue, newValue in
            Reduce { state, _ in
                guard let newValue else { return .none }
                state.appliances = newValue
                return .none
            }
        }

        Reduce { state, _ in
                .run { [appliances = state.appliances] _ in
                    enum CancelID { case saveDebounce }
                    try await withTaskCancellation(id: CancelID.saveDebounce, cancelInFlight: true) {
                        try await self.clock.sleep(for: .seconds(1))
                        try self.saveData(try JSONEncoder().encode(appliances), .appliances)
                    }
                }
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
        .task { await store.send(.task).finish() }
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
