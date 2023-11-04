import ComposableArchitecture
import Models
import SwiftUI

public struct OffPeakSelection: Reducer {
    public struct State: Equatable {
        public var periods = IdentifiedArrayOf<Period>(uniqueElements: [Period].example)
        public var minute: Double = .zero
    }
    public enum Action: Equatable {
        case updateMinute(Double)
        case task
    }

    @Dependency(\.calendar) var calendar
    @Dependency(\.continuousClock) var clock
    @Dependency(\.date.now) var now

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .updateMinute(minute):
                state.minute = minute
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
}

public struct OffPeakSelectionView: View {
    let store: StoreOf<OffPeakSelection>
    @Environment(\.colorScheme) private var colorScheme

    private struct ViewState: Equatable {
        let periods: IdentifiedArrayOf<Period>
        let minute: Double

        init(_ state: OffPeakSelection.State) {
            periods = state.periods
            minute = state.minute
        }
    }

    public var body: some View {
        WithViewStore(store, observe: ViewState.init) { viewStore in
            Form {
                clockWidgetView(periods: viewStore.periods.elements, minute: viewStore.minute)
                ForEach(viewStore.periods) { period in
                    period.clockView
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
                .trim(from: period.start.relativeClockPosition, to: period.end.relativeClockPosition)
                .stroke(Color.green, style: StrokeStyle(lineWidth: geometryProxy.size.width * 10/100, lineCap: .round))
                .padding(geometryProxy.size.width * 6.3/100)
        }
    }

    private func clockWidgetIndicators(minute: Double) -> some View {
        GeometryReader { geometryProxy in
            Rectangle()
                .size(CGSize(width: 2, height: 10))
                .offset(CGSize(width: geometryProxy.size.width * 50/100, height: geometryProxy.size.height * 18/100))
                .rotation(.degrees(360 * (minute / (24 * 60))))
                .fill(Color.accentColor)

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

private extension DateComponents {
    var formatted: String {
        @Dependency(\.calendar) var calendar
        guard let date = calendar.date(from: self) else { return "" }
        return date.formatted(date: .omitted, time: .shortened)
    }

    var relativeClockPosition: Double {
        let maxMinutes = 24.0 * 60.0
        let minutes = Double(hour ?? 0) * 60 + Double(minute ?? 0)
        return minutes/maxMinutes
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
                    .trim(from: start.relativeClockPosition, to: end.relativeClockPosition)
                    .stroke(Color.green, lineWidth: 5)
                    .frame(width: 40, height: 40)
            }
            Text(start.formatted).monospacedDigit()
            Image(systemName: "arrowshape.forward")
            Text(end.formatted).monospacedDigit()
        }
        .accessibilityLabel(
            Text("\(start.formatted) to \(end.formatted)", comment: "<Hour:Minutes> to <Hour:Minutes>")
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
