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
            VStack {
                Text(viewState.appliance.name).font(.title)
                Spacer()
                ForEach(viewState.appliance.programs) { program in
                    Text("\(Text(program.name)) - \(Text((program.duration/60).formatted())) minutes")
                }
                Spacer()
            }
        }
        .navigationTitle("Choose your program")
    }
}

#if DEBUG
struct ProgramSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ProgramSelectionView(
                store: Store(
                    initialState: ProgramSelection.State(appliance: .dishwasher),
                    reducer: ProgramSelection()
                ))
        }
    }
}
#endif
