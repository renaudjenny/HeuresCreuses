import ComposableArchitecture
import HomeWidget
import SwiftUI

public struct OffPeakHomeWidget: Reducer {
    public struct State: Equatable {
        var peakStatus = PeakStatus.unavailable

        public init(peakStatus: PeakStatus = PeakStatus.unavailable) {
            self.peakStatus = peakStatus
        }
    }
    public enum Action: Equatable {

    }

    public init() {}

    public var body: some ReducerOf<Self> {
        EmptyReducer()
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
            .listRowBackground(color(for: viewStore.peakStatus))
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
        OffPeakHomeWidgetView(store: Store(initialState: OffPeakHomeWidget.State()) {
            OffPeakHomeWidget()
        })
        OffPeakHomeWidgetView(
            store: Store(initialState: OffPeakHomeWidget.State(peakStatus: .peak(until: .seconds(2 * 60 * 60)))) {
                OffPeakHomeWidget()
            }
        )
        OffPeakHomeWidgetView(
            store: Store(initialState: OffPeakHomeWidget.State(peakStatus: .offPeak(until: .seconds(2.1 * 60 * 60)))) {
                OffPeakHomeWidget()
            }
        )
    }
    .listRowSpacing(8)
}
