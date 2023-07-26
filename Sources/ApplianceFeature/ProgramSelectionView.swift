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
                    .sheet(
                        store: store.scope(
                            state: \.$bottomSheet,
                            action: ProgramSelection.Action.bottomSheet
                        ),
                        content: BottomSheetView.init
                    )
                    .navigationDestination(
                        store: store.scope(
                            state: \.$destination,
                            action: ProgramSelection.Action.destination
                        ),
                        state: /ProgramSelection.Destination.State.delays,
                        action: ProgramSelection.Destination.Action.delays,
                        destination: DelaysView.init
                    )
                }
            }
        }
        .navigationTitle("Choose your program")
    }
}

struct BottomSheetView: View {
    let store: StoreOf<ProgramSelection.BottomSheet>

    var body: some View {
        // TODO: add a ViewState instead of the observe { $0 }
        WithViewStore(store, observe: { $0 }) { viewState in
            VStack {
                Button { viewState.send(.delaysTapped(viewState.program)) } label: {
                    Text("Delays")
                }
                Button { viewState.send(.optimumTapped(viewState.program)) } label: {
                    Text("Optimum")
                }
            }
            .presentationDetents([.medium])
        }
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
