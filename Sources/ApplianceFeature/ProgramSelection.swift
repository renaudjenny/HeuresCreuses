import ComposableArchitecture

public struct ProgramSelection: Reducer {
    public struct State: Equatable {
        var appliance: Appliance
    }
    public enum Action: Equatable {}
    public var body: some ReducerOf<Self> {
        EmptyReducer()
    }
}
