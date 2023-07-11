import ComposableArchitecture

public struct ApplianceSelection: Reducer {
    public struct State: Equatable {
        var appliances: IdentifiedArrayOf<Appliance>
        @PresentationState var programSelectionDestination: ProgramSelection.State?
    }
    public enum Action: Equatable {
        case applianceTapped(Appliance)
        case programSelectionDestination(PresentationAction<ProgramSelection.Action>)
    }

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .applianceTapped(appliance):
                state.programSelectionDestination = ProgramSelection.State(appliance: appliance)
                return .none
            case .programSelectionDestination:
                return .none
            }
        }
        .ifLet(\.$programSelectionDestination, action: /ApplianceSelection.Action.programSelectionDestination) {
            ProgramSelection()
        }
    }
}
