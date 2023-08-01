import ComposableArchitecture
import SwiftUI

public struct DelaysView: View {
    let store: StoreOf<Delays>

    struct ViewState: Equatable {
        var program: Program
        var items: [Delays.State.Item]
        var isOffPeakOnlyFilterOn: Bool
        var delaysCount: Int

        init(_ state: Delays.State) {
            program = state.program
            items = state.items
            isOffPeakOnlyFilterOn = state.isOffPeakOnlyFilterOn
            delaysCount = state.appliance.delays.count + 1
        }
    }

    public var body: some View {
        WithViewStore(store, observe: ViewState.init) { viewStore in
            ScrollView {
                Text(viewStore.program.name)
                    .font(.title)
                    .padding(.bottom, 20)

                if viewStore.isOffPeakOnlyFilterOn && viewStore.items.count < viewStore.delaysCount {
                    Text("^[\(viewStore.delaysCount - viewStore.items.count) items](inflect: true) hidden as no off peak")
                        .font(.caption)
                }

                ForEach(viewStore.items) { item in
                    VStack(alignment: .leading) {
                        HStack(alignment: .lastTextBaseline) {
                            VStack(alignment: .leading, spacing: 8) {
                                if item.delay.hour == 0 && item.delay.minute == 0 {
                                    Text("Starting immediately").font(.title2)
                                } else {
                                    Text("\(item.delay.hour) hours\(item.delay.minute > 0 ? "\(item.delay.minute) minutes" : "")")
                                        .font(.title2)
                                }
                                Text("Finishing at \(item.startEnd.upperBound.formatted(date: .omitted, time: .shortened))")
                            }
                            Spacer()
                            VStack(alignment: .trailing) {
                                Text("\(item.offPeakRatio.formatted(.percent.precision(.significantDigits(3)))) off peak")
                            }
                        }
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
                            .accessibility(
                                label: Text("\(item.minutesInPeak.formatted()) minutes in peak and \(item.minutesOffPeak.formatted()) minutes off peak")
                            )
                        }
                        .frame(height: 12)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    .padding(.bottom, 12)
                    .padding(.horizontal)
                }
            }
            .navigationTitle("Delays")
            .toolbar {
                ToolbarItem {
                    Button { viewStore.send(.onlyShowOffPeakTapped, animation: .easeInOut) } label: {
                        if viewStore.isOffPeakOnlyFilterOn {
                            Label("Show all", systemImage: "eye.slash")
                        } else {
                            Label("Only show off peak", systemImage: "eye")
                        }
                    }
                }
            }
            .task { @MainActor in viewStore.send(.task) }
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
