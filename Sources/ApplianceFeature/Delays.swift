import ComposableArchitecture

public struct Delays: Reducer {
    public struct State: Equatable {
        var program: Program
    }
    public enum Action: Equatable {}
    public var body: some ReducerOf<Self> {
        EmptyReducer()
    }
}
