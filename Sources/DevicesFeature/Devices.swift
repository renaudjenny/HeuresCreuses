import ComposableArchitecture
import SwiftUI

public struct Devices: ReducerProtocol {
    public struct State: Equatable {
        public var devices: IdentifiedArrayOf<EditDevice.State> = []
    }

    public enum Action: Equatable {
        case editDevice(id: EditDevice.State.ID, action: EditDevice.Action)
    }

    public var body: some ReducerProtocol<State, Action> {
        EmptyReducer()
            .forEach(\.devices, action: /Devices.Action.editDevice) {
                EditDevice()
            }
    }
}

public struct DevicesView: View {
    let store: StoreOf<Devices>

    public init(store: StoreOf<Devices>) {
        self.store = store
    }

    public var body: some View {
        NavigationView {
            List {
                ForEachStore(store.scope(state: \.devices, action: Devices.Action.editDevice)) { store in
                    WithViewStore(store, observe: { $0.device.name }) { viewStore in
                        NavigationLink(viewStore.state) { EditDeviceView(store: store) }
                    }
                }
            }
        }
    }
}

#if DEBUG
struct DevicesView_Previews: PreviewProvider {
    static var previews: some View {
        DevicesView(store: Store(
            initialState: Devices.State(devices: [
                EditDevice.State(device: .dishwasher),
                EditDevice.State(device: .washingMachine),
            ]),
            reducer: Devices()
        ))
    }
}
#endif
