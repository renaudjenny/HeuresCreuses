import ComposableArchitecture

public struct ApplianceSelection: Reducer {
    public struct State: Equatable {
        var appliances: IdentifiedArrayOf<Appliance>
        @PresentationState var destination: Destination.State?

        public init(
            appliances: IdentifiedArrayOf<Appliance> = [.washingMachine, .dishwasher],
            destination: Destination.State? = nil
        ) {
            self.appliances = appliances
            self.destination = destination
        }
    }
    public enum Action: Equatable {
        case addApplianceButtonTapped
        case addApplianceCancelButtonTapped
        case addApplianceSaveButtonTapped
        case applianceTapped(Appliance)
        case destination(PresentationAction<Destination.Action>)
        case programSelectionDestination(PresentationAction<ProgramSelection.Action>)
    }

    public init() {}

    @Dependency(\.uuid) var uuid

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .addApplianceButtonTapped:
                let newAppliance = Appliance(id: uuid())
                state.destination = .addAppliance(ApplianceForm.State(appliance: newAppliance))
                return .none
            case .addApplianceCancelButtonTapped:
                state.destination = nil
                return .none
            case .addApplianceSaveButtonTapped:
                guard case let .addAppliance(newAppliance) = state.destination else { return .none }
                state.appliances.append(newAppliance.appliance)
                state.destination = nil
                return .none
            case let .applianceTapped(appliance):
                state.destination = .selection(ProgramSelection.State(appliance: appliance))
                return .none
            case let .destination(.presented(.selection(.delegate(action)))):
                switch action {
                case let .applianceUpdated(appliance):
                    state.appliances[id: appliance.id] = appliance
                    return .none
                case let .deleteAppliance(id):
                    state.appliances.remove(id: id)
                    return .none
                }
            case .destination:
                return .none
            case .programSelectionDestination:
                return .none
            }
        }
        .ifLet(\.$destination, action: /ApplianceSelection.Action.destination) {
            Destination()
        }
    }
}

extension ApplianceSelection {
    public struct Destination: Reducer {
        public enum State: Equatable {
            case selection(ProgramSelection.State)
            case addAppliance(ApplianceForm.State)
        }
        public enum Action: Equatable {
            case selection(ProgramSelection.Action)
            case addAppliance(ApplianceForm.Action)
        }
        public var body: some ReducerOf<Self> {
            Scope(state: /State.selection, action: /Action.selection) {
                ProgramSelection()
            }
            Scope(state: /State.addAppliance, action: /Action.addAppliance) {
                ApplianceForm()
            }
        }
    }
}
