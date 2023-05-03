import ComposableArchitecture
import DevicesFeature
import Foundation
import Models
import SwiftUI

public struct App: ReducerProtocol {
    public struct State: Equatable {
        let periods: [Period] = [
            Period(start: DateComponents(hour: 2, minute: 2), end: DateComponents(hour: 8, minute: 2)),
            Period(start: DateComponents(hour: 15, minute: 2), end: DateComponents(hour: 17, minute: 2)),
        ]

        var date: Date = .distantPast
        var currentPeakStatus: PeakStatus = .unavailable

        var offPeakPeriods: [OffPeakPeriod] = []
        var devices = Devices.State()
    }

    public enum Action: Equatable {
        case task
        case timeChanged(Date)
        case cancel
    }

    public enum PeakStatus: Equatable {
        case offPeak(until: Duration)
        case peak(until: Duration)
        case unavailable
    }

    @Dependency(\.date) var date
    @Dependency(\.calendar) var calendar
    @Dependency(\.continuousClock) var clock

    private enum TimerTaskID {}

    public func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
        switch action {
        case .task:
            state.date = date()
            return .merge(
                updateOffPeakPeriods(state: &state),
                .run { send in
                    for await _ in clock.timer(interval: .seconds(1)) {
                        await send(.timeChanged(date()))
                    }
                }
            )
            .cancellable(id: TimerTaskID.self)
        case let .timeChanged(date):
            state.date = date
            if let currentOffPeak = state.offPeakPeriods.first(where: { ($0.start...$0.end).contains(state.date) }) {
                state.currentPeakStatus = .offPeak(until: .seconds(date.distance(to: currentOffPeak.end)))
                return .none
            } else {
                guard let closestOffPeak = state.offPeakPeriods.first(where: { date.distance(to: $0.start) > 0 })
                else { return .none }
                state.currentPeakStatus = .peak(until: .seconds(date.distance(to: closestOffPeak.start)))
                return .none
            }
        case .cancel:
            return .cancel(id: TimerTaskID.self)
        }
    }

    private func updateOffPeakPeriods(state: inout State) -> EffectTask<Action> {
        for period in state.periods {
            var start = period.start
            start.year = calendar.component(.year, from: date())
            start.month = calendar.component(.month, from: date())
            start.day = calendar.component(.day, from: date())
            var end = period.end
            end.year = calendar.component(.year, from: date())
            end.month = calendar.component(.month, from: date())
            end.day = calendar.component(.day, from: date())

            for day in -1...1 {
                let day = TimeInterval(day)
                guard let offPeakStartDate = calendar.date(from: start)?.addingTimeInterval(day * 60 * 60 * 24),
                      let offPeakEndDate = calendar.date(from: end)?.addingTimeInterval(day * 60 * 60 * 24)
                else { continue }
                if offPeakEndDate > offPeakStartDate {
                    state.offPeakPeriods.append(OffPeakPeriod(start: offPeakStartDate, end: offPeakEndDate))
                } else {
                    let offPeakEndDate = offPeakEndDate.addingTimeInterval(60 * 60 * 24)
                    state.offPeakPeriods.append(OffPeakPeriod(start: offPeakStartDate, end: offPeakEndDate))
                }
            }
        }
        return .none
    }
}

private extension Date {
    func toMidnight(calendar: Calendar) -> Date {
        calendar.startOfDay(for: self).addingTimeInterval(60 * 60 * 24)
    }
}

public struct AppView: View {
    struct ViewState: Equatable {
        let peakStatus: App.PeakStatus
        let formattedDuration: String

        // TODO: Move this one into its own Feature
        let devices: IdentifiedArrayOf<EditDevice.State>

        init(_ state: App.State) {
            self.peakStatus = state.currentPeakStatus
            switch state.currentPeakStatus {
            case .unavailable:
                self.formattedDuration = ""
            case let .offPeak(until: duration):
                self.formattedDuration = duration.formatted(.units(allowed: [.hours, .minutes], width: .wide))
            case let .peak(until: duration):
                self.formattedDuration = duration.formatted(.units(allowed: [.hours, .minutes], width: .wide))
            }
            self.devices = state.devices.devices
        }
    }

    let store: StoreOf<App>

    public init(store: StoreOf<App>) {
        self.store = store
    }

    public var body: some View {
        WithViewStore(store, observe: ViewState.init) { viewStore in
            VStack {
                switch viewStore.peakStatus {
                case .unavailable:
                    Text("Wait a sec...")
                case .offPeak:
                    Text("Currently **off peak** until \(viewStore.formattedDuration)")
                        .multilineTextAlignment(.center)
                case .peak:
                    Text("Currently **peak** hour until \(viewStore.formattedDuration)")
                        .multilineTextAlignment(.center)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                switch viewStore.peakStatus {
                case .unavailable:
                    Color.clear
                case .peak:
                    Color.red.opacity(20/100).ignoresSafeArea(.all)
                case .offPeak:
                    Color.green.opacity(20/100).ignoresSafeArea(.all)
                }
            }
            .task { viewStore.send(.task) }

            // TODO: Move that into its own Feature
            Divider()

            ScrollView {
                ForEach(viewStore.devices) { device in
                    Text(device.device.name).font(.title)

                    VStack {
                        ForEach(device.device.programs) { program in
                            VStack {
                                Text("Program - \(program.name)").font(.headline)
                                Text("\(program.duration.formatted())")
                            }
                            .padding()
                        }
                    }
                }
            }
        }
    }
}

public extension Store where State == App.State, Action == App.Action {
    static var live: StoreOf<App> {
        Store(initialState: State(), reducer: App()._printChanges())
    }
}

#if DEBUG
struct AppView_Previews: PreviewProvider {
    static var previews: some View {
        Preview(store: Store(initialState: App.State(), reducer: App()))
        Preview(store: Store(
            initialState: App.State(),
            reducer: App().dependency(\.date, DateGenerator { try! Date("2023-04-10T23:50:00+02:00", strategy: .iso8601) })
        ))
        .previewDisplayName("At 23:50")

        Preview(store: Store(
            initialState: App.State(),
            reducer: App().dependency(\.date, DateGenerator { try! Date("2023-04-10T00:10:00+02:00", strategy: .iso8601) })
        ))
        .previewDisplayName("At 00:10")

        Preview(store: Store(
            initialState: App.State(),
            reducer: App().dependency(\.date, DateGenerator { try! Date("2023-04-10T02:10:00+02:00", strategy: .iso8601) })
        ))
        .previewDisplayName("At 02:10")

        Preview(store: Store(
            initialState: App.State(),
            reducer: App().dependency(\.date, DateGenerator { try! Date("2023-04-10T16:00:00+02:00", strategy: .iso8601) })
        ))
        .previewDisplayName("At 16:00")
    }

    private struct Preview: View {
        let store: StoreOf<App>

        var body: some View {
            WithViewStore(store, observe: { $0 }) { viewStore in
                VStack {
                    AppView(store: store)
//                    Divider()
//                    Text("Current time: \(viewStore.date.formatted())")
                }
            }
        }
    }
}
#endif
