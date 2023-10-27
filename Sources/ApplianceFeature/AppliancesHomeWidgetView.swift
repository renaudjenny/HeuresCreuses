import ComposableArchitecture
import DataManagerDependency
import HomeWidget
import SwiftUI

public struct ApplianceHomeWidget: Reducer {
    public struct State: Equatable {
        public var appliances: IdentifiedArrayOf<Appliance>
        @PresentationState public var destination: ApplianceSelection.State?

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
        case widgetTapped
    }

    @Dependency(\.continuousClock) var clock
    @Dependency(\.dataManager.save) var saveData

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .destination:
                return .none

            case .widgetTapped:
                state.destination = ApplianceSelection.State(appliances: state.appliances)
                return .none
            }
        }
        .ifLet(\.$destination, action: /Action.destination) {
            ApplianceSelection()
        }
        .onChange(of: \.destination?.appliances) { oldValue, newValue in
            Reduce { state, _ in
                state.appliances = newValue ?? state.appliances
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
    let store: StoreOf<ApplianceHomeWidget>

    private struct ViewState: Equatable {
        let appliancesCount: Int

        init(_ state: ApplianceHomeWidget.State) {
            appliancesCount = state.appliances.count
        }
    }

    public init(store: StoreOf<ApplianceHomeWidget>) {
        self.store = store
    }

    public var body: some View {
        WithViewStore(store, observe: ViewState.init) { viewStore in
            Button { viewStore.send(.widgetTapped) } label: {
                HomeWidgetView(title: "Your appliances", icon: Image(systemName: "washer")) {
                    Text("^[**\(viewStore.appliancesCount)** appliances](inflect: true)")
                }
            }
            .buttonStyle(.plain)
            .navigationDestination(
                store: store.scope(state: \.$destination, action: { .destination($0) }),
                destination: ApplianceSelectionView.init
            )
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
