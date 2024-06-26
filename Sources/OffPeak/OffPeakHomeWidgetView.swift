import ComposableArchitecture
import HomeWidget
import Models
import SwiftUI

@Reducer
public struct OffPeakHomeWidget {
    @ObservableState
    public struct State: Equatable {
        @Presents public var destination: OffPeakSelection.State?
        public var peakStatus = PeakStatus.unavailable
        public var offPeakRanges: [ClosedRange<Date>] = []
        @Shared(.periods) public var periods: IdentifiedArrayOf<Period>

        public init(
            peakStatus: PeakStatus = PeakStatus.unavailable,
            offPeakRanges: [ClosedRange<Date>] = [],
            periods: IdentifiedArrayOf<Period> = IdentifiedArray(uniqueElements: [Period].example)
        ) {
            self.peakStatus = peakStatus
            self.offPeakRanges = offPeakRanges
            self._periods = Shared(wrappedValue: periods, .periods)
        }
    }
    
    public enum Action: Equatable {
        case cancelTimer
        case destination(PresentationAction<OffPeakSelection.Action>)
        case task
        case timeChanged(Date)
        case widgetTapped
    }
    
    private enum CancelID { case timer }

    @Dependency(\.date) var date
    @Dependency(\.calendar) var calendar
    @Dependency(\.continuousClock) var clock

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .cancelTimer:
                return .cancel(id: CancelID.timer)

            case .destination:
                return .none

            case .task:
                state.offPeakRanges = .nextOffPeakRanges(state.periods.elements, now: date(), calendar: calendar)
                return .run { send in
                    for await _ in clock.timer(interval: .seconds(1)) {
                        await send(.timeChanged(date()), animation: .default)
                    }
                }
                .cancellable(id: CancelID.timer)

            case let .timeChanged(date):
                if let currentOffPeak = state.offPeakRanges.first(where: { $0.contains(self.date()) }) {
                    state.peakStatus = .offPeak(until: .seconds(date.distance(to: currentOffPeak.upperBound)))
                    return .none
                } else {
                    guard let closestOffPeak = state.offPeakRanges
                        .first(where: { date.distance(to: $0.lowerBound) > 0 })
                    else { return .none }
                    state.peakStatus = .peak(until: .seconds(date.distance(to: closestOffPeak.lowerBound)))
                    return .none
                }

            case .widgetTapped:
                state.destination = OffPeakSelection.State()
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination) {
            OffPeakSelection()
        }
    }
}

public struct OffPeakHomeWidgetView: View {
    @Bindable var store: StoreOf<OffPeakHomeWidget>

    public init(store: StoreOf<OffPeakHomeWidget>) {
        self.store = store
    }

    public var body: some View {
        Button { store.send(.widgetTapped) } label: {
            HomeWidgetView(title: "Off Peak hours", icon: Image(systemName: "arrow.up.circle.badge.clock")) {
                VStack {
                    switch store.peakStatus {
                    case .unavailable:
                        Text("Wait a sec...").font(.body)
                    case let .offPeak(duration):
                        VStack(alignment: .leading) {
                            Text("Currently **off peak**")
                            Text(relativeNextChange(duration)).font(.headline)
                        }
                    case let .peak(duration):
                        VStack(alignment: .leading) {
                            Text("Currently **peak** hour")
                            Text(relativeNextChange(duration)).font(.headline)
                        }
                    }
                }
            }
        }
        .buttonStyle(.plain)
        .navigationDestination(
            item: $store.scope(state: \.destination, action: \.destination),
            destination: OffPeakSelectionView.init
        )
        .listRowBackground(color(for: store.peakStatus))
        .task { @MainActor in await store.send(.task).finish() }
    }

    private func relativeNextChange(_ duration: Duration) -> String {
        "Until \(duration.formatted(.units(allowed: [.hours, .minutes], width: .wide)))"
    }

    private func color(for peakStatus: PeakStatus) -> Color? {
        switch peakStatus {
        case .offPeak: .green.opacity(20/100)
        case .peak: .red.opacity(20/100)
        case .unavailable: nil
        }
    }
}

#Preview {
    NavigationStack {
        List {
            OffPeakHomeWidgetView(
                store: Store(initialState: OffPeakHomeWidget.State()) {
                    OffPeakHomeWidget()
                }
            )
            OffPeakHomeWidgetView(store: Store(initialState: OffPeakHomeWidget.State()) {
                OffPeakHomeWidget()
                    .dependency(\.continuousClock, TestClock())
            })
            OffPeakHomeWidgetView(
                store: Store(initialState: OffPeakHomeWidget.State()) {
                    OffPeakHomeWidget()
                        .dependency(\.date, .constant(
                            try! Date("2023-10-09T04:00:00+02:00", strategy: .iso8601)
                        ))
                }
            )
            OffPeakHomeWidgetView(
                store: Store(initialState: OffPeakHomeWidget.State()) {
                    OffPeakHomeWidget()
                        .dependency(\.date, .constant(
                            try! Date("2023-10-09T22:00:00+02:00", strategy: .iso8601)
                        ))
                }
            )
        }
        #if os(iOS)
        .listRowSpacing(8)
        #endif
    }
}
