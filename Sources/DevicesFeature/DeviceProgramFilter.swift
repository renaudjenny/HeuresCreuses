import ComposableArchitecture
import SwiftUI

public struct DeviceProgramFilter: Reducer {
    public struct State: Equatable {
        let devices: IdentifiedArrayOf<Device>
        var selections: IdentifiedArrayOf<Selection>
    }

    public struct Selection: Equatable, Identifiable, Hashable {
        let deviceID: Device.ID
        let program: Program

        public var id: Program.ID { program.id }
        public func hash(into hasher: inout Hasher) {
            hasher.combine(deviceID)
            hasher.combine(program.id)
        }
    }

    public enum Action: Equatable, BindableAction {
        case binding(BindingAction<State>)
        case deviceProgramTapped(id: Device.ID, program: Program)
    }

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .binding:
                return .none
            case let .deviceProgramTapped(id, program):
                if state.selections[id: program.id] != nil {
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
                            List {
                                ForEach(device.programs, id: \.id) { program in
                                    HStack {
                                        Button {
                                            viewStore.send(.deviceProgramTapped(id: device.id, program: program))
                                        } label: {
                                            Text(program.name)
                                        }
                                        .buttonStyle(.plain)

                                        Spacer()

                                        Image(
                                            systemName: viewStore.state.isProgramSelected(program)
                                            ? "checkmark.circle"
                                            : "circle"
                                        )
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

private extension DeviceProgramFilter.State {
    func isProgramSelected(_ program: Program) -> Bool {
        selections.contains(where: { $0.program.id == program.id })
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
