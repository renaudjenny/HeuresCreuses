import ComposableArchitecture
import SwiftUI

public struct DelaysView: View {
    @Bindable var store: StoreOf<Delays>

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
                            HStack {
                                if store.notificationOperationsIds.contains(operation.id) {
                                    Label("Notification programmed", systemImage: "bell.badge.fill")
                                        .labelStyle(.iconOnly)
                                } 
                                if store.loadingNotificationOperationsIds.contains(operation.id) {
                                    ProgressView("Programming your notification")
                                } else {
                                    Menu("More") {
                                        Button { store.send(.sendOperationEndNotification(operationID: operation.id), animation: .snappy) } label: {
                                            if !store.notificationOperationsIds.contains(operation.id) {
                                                Label("Notify me when it ends", systemImage: "bell.badge")
                                            } else {
                                                Label("Notification already programmed", systemImage: "bell.badge.fill")
                                            }
                                        }
                                    }
                                }
                            }
                            #endif
                            Text("\(operation.offPeakRatio.formatted(.percent.precision(.significantDigits(3)))) off peak")
                        }
                    }
                    .alert($store.scope(state: \.notificationAlert, action: \.notificationAlert))

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
#if DEBUG
import UserNotificationsClientDependency

#Preview {
    NavigationStack {
        let appliance: Appliance = .washingMachine
        let date = try! Date("2023-07-21T19:50:00+02:00", strategy: .iso8601)
        DelaysView(
            store: Store(initialState: Delays.State(program: appliance.programs.first!, appliance: appliance)) {
                Delays()
                    .dependency(\.date, .constant(date))
                    .dependency(\.userNotifications.notifications, { [
                        UserNotification(
                            id: "com.renaudjenny.heures-creuses.notification.operation-end-21600",
                            title: "",
                            body: "",
                            creationDate: date,
                            duration: .seconds(6 * 60 * 60)
                        )
                    ] })
            }
        )
    }
}
#endif
