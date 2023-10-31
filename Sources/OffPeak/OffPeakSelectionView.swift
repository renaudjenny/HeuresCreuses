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
                    HStack {
                        Text(period.start.description)
                        Image(systemName: "arrowshape.forward")
                        Text(period.end.description)
                    }
                }
            }
            .navigationTitle("Off peak periods")
        }
    }
}

#Preview {
    NavigationStack {
        OffPeakSelectionView(store: Store(initialState: OffPeakSelection.State()) {
            OffPeakSelection()
        })
    }
}
