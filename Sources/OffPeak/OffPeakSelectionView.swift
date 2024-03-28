import ComposableArchitecture
import Models
import SendNotification
import SwiftUI

@Reducer
public struct OffPeakSelection: Reducer {
    @ObservableState
    public struct State: Equatable {
        public var peakStatus: PeakStatus = .unavailable
        public var periods = IdentifiedArrayOf<Period>(uniqueElements: [Period].example)
        public var minute: Double = .zero
        public var sendNotification = SendNotification.State()
        @Presents public var periodForm: PeriodForm.State?
    }
    public enum Action: Equatable {
        case addPeriodButtonTapped
        case editPeriod(Period)
        case updateMinute(Double)
        case periodForm(PresentationAction<PeriodForm.Action>)
        case sendNotification(SendNotification.Action)
        case task
    }

    @Dependency(\.calendar) var calendar
    @Dependency(\.continuousClock) var clock
    @Dependency(\.date.now) var now
    @Dependency(\.uuid) var uuid

    public var body: some ReducerOf<Self> {
        Scope(state: \.sendNotification, action: \.sendNotification) {
            SendNotification()
        }

        Reduce {
            state,
            action in
            switch action {
            case .addPeriodButtonTapped:
                state.periodForm = PeriodForm.State(
                    period: Period(
                        id: uuid(),
                        startHour: 0,
                        startMinute: 0,
                        endHour: 0,
                        endMinute: 0
                    )
                )
                return .none
            case let .editPeriod(period):
                state.periodForm = PeriodForm.State(period: period)
                return .none

            case let .updateMinute(minute):
                state.minute = minute
                return .concatenate(updatePeakStatus(&state), updateSendNotification(&state))

            case .periodForm(.presented(.save)):
                guard let period = state.periodForm?.period else { return .none }
                state.periods.updateOrAppend(period)
                state.periodForm = nil
                return .concatenate(updatePeakStatus(&state), updateSendNotification(&state))

            case .periodForm:
                return .none

            case .sendNotification:
                return .none

            case .task:
                let minute = {
                    Double(calendar.component(.hour, from: now) * 60 + calendar.component(.minute, from: now))
                }
                return .run { send in
                    await send(.updateMinute(minute()))
                    for await _ in clock.timer(interval: .seconds(60)) {
                        await send(.updateMinute(minute()))
                    }
                }
            }
        }
        .ifLet(\.$periodForm, action: \.periodForm) {
            PeriodForm()
        }
    }

    private func updatePeakStatus(_ state: inout State) -> Effect<Action> {
        let offPeakRanges = [ClosedRange<Date>].nextOffPeakRanges(state.periods.elements, now: now, calendar: calendar)
        state.peakStatus = if let currentOffPeak = offPeakRanges.first(where: { $0.contains(now) }) {
            .offPeak(until: .seconds(now.distance(to: currentOffPeak.upperBound)))
        } else if let closestOffPeak = offPeakRanges.first(where: { now.distance(to: $0.lowerBound) > 0 }) {
            .peak(until: .seconds(now.distance(to: closestOffPeak.lowerBound)))
        } else {
            .unavailable
        }
        return .none
    }

    private func updateSendNotification(_ state: inout State) -> Effect<Action> {
        switch state.peakStatus {
        case let .offPeak(until):
            state.sendNotification.intent = .offPeakEnd(durationBeforePeak: until)
            return .none
        case let .peak(until):
            state.sendNotification.intent = .offPeakStart(durationBeforeOffPeak: until)
            return .none
        case .unavailable:
            return .none
        }
    }
}

public struct OffPeakSelectionView: View {
    @Bindable var store: StoreOf<OffPeakSelection>
    @Environment(\.colorScheme) private var colorScheme

    private struct ViewState: Equatable {
        let peakStatus: PeakStatus
        let periods: IdentifiedArrayOf<Period>
        let minute: Double

        init(_ state: OffPeakSelection.State) {
            peakStatus = state.peakStatus
            periods = state.periods
            minute = state.minute
        }
    }

    public var body: some View {
        Form {
            Section("Periods") {

                HStack {
                    Spacer()
                    ClockView(minute: store.minute, periods: store.periods.elements)
                        .frame(width: 250, height: 250, alignment: .center)
                    Spacer()
                }

                ForEach(store.periods) { period in
                    Button { store.send(.editPeriod(period)) } label: {
                        HStack {
                            PeriodView(period: period)
                            Spacer()
                            Label("Edit", systemImage: "pencil").labelStyle(.iconOnly)
                        }
                    }
                }
                Button { store.send(.addPeriodButtonTapped) } label: {
                    Label("Add off peak period", systemImage: "plus.circle")
                }
            }

            Section("Peak status") {
                VStack(alignment: .leading) {
                    switch store.peakStatus {
                    case .offPeak:
                        Text("Currently off peak")
                        SendNotificationButtonView(
                            store: store.scope(state: \.sendNotification, action: \.sendNotification)
                        )
                        .padding(.vertical)
                    case .peak:
                        Text("Currently peak hours")
                        SendNotificationButtonView(
                            store: store.scope(state: \.sendNotification, action: \.sendNotification)
                        )
                        .padding(.vertical)
                    case .unavailable:
                        Text("Calculating status...").redacted(reason: .placeholder)
                    }
                }
            }
        }
        .sheet(item: $store.scope(state: \.periodForm, action: \.periodForm)) { store in
            NavigationStack {
                PeriodFormView(store: store)
            }
        }
        .navigationTitle("Off peak periods")
        .task { await store.send(.task).finish() }
    }
}

#Preview {
    NavigationStack {
        OffPeakSelectionView(store: Store(initialState: OffPeakSelection.State()) {
            OffPeakSelection()
        })
    }
}

#Preview {
    NavigationStack {
        OffPeakSelectionView(store: Store(initialState: OffPeakSelection.State()) {
            OffPeakSelection().dependency(\.date, .constant(Date(timeIntervalSince1970: 5000)))
        })
    }
}
