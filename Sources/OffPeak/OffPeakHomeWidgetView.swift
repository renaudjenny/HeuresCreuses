import ComposableArchitecture
import HomeWidget
import Models
import SendNotification
import SwiftUI

public struct OffPeakHomeWidget: Reducer {
    public struct State: Equatable {
        public var peakStatus = PeakStatus.unavailable
        var offPeakRanges: [ClosedRange<Date>] = []
        var periods: [Period] = .example
        var sendNotification = SendNotification.State()

        public init(
            peakStatus: PeakStatus = PeakStatus.unavailable,
            offPeakRanges: [ClosedRange<Date>] = [],
            periods: [Period] = .example
        ) {
            self.peakStatus = peakStatus
            self.offPeakRanges = offPeakRanges
            self.periods = periods
        }
    }
    
    public enum Action: Equatable {
        case sendNotification(SendNotification.Action)
        case task
        case timeChanged(Date)
    }
    
    private enum CancelID { case timer }

    @Dependency(\.date) var date
    @Dependency(\.calendar) var calendar
    @Dependency(\.continuousClock) var clock

    public init() {}

    public var body: some ReducerOf<Self> {
        Scope(state: \.sendNotification, action: /Action.sendNotification) {
            SendNotification()
        }

        Reduce { state, action in
            switch action {
            case .sendNotification:
                return .none
            case .task:
                state.offPeakRanges = .offPeakRanges(state.periods, now: date(), calendar: calendar)
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
                    return updateSendNotification(&state)
                }
            }
        }
    }

    private func updateSendNotification(_ state: inout State) -> Effect<Action> {
        guard case let .peak(duration) = state.peakStatus else { return .none }
        state.sendNotification.intent = .offPeakStart(durationBeforeOffPeak: duration)
        return .none
    }
}

public struct OffPeakHomeWidgetView: View {
    public let store: StoreOf<OffPeakHomeWidget>

    private struct ViewState: Equatable {
        let peakStatus: PeakStatus

        init(_ state: OffPeakHomeWidget.State) {
            peakStatus = state.peakStatus
        }
    }

    public init(store: StoreOf<OffPeakHomeWidget>) {
        self.store = store
    }

    public var body: some View {
        WithViewStore(store, observe: ViewState.init) { viewStore in
            HomeWidgetView(title: "Off Peak hours", icon: Image(systemName: "arrow.up.circle.badge.clock")) {
                VStack {
                    switch viewStore.peakStatus {
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
            .background(alignment: .bottomTrailing) {
                if case .peak = viewStore.peakStatus {
                    SendNotificationButtonView(
                        store: store.scope(state: \.sendNotification, action: { .sendNotification($0) })
                    )
                    .labelStyle(.iconOnly)
                    .padding(.vertical)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .contentShape(RoundedRectangle(cornerRadius: 10))
                }
            }
            .listRowBackground(color(for: viewStore.peakStatus))
            .task { @MainActor in await viewStore.send(.task).finish() }
        }
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
    .listRowSpacing(8)
}
