import ComposableArchitecture

public struct ApplianceForm: Reducer {
    public struct State: Equatable {
        @BindingState var appliance: Appliance

        public init(appliance: Appliance) {
            self.appliance = appliance
        }
    }
    public enum Action: BindableAction, Equatable {
        case binding(BindingAction<ApplianceForm.State>)
    }
    public var body: some ReducerOf<Self> {
        BindingReducer()
    }
}
