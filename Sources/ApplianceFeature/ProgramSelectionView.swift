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
                ForEach(viewState.appliance.programs) { program in
                    Button { viewState.send(.programTapped(program)) } label: {
                        Text("\(Text(program.name)) - \(Text((program.duration/60).formatted())) minutes")
                    }
                }
                .navigationDestination(
                    store: store.scope(
                        state: \.$delaysDestination,
                        action: ProgramSelection.Action.delaysDestination
                    ),
                    destination: DelaysView.init
                )
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
