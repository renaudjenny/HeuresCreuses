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
                Text("Optimum").font(.title).padding()

                Text("The **optimum** is the best time to start your appliance from now with the indicated delay")
                    .font(.subheadline)
                    .padding([.horizontal, .bottom])

                Text("Wait **23 minutes** before starting your appliance with the **2 hours delay** to be **100%** off peak")
                    .padding(.horizontal)

                Button { } label: {
                    Label("Send me a notification in 23 minutes", systemImage: "bell.badge")
                }
                .padding()

                Spacer()
                Button { viewState.send(.delaysTapped(viewState.program)) } label: {
                    Label("All delays", systemImage: "arrowshape.turn.up.backward.badge.clock.rtl")
                }
            }
            .padding()
            .presentationDetents([.medium])
        }
    }
}

#if DEBUG
struct OptimumView_Preview: PreviewProvider {
    static var previews: some View {
        Color.blue
            .sheet(isPresented: .constant(true)) {
                OptimumView(store: Store(
                    initialState: Optimum.State(program: Appliance.dishwasher.programs.first!, appliance: .dishwasher),
                    reducer: Optimum()
                ))
            }
    }
}
#endif
