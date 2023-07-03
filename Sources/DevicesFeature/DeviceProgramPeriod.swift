import ComposableArchitecture
import SwiftUI

public struct DeviceProgramPeriod: Reducer {
    public struct State: Equatable, Identifiable {
        public var id: String { device.id.uuidString + program.id.uuidString }
        public let device: Device
        public let program: Program
        public var start: Date
        public var end: Date
        public var offPeakRatio: Double
        @BindingState public var isTimersShown: Bool
        public var now: Date

        public init(
            device: Device,
            program: Program,
            start: Date,
            end: Date,
            offPeakRatio: Double,
            isTimersShown: Bool
        ) {
            self.device = device
            self.program = program
            self.start = start
            self.end = end
            self.offPeakRatio = offPeakRatio
            self.isTimersShown = isTimersShown
            @Dependency(\.date) var date
            self.now = date()
        }
    }

    public enum Action: Equatable, BindableAction {
        case binding(BindingAction<State>)
        case delegate(Delegate)
    }

    public enum Delegate: Equatable {
        case setDate(Date, mode: DeviceProgramPeriods.Mode)
    }

    public init() {}

    public var body: some ReducerOf<Self> {
        BindingReducer()
    }
}

public struct DeviceProgramPeriodView: View {

    let store: StoreOf<DeviceProgramPeriod>

    public init(store: StoreOf<DeviceProgramPeriod>) {
        self.store = store
    }

    public var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            VStack(alignment: .leading, spacing: 8) {
                let duration = Text("\((viewStore.start.distance(to: viewStore.end)/(60)).formatted()) minutes").font(.caption)
                Text(viewStore.device.name).font(.subheadline)
                Text("\(viewStore.program.name) - \(duration)").font(.headline)
                Text("\(viewStore.start.formatted(date: .omitted, time: .shortened)) - \(viewStore.end.formatted(date: .omitted, time: .shortened))")
                ProgressView(value: viewStore.offPeakRatio) { Text("**Offpeak ratio** - \(viewStore.offPeakRatio.formatted(.percent))") }

                Toggle("Show Timers", isOn: viewStore.binding(\.$isTimersShown))

                if viewStore.isTimersShown {
                    Divider()

                    if case let .timers(timers) = viewStore.device.delay {
                        deviceTimers(timers)
                    }
                }
            }
        }
    }

    private func deviceTimers(_ timers: [Delay.Timer]) -> some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            VStack(alignment: .leading) {
                Text("Timers from now")
                    .font(.headline)
                ForEach(timers) { timer in
                    HStack {
                        VStack(alignment: .leading) {
                            Text("\(timer.hour) hours\(timer.minute > 0 ? "\(timer.minute) minutes" : "")")
                            Text("\(viewStore.now.addingDelayTimer(timer).formatted(date: .omitted, time: .shortened))")
                        }

                        HStack {
                            Button { viewStore.send(.delegate(.setDate(
                                viewStore.now.addingDelayTimer(timer),
                                mode: .startDate
                            ))) } label: {
                                Label("Set as start date", systemImage: "arrowshape.turn.up.backward.badge.clock.rtl")
                                    .labelStyle(.iconOnly)
                            }
                            .buttonStyle(.plain)
                            .padding()

                            Button { viewStore.send(.delegate(.setDate(
                                viewStore.now.addingDelayTimer(timer),
                                mode: .endDate
                            ))) } label: {
                                Label("Set as end date", systemImage: "arrowshape.turn.up.backward.badge.clock")
                                    .labelStyle(.iconOnly)
                            }
                            .buttonStyle(.plain)
                            .padding()
                        }
                    }
                }
            }
        }
    }
}

private extension Date {
    func addingDelayTimer(_ timer: Delay.Timer) -> Date {
        let hoursInSeconds = Double(timer.hour) * 60 * 60
        let minutesInSeconds = Double(timer.minute * 60)
        return addingTimeInterval(hoursInSeconds + minutesInSeconds)
    }
}

#if DEBUG
struct DeviceProgramPeriodView_Previews: PreviewProvider {
    static var previews: some View {
        Form {
            Section("\(Device.dishwasher.name)") {
                DeviceProgramPeriodView(
                    store: Store(
                        initialState: DeviceProgramPeriod.State(
                            device: .dishwasher,
                            program: Device.dishwasher.programs.first!,
                            start: Date(),
                            end: Date().addingTimeInterval(Device.dishwasher.programs.first!.duration),
                            offPeakRatio: 50/100,
                            isTimersShown: false
                        ),
                        reducer: DeviceProgramPeriod()
                    )
                )
            }
        }
    }
}
#endif
