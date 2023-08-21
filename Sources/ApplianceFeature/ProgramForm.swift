import ComposableArchitecture

public struct ProgramForm: Reducer {
    public struct State: Equatable, Identifiable {
        @BindingState var program: Program
        @BindingState var isExtended: Bool = true

        public var id: Program.ID { program.id }
    }
    public enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
    }

    public var body: some ReducerOf<Self> {
        BindingReducer()
    }
}
