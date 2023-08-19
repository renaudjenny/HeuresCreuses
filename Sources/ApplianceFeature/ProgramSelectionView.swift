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
        WithViewStore(store, observe: ViewState.init) { viewStore in
            ScrollView {
                Text(viewStore.appliance.name)
                    .font(.title)
                    .padding(.bottom, 20)
                VStack(alignment: .leading) {
                    ForEach(viewStore.appliance.programs) { program in
                        Button { viewStore.send(.programTapped(program)) } label: {
                            VStack(alignment: .leading) {
                                Text(program.name).font(.title3)
                                Label(
                                    program.duration
                                        .formatted(.units(allowed: [.minutes], width: .wide)),
                                    systemImage: "timer"
                                )
                            }
                        }
                        .padding()
                    }
                    .sheet(
                        store: store.scope(
                            state: \.$destination,
                            action: ProgramSelection.Action.destination
                        ),
                        state: /ProgramSelection.Destination.State.optimum,
                        action: ProgramSelection.Destination.Action.optimum,
                        content: OptimumView.init
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

#if DEBUG
struct ProgramSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ProgramSelectionView(store: Store(initialState: ProgramSelection.State(appliance: .dishwasher)) {
                ProgramSelection()
            })
        }
    }
}
#endif
