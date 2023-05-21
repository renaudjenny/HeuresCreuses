import ComposableArchitecture
import SwiftUI

struct DeviceProgramFilter: Reducer {
    struct State: Equatable {
        let devices: IdentifiedArrayOf<Device>
        @BindingState var selections: IdentifiedArrayOf<Selection>
    }

    struct Selection: Equatable, Identifiable, Hashable {
        let deviceID: Device.ID
        let program: Program

        var id: Program.ID { program.id }
        func hash(into hasher: inout Hasher) {
            hasher.combine(deviceID)
            hasher.combine(program.id)
        }
    }

    enum Action: Equatable, BindableAction {
        case binding(BindingAction<State>)
        case deviceProgramTapped(id: Device.ID, program: Program)
    }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .binding:
                return .none
            case let .deviceProgramTapped(id, program):
                if let selection = state.selections[id: program.id] {
                    state.selections.remove(id: program.id)
                } else {
                    state.selections.append(Selection(deviceID: id, program: program))
                }
                return .none
            }
        }
    }
}

struct DeviceProgramFilterView: View {
    let store: StoreOf<DeviceProgramFilter>

    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            Form {
                List {
                    ForEach(viewStore.devices) { device in
                        Section(device.name) {
                            Text("")
                        }
                    }
                }
            }
        }
    }
}

#if DEBUG
struct DeviceProgramFilersView_Previews: PreviewProvider {
    static var previews: some View {
        DeviceProgramFilterView(store: Store(
            initialState: DeviceProgramFilter.State(
                devices: [.dishwasher, .washingMachine],
                selections: [
                    DeviceProgramFilter.Selection(
                        deviceID: Device.dishwasher.id,
                        program: Device.dishwasher.programs.first!
                    )
                ]
            ),
            reducer: DeviceProgramFilter()
        ))
    }
}
#endif
