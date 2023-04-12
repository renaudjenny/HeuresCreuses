import ComposableArchitecture
import Foundation
import SwiftUI

public struct App: ReducerProtocol {
    public struct State: Equatable {
        let periods: [Period] = [
            Period(start: DateComponents(hour: 23, minute: 24), end: DateComponents(hour: 7, minute: 24))
        ]

        var date: Date = .distantPast
        var currentPeakStatus: PeakStatus = .unavailable
    }

    public struct Period: Equatable {
        let start: DateComponents
        let end: DateComponents
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
                updateCurrentPeakStatus(state: &state),
                .run { send in
                    for await _ in clock.timer(interval: .seconds(1)) {
                        await send(.timeChanged(date()))
                    }
                }
            )
            .cancellable(id: TimerTaskID.self)
        case let .timeChanged(date):
            state.date = date
            return updateCurrentPeakStatus(state: &state)
        case .cancel:
            return .cancel(id: TimerTaskID.self)
        }
    }

    private func updateCurrentPeakStatus(state: inout State) -> EffectTask<Action> {
        // TODO: Should be determined directly after editing the periods, not here.
        var todayDates: [(start: Date, end: Date)] = []
        for period in state.periods {
            for day in -1...1 {
                let day = TimeInterval(day)
                var start = period.start
                start.year = calendar.component(.year, from: date())
                start.month = calendar.component(.month, from: date())
                start.day = calendar.component(.day, from: date().addingTimeInterval(day * 60 * 60 * 24))
                var end = period.end
                end.year = calendar.component(.year, from: date())
                end.month = calendar.component(.month, from: date())
                end.day = calendar.component(.day, from: date().addingTimeInterval(day * 60 * 60 * 24))

                guard let offPeakStartDate = calendar.date(from: start),
                      let offPeakEndDate = calendar.date(from: end)
                else { continue }
                if offPeakEndDate > offPeakStartDate {
                    todayDates.append((start: offPeakStartDate, end: offPeakEndDate))
                } else {
                    todayDates.append((start: offPeakStartDate, end: offPeakEndDate.addingTimeInterval(60 * 60 * 24)))
                }
            }
        }
        print(date(), todayDates)
        // Move the code above to be executed less times

        if let currentDate = todayDates.first(where: { ($0...$1).contains(state.date) }) {
            state.currentPeakStatus = .offPeak(until: .seconds(date().distance(to: currentDate.end)))
            return .none
        } else {
            guard let closestOffPeak = todayDates.first(where: { date().distance(to: $0.start) > 0 })
            else { return .none }
            state.currentPeakStatus = .peak(until: .seconds(date().distance(to: closestOffPeak.start)))
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
            self.peakStatus = state.currentPeakStatus
            switch state.currentPeakStatus {
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
