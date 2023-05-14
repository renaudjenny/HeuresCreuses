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
        var deviceProgramPeriods: IdentifiedArrayOf<DeviceProgramPeriod.State> = []
        var now: Date

        public init(periods: [OffPeakPeriod], devices: IdentifiedArrayOf<Device>) {
            self.periods = periods
            self.devices = devices
            @Dependency(\.date) var date
            self.date = date()
            now = date()
            dateRange = date()...date().addingTimeInterval(60 * 60 * 24 * 2)
            mode = .startDate
        }
    }

    public enum Mode {
        case startDate
        case endDate
    }

    public enum Action: Equatable, BindableAction {
        case binding(BindingAction<State>)
        case task
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
    }

    private func updateDeviceProgramPeriods(state: inout State) -> Effect<Action> {
        state.extraMinutesFromNow = date().distance(to: state.date) / 60
        state.deviceProgramPeriods = IdentifiedArray(uniqueElements: state.periods.map { period in
            state.devices.map { device in
                device.programs.compactMap { program -> DeviceProgramPeriod.State? in
                    let start: Date
                    let end: Date
                    switch state.mode {
                    case .startDate:
                        start = state.date
                        end = start.addingTimeInterval(program.duration)
                    case .endDate:
                        end = state.date
                        start = end.addingTimeInterval(-program.duration)
                    }

                    guard start.distance(to: end) > 0, (period.start...period.end).overlaps(start...end)
                    else { return nil }

                    let distanceToOffPeakStart = start.distance(to: period.start)
                    let distanceFromOffPeakEnd = period.end.distance(to: end)

                    let peakDuration = max(distanceToOffPeakStart, 0) + max(distanceFromOffPeakEnd, 0)

                    let id = device.id.uuidString + program.id.uuidString
                    return DeviceProgramPeriod.State(
                        device: device,
                        program: program,
                        start: start,
                        end: end,
                        offPeakRatio: 1 - (peakDuration / start.distance(to: end)),
                        isTimersShown: state.deviceProgramPeriods[id: id]?.isTimersShown ?? false
                    )
                }
            }
        }.flatMap { $0 }.flatMap { $0 })
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
                    Picker("Mode", selection: viewStore.binding(\.$mode)) {
                        Text("Start").tag(DeviceProgramPeriods.Mode.startDate)
                        Text("End").tag(DeviceProgramPeriods.Mode.endDate)
                    }
                    .pickerStyle(.segmented)
                    DatePicker(
                        selection: viewStore.binding(\.$date),
                        in: viewStore.dateRange,
                        displayedComponents: [.date, .hourAndMinute]
                    ) {
                        Text("Date & time")
                    }
                    Slider(value: viewStore.binding(\.$extraMinutesFromNow), in: 0...2880) {
                        Text("Extra minutes")
                    }
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
            .task { viewStore.send(.task) }
        }
    }
}

#if DEBUG
struct DeviceProgramPeriodsView_Previews: PreviewProvider {
    static var previews: some View {
        DeviceProgramPeriodsView(
            store: Store(
                initialState: DeviceProgramPeriods.State(
                    periods: [
                        OffPeakPeriod(start: Date().addingTimeInterval(-60 * 60 * 10), end: Date().addingTimeInterval(-60 * 60 * 8)),
                        OffPeakPeriod(start: Date().addingTimeInterval(60 * 60 * 2), end: Date().addingTimeInterval(60 * 60 * 4)),
                        OffPeakPeriod(start: Date().addingTimeInterval(60 * 60 * 10), end: Date().addingTimeInterval(60 * 60 * 12)),
                    ],
                    devices: [.dishwasher, .washingMachine]
                ),
                reducer: DeviceProgramPeriods()
            )
        )
    }
}
#endif
