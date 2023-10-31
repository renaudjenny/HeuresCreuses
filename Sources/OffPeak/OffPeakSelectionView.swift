import ComposableArchitecture
import Models
import SwiftUI

public struct OffPeakSelection: Reducer {
    public struct State: Equatable {
        public var periods = IdentifiedArrayOf<Period>(uniqueElements: [Period].example)
    }
    public enum Action: Equatable {

    }

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            return .none
        }
    }
}

public struct OffPeakSelectionView: View {
    let store: StoreOf<OffPeakSelection>

    private struct ViewState: Equatable {
        let periods: IdentifiedArrayOf<Period>

        init(_ state: OffPeakSelection.State) {
            periods = state.periods
        }
    }

    public var body: some View {
        WithViewStore(store, observe: ViewState.init) { viewState in
            Form {
                ForEach(viewState.periods) { period in
                    period.clockView
                }
            }
            .navigationTitle("Off peak periods")
        }
    }
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
