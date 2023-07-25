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
            ScrollView {
                Text(viewState.appliance.name)
                    .font(.title)
                    .padding(.bottom, 20)
                VStack(alignment: .leading) {
                    ForEach(viewState.appliance.programs) { program in
                        Button { viewState.send(.programTapped(program)) } label: {
                            VStack(alignment: .leading) {
                                Text(program.name).font(.title3)
                                Label("\((program.duration/60).formatted()) minutes", systemImage: "timer")
                            }
                        }
                        .padding()
                    }
                    .navigationDestination(
                        store: store.scope(
                            state: \.$delaysDestination,
                            action: ProgramSelection.Action.delaysDestination
                        ),
                        destination: DelaysView.init
                    )
                }
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
