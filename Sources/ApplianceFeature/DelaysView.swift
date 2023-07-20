import ComposableArchitecture
import SwiftUI

public struct DelaysView: View {
    let store: StoreOf<Delays>

    struct ViewState: Equatable {
        var program: Program
        var items: [Delays.State.Item]

        init(_ state: Delays.State) {
            program = state.program
            items = state.items
        }
    }

    public var body: some View {
        WithViewStore(store, observe: ViewState.init) { viewState in
            ScrollView {
                Text(viewState.program.name)
                    .font(.title)
                    .padding(.bottom, 20)

                ForEach(viewState.items) { item in
                    VStack(alignment: .leading) {
                        Text("\(item.delay.hour) hours\(item.delay.minute > 0 ? "\(item.delay.minute) minutes" : "")")
                            .font(.title2)
                        Text("**\(item.minutesInPeak.formatted()) minutes** in peak")
                        Text("**\(item.minutesOffPeak.formatted()) minutes** off peak")
                    }
                    .padding(.bottom, 12)
                }
            }
            .navigationTitle("Delays")
            .task { @MainActor in viewState.send(.task) }
        }
    }
}

#if DEBUG
struct DelaysView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            let appliance: Appliance = .dishwasher
            DelaysView(
                store: Store(initialState: Delays.State(program: appliance.programs.first!, appliance: appliance)) {
                    Delays()
                }
            )
        }
    }
}
#endif
