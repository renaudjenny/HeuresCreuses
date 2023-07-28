import ComposableArchitecture
import SwiftUI

struct OptimumView: View {
    let store: StoreOf<Optimum>


    struct ViewState: Equatable {
        let program: Program

        init(_ state: Optimum.State) {
            program = state.program
        }
    }

    var body: some View {
        WithViewStore(store, observe: ViewState.init) { viewState in
            VStack {
                Text("Optimum").font(.title2).padding()

                Text("TODO")

                Spacer()
                Button { viewState.send(.delaysTapped(viewState.program)) } label: {
                    Label("All delays", systemImage: "arrowshape.turn.up.backward.badge.clock.rtl")
                }
            }
            .padding()
            .presentationDetents([.fraction(1/4)])
        }
    }
}
