import ComposableArchitecture
import SwiftUI

public struct DelaysView: View {
    let store: StoreOf<Delays>

    struct ViewState: Equatable {
        var program: Program
        var operations: [Operation]
        var isOffPeakOnlyFilterOn: Bool
        var delaysCount: Int

        init(_ state: Delays.State) {
            program = state.program
            operations = state.operations
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

                if viewStore.isOffPeakOnlyFilterOn && viewStore.operations.count < viewStore.delaysCount {
                    Text("""
                    ^[\(viewStore.delaysCount - viewStore.operations.count) operations](inflect: true) \
                    hidden as no off peak
                    """)
                    .font(.caption)
                }

                ForEach(viewStore.operations) { operation in
                    VStack(alignment: .leading) {
                        HStack(alignment: .lastTextBaseline) {
                            VStack(alignment: .leading, spacing: 8) {
                                if operation.delay == .zero {
                                    Text("Starting immediately").font(.title2)
                                } else {
                                    Text(operation.delay.hourMinute).font(.title2)
                                }
                                Text("Finishing at \(operation.startEnd.upperBound.formatted(date: .omitted, time: .shortened))")
                            }
                            Spacer()
                            VStack(alignment: .trailing) {
                                Text("\(operation.offPeakRatio.formatted(.percent.precision(.significantDigits(3)))) off peak")
                            }
                        }
                        ZStack {
                            GeometryReader { proxy in
                                Color.blue
                                if operation.minutesOffPeak > 0 {
                                    Color.green
                                        .frame(width: proxy.size.width * operation.offPeakRangeRatio.upperBound)
                                        .clipShape(RoundedRectangle(cornerRadius: 6))
                                        .offset(x: operation.offPeakRangeRatio.lowerBound * proxy.size.width)
                                }
                            }
                            .accessibility(
                                label: Text("\(operation.minutesInPeak.formatted()) minutes in peak and \(operation.minutesOffPeak.formatted()) minutes off peak")
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
