import ComposableArchitecture

public struct ApplianceSelection: Reducer {
    public struct State: Equatable {
        var appliances: IdentifiedArrayOf<Appliance>
        @PresentationState var destination: Destination.State?
//        @PresentationState var programSelectionDestination: ProgramSelection.State?

        public init(
            appliances: IdentifiedArrayOf<Appliance> = [.washingMachine, .dishwasher],
            destination: Destination.State? = nil
//            programSelectionDestination: ProgramSelection.State? = nil
        ) {
            self.appliances = appliances
            self.destination = destination
//            self.programSelectionDestination = programSelectionDestination
        }
    }
    public enum Action: Equatable {
        case applianceTapped(Appliance)
        case destination(PresentationAction<Destination.Action>)
        case programSelectionDestination(PresentationAction<ProgramSelection.Action>)
        case addApplianceButtonTapped
    }

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .applianceTapped(appliance):
//                state.programSelectionDestination = ProgramSelection.State(appliance: appliance)
                state.destination = .selection(ProgramSelection.State(appliance: appliance))
                return .none
            case .destination:
                return .none
            case .programSelectionDestination:
                return .none
            case .addApplianceButtonTapped:
                // TODO: change the state.destination to a future ApplianceForm.State
                return .none
            }
        }
        .ifLet(\.$destination, action: /ApplianceSelection.Action.destination) {
            Destination()
        }
//        .ifLet(\.$programSelectionDestination, action: /ApplianceSelection.Action.programSelectionDestination) {
//            ProgramSelection()
//        }
    }
}

extension ApplianceSelection {
    public struct Destination: Reducer {
        public enum State: Equatable {
            case selection(ProgramSelection.State)
        }
        public enum Action: Equatable {
            case selection(ProgramSelection.Action)
        }
        public var body: some ReducerOf<Self> {
            Scope(state: /State.selection, action: /Action.selection) {
                ProgramSelection()
            }
        }
    }
}
