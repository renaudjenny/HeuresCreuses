import ComposableArchitecture
import SwiftUI

public struct EditDevice: Reducer {
    public struct State: Equatable, Identifiable {
        public var id: Device.ID { device.id }
        @BindingState public var device: Device

        public init(device: Device) {
            self.device = device
        }
    }

    public enum Action: Equatable, BindableAction {
        case binding(BindingAction<State>)
    }

    public var body: some ReducerOf<Self> {
        BindingReducer()
    }
}

public struct EditDeviceView: View {
    let store: StoreOf<EditDevice>

    public init(store: StoreOf<EditDevice>) {
        self.store = store
    }

    public var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            Form {
                Section("Device") {
                    TextField("Name", text: viewStore.$device.name)
                    Picker(selection: viewStore.binding(\.$device.type)) {
                        ForEach(DeviceType.allCases, id: \.self) { deviceType in
                            switch deviceType {
                            case .washingMachine: Text("Washing Machine").tag(DeviceType.washingMachine)
                            case .dishWasher: Text("Dishwasher").tag(DeviceType.dishWasher)
                            }
                        }
                    } label: {
                        Text("Device Type")
                    }

                }

                Section("Program") {
                    Picker(selection: viewStore.$device.delay) {
                        ForEach(Delay.allCases, id: \.self) { delay in
                            switch delay {
                            case .none: Text("None").tag(Delay.none)
                            case .schedule: Text("Schedule").tag(Delay.schedule)
                            case .timers: Text("Timers").tag(Delay.timers([]))
                            }
                        }
                    } label: {
                        Text("Delay Type")
                    }
                }
            }
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
