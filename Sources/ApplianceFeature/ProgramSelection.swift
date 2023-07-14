import ComposableArchitecture

public struct ProgramSelection: Reducer {
    public struct State: Equatable {
        var appliance: Appliance
        @PresentationState var delaysDestination: Delays.State?
    }
    public enum Action: Equatable {
        case programTapped(Program)
        case delaysDestination(PresentationAction<Delays.Action>)
    }

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .programTapped(program):
                state.delaysDestination = Delays.State(program: program)
                return .none
            case .delaysDestination:
                return .none
            }
        }
        .ifLet(\.$delaysDestination, action: /ProgramSelection.Action.delaysDestination) {
            Delays()
        }
    }
}
