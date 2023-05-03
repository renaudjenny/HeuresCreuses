import ComposableArchitecture
import Models
import SwiftUI

public struct DeviceProgramPeriods: Reducer {
    public struct State: Equatable {
        var periods: [OffPeakPeriod]
        var devices: IdentifiedArrayOf<Device>
        var deviceProgramPeriods: IdentifiedArrayOf<DeviceProgramPeriod> = []

        public init(periods: [OffPeakPeriod], devices: IdentifiedArrayOf<Device>) {
            self.periods = periods
            self.devices = devices
        }
    }

    struct DeviceProgramPeriod: Identifiable, Equatable {
        var id: String { device.id.uuidString + program.id.uuidString }
        let device: Device
        let program: Program
        var start: Date
        var end: Date
        var offPeakRatio: Double
    }

    public enum Action: Equatable {
        case task
    }

    @Dependency(\.date) var date

    public func reduce(into state: inout State, action: Action) -> Effect<Action> {
        switch action {
        case .task:
            state.deviceProgramPeriods = IdentifiedArray(uniqueElements: state.periods.map { period in
                state.devices.map { device in
                    device.programs.compactMap { program -> DeviceProgramPeriod? in
                        let start = date()
                        let end = start.addingTimeInterval(program.duration)

                        guard start.distance(to: end) > 0, (period.start...period.end).overlaps(start...end)
                        else { return nil }

                        let distanceToOffPeakStart = start.distance(to: period.start)
                        let distanceFromOffPeakEnd = period.end.distance(to: end)

                        let peakDuration = max(distanceToOffPeakStart, 0) + max(distanceFromOffPeakEnd, 0)

                        return DeviceProgramPeriod(
                            device: device,
                            program: program,
                            start: start,
                            end: end,
                            offPeakRatio: 1 - (peakDuration / start.distance(to: end))
                        )
                    }
                }
            }.flatMap { $0 }.flatMap { $0 })
            return .none
        }
    }
}

public struct DeviceProgramPeriodsView: View {
    let store: StoreOf<DeviceProgramPeriods>

    public init(store: StoreOf<DeviceProgramPeriods>) {
        self.store = store
    }

    public var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            ScrollView {
                ForEach(viewStore.deviceProgramPeriods) { deviceProgramPeriod in
                    VStack {
                        Text("\(deviceProgramPeriod.device.name) - \(deviceProgramPeriod.program.name)").font(.headline)
                        Text("Duration: \((deviceProgramPeriod.start.distance(to: deviceProgramPeriod.end)/(60)).formatted()) minutes")
                        Text("\(deviceProgramPeriod.start.formatted(date: .omitted, time: .shortened)) - \(deviceProgramPeriod.end.formatted(date: .omitted, time: .shortened))")
                        Text("\(deviceProgramPeriod.offPeakRatio.formatted(.percent))")
                    }
                    .padding()
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