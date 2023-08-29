import ApplianceFeature
import ComposableArchitecture
import Foundation
import Models

public struct App: Reducer {
    public struct State: Equatable {
        let periods: [Period] = [
            Period(start: DateComponents(hour: 2, minute: 2), end: DateComponents(hour: 8, minute: 2)),
            Period(start: DateComponents(hour: 15, minute: 2), end: DateComponents(hour: 17, minute: 2)),
        ]

        var date: Date = .distantPast
        var currentPeakStatus: PeakStatus = .unavailable

        var offPeakRanges: [ClosedRange<Date>] = []
        @PresentationState var destination: Destination.State?
    }

    public struct Destination: Reducer {
        public enum State: Equatable {
            case applianceSelection(ApplianceSelection.State)
        }

        public enum Action: Equatable {
            case applianceSelection(ApplianceSelection.Action)
        }

        public var body: some ReducerOf<Self> {
            Scope(state: /State.applianceSelection, action: /Action.applianceSelection) {
                ApplianceSelection()
            }
        }
    }

    public enum Action: Equatable {
        case task
        case timeChanged(Date)
        case cancel
        case appliancesButtonTapped
        case destination(PresentationAction<Destination.Action>)
    }

    public enum PeakStatus: Equatable {
        case offPeak(until: Duration)
        case peak(until: Duration)
        case unavailable
    }

    @Dependency(\.date) var date
    @Dependency(\.calendar) var calendar
    @Dependency(\.continuousClock) var clock

    private enum CancelID { case timer }

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .task:
                state.date = date()
                state.offPeakRanges = .offPeakRanges(state.periods, now: date(), calendar: calendar)
                return .run { send in
                    for await _ in clock.timer(interval: .seconds(1)) {
                        await send(.timeChanged(date()))
                    }
                }
                .cancellable(id: CancelID.timer)
            case let .timeChanged(date):
                state.date = date
                if let currentOffPeak = state.offPeakRanges.first(where: { $0.contains(state.date) }) {
                    state.currentPeakStatus = .offPeak(until: .seconds(date.distance(to: currentOffPeak.upperBound)))
                    return .none
                } else {
                    guard let closestOffPeak = state.offPeakRanges
                        .first(where: { date.distance(to: $0.lowerBound) > 0 })
                    else { return .none }
                    state.currentPeakStatus = .peak(until: .seconds(date.distance(to: closestOffPeak.lowerBound)))
                    return .none
                }
            case .cancel:
                return .cancel(id: CancelID.timer)
            case .appliancesButtonTapped:
                state.destination = .applianceSelection(ApplianceSelection.State())
                return .none
            case .destination:
                return .none
            }
        }
        .ifLet(\.$destination, action: /App.Action.destination) {
            Destination()
        }
    }
}

public extension Store where State == App.State, Action == App.Action {
    static var live: StoreOf<App> {
        Store(initialState: State()) { App() }
    }
}
