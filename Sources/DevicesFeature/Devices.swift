import ComposableArchitecture
import SwiftUI

public struct Devices: ReducerProtocol {
    public struct State: Equatable {
        var devices: IdentifiedArrayOf<EditDevice.State> = []
    }

    public enum Action: Equatable {
    case editDevice(EditDevice.Action)
    }

    public func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
        EmptyReducer()
            .forEach(\.devices, action: /Devices.Action.editDevice) {
                EditDevice()
            }
    }
}

public struct DevicesView: View {
    let store: StoreOf<Devices>

    public var body: some View {
        ForEachStore(store.scope(state: \.devices, action: Devices.Action.editDevice, content: EditDeviceView.init))
    }
}
