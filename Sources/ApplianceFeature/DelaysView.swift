import ComposableArchitecture
import SwiftUI

public struct DelaysView: View {
    let store: StoreOf<Delays>

    struct ViewState: Equatable {
        var program: Program
        var operations: IdentifiedArrayOf<Operation>
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
        ScrollView {
            Text(store.program.name)
                .font(.title)
                .padding(.bottom, 20)

            if store.isOffPeakOnlyFilterOn && store.operations.count < store.appliance.delays.count {
                Text("""
                    ^[\(store.appliance.delays.count - store.operations.count) operations](inflect: true) \
                    hidden as no off peak
                    """)
                .font(.caption)
            }

            ForEach(store.operations) { operation in
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
                            #if os(iOS) || os(macOS)
                            Menu("More") {
                                Button { store.send(.sendOperationEndNotification(operationID: operation.id)) } label: {
                                    Label("Notify me when it ends", systemImage: "bell.badge")
                                }
                            }
                            #endif
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
                Button { store.send(.onlyShowOffPeakTapped, animation: .easeInOut) } label: {
                    if store.isOffPeakOnlyFilterOn {
                        Label("Show all", systemImage: "eye.slash")
                    } else {
                        Label("Only show off peak", systemImage: "eye")
                    }
                }
            }
        }
        .task { @MainActor in store.send(.task) }
    }
}

#Preview {
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
