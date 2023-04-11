import ComposableArchitecture
import Foundation
import SwiftUI

public struct App: ReducerProtocol {
    public struct State: Equatable {
        let startHour = 7
        let startMinute = 24
        let endHour = 23
        let endMinute = 24

        var date: Date = .distantPast
        var peakStatus: PeakStatus = .unavailable
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
                updatePeakStatus(state: &state),
                .run { send in
                    for await _ in clock.timer(interval: .seconds(1)) {
                        await send(.timeChanged(date()))
                    }
                }
            )
            .cancellable(id: TimerTaskID.self)
        case let .timeChanged(date):
            state.date = date
            return updatePeakStatus(state: &state)
        case .cancel:
            return .cancel(id: TimerTaskID.self)
        }
    }

    private func updatePeakStatus(state: inout State) -> EffectTask<Action> {
        guard
            let todayPeakStartDate = calendar.date(
                bySettingHour: state.startHour,
                minute: state.startMinute,
                second: 0, of: state.date
            ),
            let todayPeakEndDate = calendar.date(
                bySettingHour: state.endHour,
                minute: state.endMinute,
                second: 0, of: state.date
            )
        else { return .none }
        let isPeakHour = (todayPeakStartDate...todayPeakEndDate).contains(state.date)
        switch (isPeakHour, now: date()) {
        case let (true, now) where now > todayPeakEndDate:
            let tomorrowPeakEndDate = todayPeakEndDate.addingTimeInterval(60 * 60 * 24)
            state.peakStatus = .peak(until: .seconds(now.distance(to: tomorrowPeakEndDate)))
            return .none
        case let (true, now):
            state.peakStatus = .peak(until: .seconds(now.distance(to: todayPeakEndDate)))
            return .none
        case let (false, now) where now > todayPeakStartDate:
            let tomorrowPeakStartDate = todayPeakStartDate.addingTimeInterval(60 * 60 * 24)
            state.peakStatus = .offPeak(until: .seconds(now.distance(to: tomorrowPeakStartDate)))
            return .none
        case let (false, now):
            state.peakStatus = .offPeak(until: .seconds(now.distance(to: todayPeakStartDate)))
            return .none
        }
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

        init(_ state: App.State) {
            self.peakStatus = state.peakStatus
            switch state.peakStatus {
            case .unavailable:
                self.formattedDuration = ""
            case let .offPeak(until: duration):
                self.formattedDuration = duration.formatted(.units(allowed: [.hours, .minutes], width: .wide))
            case let .peak(until: duration):
                self.formattedDuration = duration.formatted(.units(allowed: [.hours, .minutes], width: .wide))
            }
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
        }
    }
}

public extension Store where State == App.State, Action == App.Action {
    static var live: StoreOf<App> {
        Store(initialState: State(), reducer: App())
    }
}

#if DEBUG
struct AppView_Previews: PreviewProvider {
    static var previews: some View {
        AppView(store: Store(initialState: App.State(), reducer: App()))
        AppView(store: Store(
            initialState: App.State(),
            reducer: App().dependency(\.date, DateGenerator { try! Date("2023-04-10T23:25:00+02:00", strategy: .iso8601) })
        ))
        .previewDisplayName("Off peak before midnight")

        AppView(store: Store(
            initialState: App.State(),
            reducer: App().dependency(\.date, DateGenerator { try! Date("2023-04-10T02:25:00+02:00", strategy: .iso8601) })
        ))
        .previewDisplayName("Off peak after midnight")

        AppView(store: Store(
            initialState: App.State(),
            reducer: App().dependency(\.date, DateGenerator { try! Date("2023-04-10T20:25:00+02:00", strategy: .iso8601) })
        ))
        .previewDisplayName("Peak")
    }
}
#endif
