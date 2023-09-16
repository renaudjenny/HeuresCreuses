import ComposableArchitecture

public struct ProgramForm: Reducer {
    public struct State: Equatable, Identifiable {
        @BindingState var program: Program
        @BindingState var isExtended: Bool

        public var id: Program.ID { program.id }

        public init(program: Program, isExtended: Bool = true) {
            self.program = program
            self.isExtended = isExtended
        }
    }
    public enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
    }

    public var body: some ReducerOf<Self> {
        BindingReducer()
    }
}
