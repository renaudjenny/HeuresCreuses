import ComposableArchitecture
import SendNotification
import SwiftUI

struct OptimumView: View {
    let store: StoreOf<Optimum>

    var body: some View {
        let ratio = store.ratio.formatted(.percent.precision(.significantDigits(3)))
        ScrollView {
            VStack {
                Text("Optimum").font(.title).padding()

                Text("The **optimum** is the best time to start your appliance from now with the indicated delay")
                    .font(.subheadline)
                    .padding([.horizontal, .bottom])

                if store.durationBeforeStart > .zero {
                    Text("""
                        Wait **\(store.durationBeforeStart.hourMinute)** before starting your appliance \
                        with the **\(store.delay.hourMinute) delay** to be **\(ratio)** off peak
                        """)
                    .padding(.horizontal)

                    SendNotificationButtonView(
                        store: store.scope(state: \.sendNotification, action: \.sendNotification)
                    )
                    .padding()
                } else {
                    Text("""
                        You can start your appliance with the **\(store.delay.hourMinute) delay** now and have an off peak of \
                        \(ratio)
                        """)
                }

                Button { store.send(.delaysTapped(store.program)) } label: {
                    Label("All delays", systemImage: "arrowshape.turn.up.backward.badge.clock.rtl")
                }
                .padding(.top)
            }
            .padding()
            .presentationDetents([.medium])
            .task { await store.send(.task).finish() }
        }
    }
}

#Preview {
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
