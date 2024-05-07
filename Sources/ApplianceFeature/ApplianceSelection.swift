import ComposableArchitecture

@Reducer
public struct ApplianceSelection {
    @ObservableState
    public struct State: Equatable {
        @Shared public var appliances: IdentifiedArrayOf<Appliance>
        @Presents public var destination: Destination.State?

        public init(
            appliances: IdentifiedArrayOf<Appliance> = [.washingMachine, .dishwasher],
            destination: Destination.State? = nil
        ) {
            self._appliances = Shared(wrappedValue: appliances, .appliances)
            self.destination = destination
        }
    }
    public enum Action: Equatable {
        case addApplianceButtonTapped
        case addApplianceCancelButtonTapped
        case addApplianceSaveButtonTapped
        case applianceTapped(Appliance)
        case destination(PresentationAction<Destination.Action>)
    }

    @Reducer(state: .equatable, action: .equatable)
    public enum Destination {
        case selection(ProgramSelection)
        case addAppliance(ApplianceForm)
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
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }
}
