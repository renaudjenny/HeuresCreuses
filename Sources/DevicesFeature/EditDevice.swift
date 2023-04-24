import ComposableArchitecture
import SwiftUI

public struct EditDevice: ReducerProtocol {
    public struct State: Equatable, Identifiable, Hashable {
        public var id: Device.ID { device.id }
        public var device: Device

        public func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
    }

    public enum Action: Equatable {

    }

    public func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
        switch action {
        }
        return .none
    }
}

public struct EditDeviceView: View {
    let store: StoreOf<EditDevice>

    public init(store: StoreOf<EditDevice>) {
        self.store = store
    }

    public var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            Text("Edit Device: \(viewStore.device.name)")
        }
    }
}

#if DEBUG
struct EditDeviceView_Previews: PreviewProvider {
    static var previews: some View {
        EditDeviceView(store: Store(initialState: EditDevice.State(device: .washingMachine), reducer: EditDevice()))
    }
}
#endif
