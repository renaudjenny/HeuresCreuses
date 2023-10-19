import ComposableArchitecture
import SendNotification
import SwiftUI

struct OptimumView: View {
    let store: StoreOf<Optimum>

    struct ViewState: Equatable {
        let program: Program
        let delay: String
        let shouldWaitBeforeStart: Bool
        let durationBeforeStart: String
        let ratio: String

        init(_ state: Optimum.State) {
            program = state.program
            delay = state.delay.hourMinute
            shouldWaitBeforeStart = state.durationBeforeStart > .zero
            durationBeforeStart = state.durationBeforeStart.hourMinute
            ratio = state.ratio.formatted(.percent.precision(.significantDigits(3)))
        }
    }

    var body: some View {
        WithViewStore(store, observe: ViewState.init) { viewStore in
            ScrollView {
                VStack {
                    Text("Optimum").font(.title).padding()

                    Text("The **optimum** is the best time to start your appliance from now with the indicated delay")
                        .font(.subheadline)
                        .padding([.horizontal, .bottom])

                    if viewStore.shouldWaitBeforeStart {
                        Text("""
                        Wait **\(viewStore.durationBeforeStart)** before starting your appliance \
                        with the **\(viewStore.delay) delay** to be **\(viewStore.ratio)** off peak
                        """)
                        .padding(.horizontal)

                        SendNotificationButtonView(
                            store: store.scope(state: \.sendNotification, action: Optimum.Action.sendNotification)
                        )
                        .padding()
                    } else {
                        Text("""
                        You can start your appliance with the **\(viewStore.delay) delay** now and have an off peak of \
                        \(viewStore.ratio)
                        """)
                    }

                    Button { viewStore.send(.delaysTapped(viewStore.program)) } label: {
                        Label("All delays", systemImage: "arrowshape.turn.up.backward.badge.clock.rtl")
                    }
                    .padding(.top)
                }
                .padding()
                .presentationDetents([.medium])
                .task { await viewStore.send(.task).finish() }
            }
        }
    }
}

#if DEBUG
struct OptimumView_Preview: PreviewProvider {
    static var previews: some View {
        Color.blue
            .sheet(isPresented: .constant(true)) {
                OptimumView(
                    store: Store(
                        initialState: Optimum.State(program: Appliance.dishwasher.programs.first!, appliance: .dishwasher)
                    ) {
                        Optimum()
                    }
                )
            }
    }
}
#endif
