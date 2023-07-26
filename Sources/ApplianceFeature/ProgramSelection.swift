import ComposableArchitecture

public struct ProgramSelection: Reducer {
    public struct State: Equatable {
        var appliance: Appliance
        @PresentationState var bottomSheet: BottomSheet.State?
        @PresentationState var destination: Destination.State?
    }
    public enum Action: Equatable {
        case programTapped(Program)
        case bottomSheet(PresentationAction<BottomSheet.Action>)
        case destination(PresentationAction<Destination.Action>)
    }

    public struct BottomSheet: Reducer {
        public struct State: Equatable {
            let program: Program
            let appliance: Appliance
        }
        public enum Action: Equatable {
            case delaysTapped(Program)
            case optimumTapped(Program)
        }

        public var body: some ReducerOf<Self> { EmptyReducer() }
    }

    public struct Destination: Reducer {
        public enum State: Equatable {
            case delays(Delays.State)
            case optimum(String)
        }
        public enum Action: Equatable {
            case delays(Delays.Action)
            case optimum
        }

        public var body: some ReducerOf<Self> {
            Scope(state: /State.delays, action: /Action.delays) {
                Delays()
            }
            Scope(state: /State.optimum, action: /Action.optimum) {
                EmptyReducer()
            }
        }
    }

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .programTapped(program):
                state.bottomSheet = BottomSheet.State(program: program, appliance: state.appliance)
                return .none
            case let .bottomSheet(.presented(.delaysTapped(program))):
                state.destination = .delays(Delays.State(program: program, appliance: state.appliance))
                return .none
            case .bottomSheet:
                return .none
            case .destination:
                return .none
            }
        }
        .ifLet(\.$bottomSheet, action: /Action.bottomSheet) {
            BottomSheet()
        }
        .ifLet(\.$destination, action: /Action.destination) {
            Destination()
        }
    }
}
