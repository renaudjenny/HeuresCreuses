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

    struct ViewState: Equatable {
        let program: Program

        init(_ state: ProgramSelection.BottomSheet.State) {
            program = state.program
        }
    }

    var body: some View {
        WithViewStore(store, observe: ViewState.init) { viewState in
            VStack(alignment: .leading) {
                Spacer()
                Button { viewState.send(.delaysTapped(viewState.program)) } label: {
                    Label("Delays", systemImage: "arrowshape.turn.up.backward.badge.clock.rtl")
                }
                Spacer()
                Button { viewState.send(.optimumTapped(viewState.program)) } label: {
                    Label("Optimum", systemImage: "wand.and.stars")
                }
                Spacer()
            }
            .padding()
            .presentationDetents([.fraction(1/4)])
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
