import ComposableArchitecture
import SwiftUI

public struct DelaysView: View {
    let store: StoreOf<Delays>

    struct ViewState: Equatable {
        var program: Program

        init(_ state: Delays.State) {
            program = state.program
        }
    }

    public var body: some View {
        WithViewStore(store, observe: ViewState.init) { viewState in
            ScrollView {
                Text(viewState.program.name)
                    .font(.title)
                    .padding(.bottom, 20)
            }
            .navigationTitle("Delays")
        }
    }
}

#if DEBUG
struct DelaysView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            DelaysView(
                store: Store(initialState: Delays.State(program: Appliance.dishwasher.programs.first!)) {
                    Delays()
                }
            )
        }
    }
}
#endif
