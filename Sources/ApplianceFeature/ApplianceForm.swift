import ComposableArchitecture

public struct ApplianceForm: Reducer {
    public struct State: Equatable {
        @BindingState var appliance: Appliance

        public init(appliance: Appliance) {
            self.appliance = appliance
        }
    }
    public enum Action: BindableAction, Equatable {
        case addProgramButtonTapped
        case binding(BindingAction<State>)
    }

    @Dependency(\.uuid) var uuid

    public var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .addProgramButtonTapped:
                state.appliance.programs.append(Program(id: uuid()))
                return .none
            case .binding:
                return .none
            }
        }
    }
}
