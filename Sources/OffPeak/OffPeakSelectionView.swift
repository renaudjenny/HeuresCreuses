import ComposableArchitecture
import Models
import SendNotification
import SwiftUI

@Reducer
public struct OffPeakSelection: Reducer {
    public struct State: Equatable {
        public var peakStatus: PeakStatus = .unavailable
        public var periods = IdentifiedArrayOf<Period>(uniqueElements: [Period].example)
        public var minute: Double = .zero
        public var sendNotification = SendNotification.State()
    }
    public enum Action: Equatable {
        case updateMinute(Double)
        case sendNotification(SendNotification.Action)
        case task
    }

    @Dependency(\.calendar) var calendar
    @Dependency(\.continuousClock) var clock
    @Dependency(\.date.now) var now

    public var body: some ReducerOf<Self> {
        Scope(state: \.sendNotification, action: /Action.sendNotification) {
            SendNotification()
        }

        Reduce { state, action in
            switch action {
            case let .updateMinute(minute):
                state.minute = minute
                return .concatenate(updatePeakStatus(&state), updateSendNotification(&state))

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
    let store: StoreOf<OffPeakSelection>
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
        WithViewStore(store, observe: ViewState.init) { viewStore in
            Form {
                Section("Periods") {
                    clockWidgetView(periods: viewStore.periods.elements, minute: viewStore.minute)
                    ForEach(viewStore.periods) { period in
                        period.clockView
                    }
                }

                Section("Peak status") {
                    VStack(alignment: .leading) {
                        switch viewStore.peakStatus {
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
            .navigationTitle("Off peak periods")
            .task { await viewStore.send(.task).finish() }
        }
    }

    private func clockWidgetView(periods: [Period], minute: Double) -> some View {
        ZStack {
            Circle()
                .fill(Color.primary.opacity(15/100))
            Circle()
                .scale(75/100)
                .fill(backgroundColor)

            ForEach(periods) { period in
                clockWidgetPeriod(period)
            }

            clockWidgetIndicators(minute: minute)
            clockWidgetNumbersView
        }
        .padding()
    }

    private func clockWidgetPeriod(_ period: Period) -> some View {
        GeometryReader { geometryProxy in
            Circle()
                .rotation(.radians(-.pi/2))
                .trim(from: period.relativeClockPosition.start, to: period.relativeClockPosition.end)
                .stroke(Color.green, style: StrokeStyle(lineWidth: geometryProxy.size.width * 10/100, lineCap: .round))
                .padding(geometryProxy.size.width * 6.3/100)
        }
    }

    private func clockWidgetIndicators(minute: Double) -> some View {
        GeometryReader { geometryProxy in
            let angle: Double = (2 * .pi)/Double(24 * 60) * Double(minute) - .pi/2
            let radius = min(geometryProxy.size.width, geometryProxy.size.height) * 40/100
            Rectangle()
                .size(CGSize(width: 2, height: geometryProxy.size.height * 7/100))
                .fill(Color.accentColor)
                .position(
                    x: geometryProxy.size.width - 1,
                    y: geometryProxy.size.height
                )
                .rotationEffect(.radians(angle - .pi/2))
                .position(
                    x: cos(angle) * radius + geometryProxy.size.width/2,
                    y: sin(angle) * radius + geometryProxy.size.height/2
                )

            ForEach(0..<96) { i in
                Rectangle()
                    .size(CGSize(width: 1, height: i % 4 == 0 ? 6 : 2))
                    .offset(CGSize(width: geometryProxy.size.width / 2, height: geometryProxy.size.width / 6))
                    .rotation(.degrees(360 / 96 * Double(i)))
                    .fill(Color.primary.opacity(50/100))
            }
        }
    }

    private var clockWidgetNumbersView: some View {
        GeometryReader { geometryProxy in
            ForEach(0..<23) { i in
                if i % 2 == 0 {
                    let angle: Double = (2 * .pi)/24 * Double(i) - .pi/2
                    let radius = min(geometryProxy.size.width, geometryProxy.size.height) * 28/100

                    Text("\(i)")
                        .position(
                            x: cos(angle) * radius + geometryProxy.size.width/2,
                            y: sin(angle) * radius + geometryProxy.size.height/2
                        )
                        .foregroundStyle(i % 6 == 0 ? Color.primary : Color.secondary)
                }
            }
        }
    }

    private var backgroundColor: Color { colorScheme == .dark ? .black : .white }
}

private extension Period {
    var dateFormatted: (start: String, end: String) {
        @Dependency(\.calendar) var calendar
        @Dependency(\.date.now) var now

        guard let range = ranges(from: now, calendar: calendar).first else { return ("", "") }
        return (
            start: range.lowerBound.formatted(date: .omitted, time: .shortened),
            end: range.upperBound.formatted(date: .omitted, time: .shortened)
        )
    }

    var relativeClockPosition: (start: Double, end: Double) {
        @Dependency(\.calendar) var calendar
        @Dependency(\.date.now) var now

        let maxMinutes = 24.0 * 60.0
        guard let range = ranges(from: now, calendar: calendar).first else { return (0, 0) }
        return (
            start: range.lowerBound.minutes(calendar: calendar)/maxMinutes,
            end: range.upperBound.minutes(calendar: calendar)/maxMinutes
        )
    }
}

private extension Date {
    func minutes(calendar: Calendar) -> Double {
        Double(calendar.component(.hour, from: self)) * 60 + Double(calendar.component(.minute, from: self))
    }
}

private extension Period {
    var clockView: some View {
        HStack {
            ZStack {
                Circle()
                    .stroke(Color.primary.opacity(25/100), lineWidth: 5)
                    .frame(width: 40, height: 40)
                Circle()
                    .rotation(.radians(-.pi/2))
                    .trim(from: relativeClockPosition.start, to: relativeClockPosition.end)
                    .stroke(Color.green, lineWidth: 5)
                    .frame(width: 40, height: 40)
            }
            Text(dateFormatted.start).monospacedDigit()
            Image(systemName: "arrowshape.forward")
            Text(dateFormatted.end).monospacedDigit()
        }
        .accessibilityLabel(
            Text("\(dateFormatted.start) to \(dateFormatted.end)", comment: "<Hour:Minutes> to <Hour:Minutes>")
        )
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
