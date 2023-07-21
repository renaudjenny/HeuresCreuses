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
                        ZStack {
                            GeometryReader { proxy in
                                Color.blue
                                if item.minutesOffPeak > 0 {
                                    Color.green
                                        .frame(width: proxy.size.width * item.offPeakRangeRatio.upperBound)
                                        .clipShape(RoundedRectangle(cornerRadius: 6))
                                        .offset(x: item.offPeakRangeRatio.lowerBound * proxy.size.width)
                                }
                            }
                        }
                        .frame(height: 12)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    .padding(.bottom, 12)
                    .padding(.horizontal)
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
            let appliance: Appliance = .washingMachine
            DelaysView(
                store: Store(initialState: Delays.State(program: appliance.programs.first!, appliance: appliance)) {
                    Delays()
                        .dependency(\.date, .constant(try! Date("2023-07-21T19:50:00+02:00", strategy: .iso8601)))
                }
            )
        }
    }
}
#endif
