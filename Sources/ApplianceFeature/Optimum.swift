import ComposableArchitecture

public struct Optimum: Reducer {
    public struct State: Equatable {
        let program: Program
        let appliance: Appliance
    }
    public enum Action: Equatable {
        case delaysTapped(Program)
    }

    public var body: some ReducerOf<Self> { EmptyReducer() }
}
