import ComposableArchitecture

public struct ProgramSelection: Reducer {
    public struct State: Equatable {
        var appliance: Appliance
        @PresentationState var destination: Destination.State?
    }
    public enum Action: Equatable {
        case programTapped(Program)
        case delegate(Delegate)
        case destination(PresentationAction<Destination.Action>)
        case editApplianceButtonTapped
        case editApplianceCancelButtonTapped
        case editApplianceSaveButtonTapped

        public enum Delegate: Equatable {
            case applianceUpdated(Appliance)
        }
    }

    public struct Destination: Reducer {
        public enum State: Equatable {
            case delays(Delays.State)
            case edit(ApplianceForm.State)
            case optimum(Optimum.State)
        }
        public enum Action: Equatable {
            case delays(Delays.Action)
            case edit(ApplianceForm.Action)
            case optimum(Optimum.Action)
        }

        public var body: some ReducerOf<Self> {
            Scope(state: /State.delays, action: /Action.delays) {
                Delays()
            }
            Scope(state: /State.edit, action: /Action.edit) {
                ApplianceForm()
            }
            Scope(state: /State.optimum, action: /Action.optimum) {
                Optimum()
            }
        }
    }

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .programTapped(program):
                state.destination = .optimum(Optimum.State(program: program, appliance: state.appliance))
                return .none
            case .delegate:
                return .none
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
        .ifLet(\.$destination, action: /Action.destination) {
            Destination()
        }
        .onChange(of: \.appliance) { oldValue, newValue in
            Reduce { state, action in
                return .send(.delegate(.applianceUpdated(newValue)))
            }
        }
    }
}
