import ComposableArchitecture
import DevicesFeature
import Foundation
import Models

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
        @PresentationState var destination: DeviceProgramPeriods.State?
    }

    public enum Action: Equatable {
        case task
        case timeChanged(Date)
        case cancel
        case devicesButtonTapped
        case destination(PresentationAction<DeviceProgramPeriods.Action>)
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

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
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
            case .devicesButtonTapped:
                state.destination = DeviceProgramPeriods.State(
                    periods: state.offPeakPeriods,
                    devices: IdentifiedArrayOf(uniqueElements: state.devices.devices.map(\.device))
                )
                return .none
            case .destination:
                return .none
            }
        }
        .ifLet(\.$destination, action: /App.Action.destination) {
            DeviceProgramPeriods()
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

public extension Store where State == App.State, Action == App.Action {
    static var live: StoreOf<App> {
        Store(initialState: State(), reducer: App()._printChanges())
    }
}
