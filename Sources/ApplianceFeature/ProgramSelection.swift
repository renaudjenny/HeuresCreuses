import ComposableArchitecture

@Reducer
public struct ProgramSelection {
    @ObservableState
    public struct State: Equatable {
        public var appliance: Appliance
        @Presents public var destination: Destination.State?

        public init(appliance: Appliance, destination: Destination.State? = nil) {
            self.appliance = appliance
            self.destination = destination
        }
    }
    public enum Action: Equatable {
        case programTapped(Program)
        case delegate(Delegate)
        case deleteButtonTapped
        case destination(PresentationAction<Destination.Action>)
        case editApplianceButtonTapped
        case editApplianceCancelButtonTapped
        case editApplianceSaveButtonTapped

        public enum Delegate: Equatable {
            case applianceUpdated(Appliance)
            case deleteAppliance(id: Appliance.ID)
        }
    }

    @Reducer
    public struct Alert {
        public typealias State = AlertState<Action>

        public enum Action {
            case confirmDeletion
        }
    }

    @Reducer(state: .equatable, action: .equatable)
    public enum Destination {
        case alert(Alert)
        case delays(Delays)
        case edit(ApplianceForm)
        case optimum(Optimum)
    }

    @Dependency(\.dismiss) var dismiss

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .programTapped(program):
                state.destination = .optimum(Optimum.State(program: program, appliance: state.appliance))
                return .none
            case .delegate:
                return .none
            case .deleteButtonTapped:
                state.destination = .alert(
                    AlertState {
                        TextState("Are you sure you want to delete?")
                    } actions: {
                        ButtonState(
                            role: .destructive, action: .confirmDeletion
                        ) {
                            TextState("Delete")
                        }
                    }
                )
                return .none
            case .destination(.presented(.alert(.confirmDeletion))):
                state.destination = nil
                return .run { [id = state.appliance.id] send in
                    await send(.delegate(.deleteAppliance(id: id)))
                    await dismiss()
                }
            case let .destination(.presented(.optimum(.delaysTapped(program)))):
                state.destination = .delays(Delays.State(program: program, appliance: state.appliance))
                return .none
            case .destination:
                return .none
            case .editApplianceButtonTapped:
                state.destination = .edit(ApplianceForm.State(appliance: state.appliance))
                return .none
            case .editApplianceCancelButtonTapped:
                state.destination = nil
                return .none
            case .editApplianceSaveButtonTapped:
                guard case let .edit(editedApplianceState) = state.destination else { return .none }
                state.destination = nil
                state.appliance = editedApplianceState.appliance
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
        .onChange(of: \.appliance) { oldValue, newValue in
            Reduce { state, action in
                return .send(.delegate(.applianceUpdated(newValue)))
            }
        }
    }
}
