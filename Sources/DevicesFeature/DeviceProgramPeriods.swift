import ComposableArchitecture
import Models
import SwiftUI

public struct DeviceProgramPeriods: Reducer {
    public struct State: Equatable {
        @BindingState var date: Date
        @BindingState var extraMinutesFromNow = 0.0
        @BindingState var mode: Mode
        var dateRange: ClosedRange<Date>
        var periods: [OffPeakPeriod]
        var devices: IdentifiedArrayOf<Device>
        var filteredDevicePrograms: IdentifiedArrayOf<DeviceProgramFilter.Selection>
        var deviceProgramPeriods: IdentifiedArrayOf<DeviceProgramPeriod.State> = []
        var now: Date
        @PresentationState var filterDestination: DeviceProgramFilter.State?

        public init(periods: [OffPeakPeriod], devices: IdentifiedArrayOf<Device>) {
            self.periods = periods
            self.devices = devices
            @Dependency(\.date) var date
            self.date = date()
            now = date()
            dateRange = date()...date().addingTimeInterval(60 * 60 * 24 * 2)
            mode = .startDate
            filteredDevicePrograms = IdentifiedArrayOf(
                uniqueElements: devices
                    .map { ($0.id, $0.programs) }
                    .flatMap { id, programs in
                        programs.map { DeviceProgramFilter.Selection(deviceID: id, program: $0) }
                    }
            )
        }
    }

    public enum Mode {
        case startDate
        case endDate
    }

    public enum Action: Equatable, BindableAction {
        case binding(BindingAction<State>)
        case filterDestination(PresentationAction<DeviceProgramFilter.Action>)
        case task
        case filterButtonTapped
        case deviceProgramPeriod(id: DeviceProgramPeriod.State.ID, action: DeviceProgramPeriod.Action)
    }

    @Dependency(\.date) var date

    public init() {}

    public var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .binding(\.$date), .binding(\.$mode):
                return updateDeviceProgramPeriods(state: &state)
            case .binding(\.$extraMinutesFromNow):
                state.date = date().addingTimeInterval(state.extraMinutesFromNow * 60)
                return updateDeviceProgramPeriods(state: &state)
            case .binding:
                return .none
            case .filterDestination(.dismiss):
                state.filteredDevicePrograms = state.filterDestination?.selections ?? state.filteredDevicePrograms
                return updateDeviceProgramPeriods(state: &state)
            case .filterDestination:
                return .none
            case .filterButtonTapped:
                state.filterDestination = DeviceProgramFilter.State(
                    devices: state.devices,
                    selections: state.filteredDevicePrograms
                )
                return .none
            case .task:
                return updateDeviceProgramPeriods(state: &state)
            case let .deviceProgramPeriod(_, action: .delegate(action)):
                switch action {
                case let .setDate(date, mode):
                    state.date = date
                    state.mode = mode
                    return updateDeviceProgramPeriods(state: &state)
                }
            case .deviceProgramPeriod:
                return .none
            }
        }
        .forEach(\.deviceProgramPeriods, action: /Action.deviceProgramPeriod) {
            DeviceProgramPeriod()
        }
        .ifLet(\.$filterDestination, action: /DeviceProgramPeriods.Action.filterDestination) {
            DeviceProgramFilter()
        }
    }

    private func updateDeviceProgramPeriods(state: inout State) -> Effect<Action> {
        state.extraMinutesFromNow = date().distance(to: state.date) / 60
        state.deviceProgramPeriods = IdentifiedArray(uniqueElements: state.periods.map { period in
            state.filteredDevicePrograms.compactMap { selection in
                let start: Date
                let end: Date
                switch state.mode {
                case .startDate:
                    start = state.date
                    end = start.addingTimeInterval(selection.program.duration)
                case .endDate:
                    end = state.date
                    start = end.addingTimeInterval(-selection.program.duration)
                }

                guard start.distance(to: end) > 0, (period.start...period.end).overlaps(start...end),
                      let device = state.devices[id: selection.deviceID]
                else { return nil }

                let distanceToOffPeakStart = start.distance(to: period.start)
                let distanceFromOffPeakEnd = period.end.distance(to: end)

                let peakDuration = max(distanceToOffPeakStart, 0) + max(distanceFromOffPeakEnd, 0)

                let id = selection.deviceID.uuidString + selection.program.id.uuidString
                return DeviceProgramPeriod.State(
                    device: device,
                    program: selection.program,
                    start: start,
                    end: end,
                    offPeakRatio: 1 - (peakDuration / start.distance(to: end)),
                    isTimersShown: state.deviceProgramPeriods[id: id]?.isTimersShown ?? false
                )
            }
        }.flatMap { $0 })
        return .none
    }
}

public struct DeviceProgramPeriodsView: View {
    let store: StoreOf<DeviceProgramPeriods>

    public init(store: StoreOf<DeviceProgramPeriods>) {
        self.store = store
    }

    public var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            Form {
                Section("Dates") {
                    #if os(watchOS)
                    Picker("Mode", selection: viewStore.$mode) {
                        Text("Start").tag(DeviceProgramPeriods.Mode.startDate)
                        Text("End").tag(DeviceProgramPeriods.Mode.endDate)
                    }
                    Text("Date: \(viewStore.date, format: .dateTime)")
                    #else
                    Picker("Mode", selection: viewStore.$mode) {
                        Text("Start").tag(DeviceProgramPeriods.Mode.startDate)
                        Text("End").tag(DeviceProgramPeriods.Mode.endDate)
                    }
                    .pickerStyle(.segmented)

                    DatePicker(
                        selection: viewStore.$date,
                        in: viewStore.dateRange,
                        displayedComponents: [.date, .hourAndMinute]
                    ) {
                        Text("Date & time")
                    }
                    #endif
                    Slider(value: viewStore.$extraMinutesFromNow, in: 0...2880) {
                        Text("Extra minutes")
                    }
                }

                Section("Filter") {

                    Button { viewStore.send(.filterButtonTapped) } label: {
                        VStack(alignment: .leading) {
                            if let filterCaption = viewStore.state.filterCaption {
                                Text(.init(filterCaption)).font(.caption)
                            } else {
                                Text("All programs")
                            }
                        }
                    }
                    .navigationDestination(
                        store: store.scope(
                            state: \.$filterDestination,
                            action: DeviceProgramPeriods.Action.filterDestination
                        ),
                        destination: DeviceProgramFilterView.init
                    )
                }

                Section("Off peak available programs") {
                    ForEachStore(
                        store.scope(
                            state: \.deviceProgramPeriods,
                            action: DeviceProgramPeriods.Action.deviceProgramPeriod
                        ),
                        content: DeviceProgramPeriodView.init
                    )
                }
            }
            .task { @MainActor in viewStore.send(.task) }
        }
    }
}

private extension DeviceProgramPeriods.State {
    var filterCaption: String? {
        guard Set(filteredDevicePrograms.map(\.program)) != Set(devices.flatMap(\.programs))
        else { return nil }
        return filteredDevicePrograms.compactMap { selection in
            guard let device = devices[id: selection.deviceID] else { return nil }
            return "**\(device.name)** \(selection.program.name)"
        }
        .joined(separator: "\n")
    }
}

#if DEBUG
struct DeviceProgramPeriodsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            DeviceProgramPeriodsView(
                store: Store(
                    initialState: DeviceProgramPeriods.State(
                        periods: [
                            OffPeakPeriod(start: Date().addingTimeInterval(-60 * 60 * 10), end: Date().addingTimeInterval(-60 * 60 * 8)),
                            OffPeakPeriod(start: Date().addingTimeInterval(60 * 60 * 2), end: Date().addingTimeInterval(60 * 60 * 4)),
                            OffPeakPeriod(start: Date().addingTimeInterval(60 * 60 * 10), end: Date().addingTimeInterval(60 * 60 * 12)),
                        ],
                        devices: [.dishwasher, .washingMachine]
                    )
                ) {
                    DeviceProgramPeriods()
                }
            )
        }
    }
}
#endif
