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
                clockWidgetView(periods: store.periods.elements, minute: store.minute)
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

    private func clockWidgetView(periods: [Period], minute: Double) -> some View {
        ViewThatFits {
            clockWidthView(periods: periods, minute: minute, scale: 80.0/100.0)
                .padding()
                .frame(minWidth: 200)

            clockWidthView(periods: periods, minute: minute, scale: 85.0/100.0)
        }
    }

    private func clockWidthView(periods: [Period], minute: Double, scale: Double) -> some View {
        ZStack {
            Circle()
                .fill(Color.primary.opacity(15/100))
            Circle()
                .scale(scale)
                .fill(backgroundColor)

            ForEach(periods) { period in
                clockWidgetPeriod(period, scale: scale)
            }

            clockWidgetIndicators(minute: minute, scale: scale)
            clockWidgetNumbersView(scale: scale)
        }
    }

    private func clockWidgetPeriod(_ period: Period, scale: Double) -> some View {
        GeometryReader { geometryProxy in
            let radius = min(geometryProxy.size.width, geometryProxy.size.height)
            let lineWidth = radius * (1 - scale) * 40/100

            Circle()
                .rotation(.radians(-.pi/2))
                .trim(from: period.relativeClockPosition.start, to: period.relativeClockPosition.end)
                .stroke(Color.green, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .padding(lineWidth * 63/100)
        }
    }

    private func clockWidgetIndicators(minute: Double, scale: Double) -> some View {
        GeometryReader { geometryProxy in
            let angle: Double = (2.0 * .pi)/(24.0 * 60.0) * Double(minute) - .pi/2.0
            let indicatorHeight = min(geometryProxy.size.width, geometryProxy.size.height) * (1 - scale) * 30.0/100.0
            let radius = min(geometryProxy.size.width, geometryProxy.size.height) * scale * 54.0/100.0
            // TODO: Not right... find why
            let indicatorRadius = radius - (1 + 200/100 * scale)
            Rectangle()
                .size(CGSize(width: 2, height: indicatorHeight))
                .fill(Color.accentColor)
                .position(x: geometryProxy.size.width, y: geometryProxy.size.height)
                .rotationEffect(.radians(angle - .pi/2))
                .position(
                    x: cos(angle) * indicatorRadius + geometryProxy.size.width/2,
                    y: sin(angle) * indicatorRadius + geometryProxy.size.height/2
                )

            ForEach(0..<96) { i in
                let angle: Double = (2.0 * .pi)/(96.0) * Double(i) - .pi/2.0
                let radius = 83.0/100.0 * radius
                Rectangle()
                    .size(CGSize(width: 1, height: i % 4 == 0 ? 6 * scale : 2 * scale))
                    .fill(Color.primary.opacity(50/100))
                    .position(x: geometryProxy.size.width, y: geometryProxy.size.height)
                    .rotationEffect(.radians(angle - .pi/2))
                    .position(
                        x: cos(angle) * radius + geometryProxy.size.width/2,
                        y: sin(angle) * radius + geometryProxy.size.height/2
                    )
            }
        }
    }

    private func clockWidgetNumbersView(scale: Double) -> some View {
        GeometryReader { geometryProxy in
            ForEach(0..<23) { i in
                if i % 2 == 0 {
                    let angle: Double = (2.0 * .pi)/24.0 * Double(i) - .pi/2.0
                    let radius = min(geometryProxy.size.width, geometryProxy.size.height) * 35.0/100.0 * scale

                    Text("\(i)")
                        #if os(watchOS)
                        .font(.caption2)
                        #else
                        .font(.body)
                        #endif
                        .position(
                            x: cos(angle) * radius + geometryProxy.size.width/2.0,
                            y: sin(angle) * radius + geometryProxy.size.height/2.0
                        )
                        .foregroundStyle(i % 6 == 0 ? Color.primary : Color.secondary)
                }
            }
        }
    }

    private var backgroundColor: Color { colorScheme == .dark ? .black : .white }
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
