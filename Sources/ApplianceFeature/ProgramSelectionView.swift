import ComposableArchitecture
import SwiftUI

public struct ProgramSelectionView: View {
    let store: StoreOf<ProgramSelection>

    struct ViewState: Equatable {
        var appliance: Appliance

        init(_ state: ProgramSelection.State) {
            self.appliance = state.appliance
        }
    }

    public var body: some View {
        WithViewStore(store, observe: ViewState.init) { viewState in
            Text(viewState.appliance.name)
        }
    }
}

#if DEBUG
struct ProgramSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        ProgramSelectionView(
            store: Store(
                initialState: ProgramSelection.State(appliance: .dishwasher),
                reducer: ProgramSelection()
            ))
    }
}
#endif
