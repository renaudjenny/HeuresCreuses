import ComposableArchitecture

@Reducer
public struct ProgramForm {
    @ObservableState
    public struct State: Equatable, Identifiable {
        var program: Program
        var isExtended: Bool

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
