import ApplianceFeature
import ComposableArchitecture
import Models
import OffPeak
import SwiftUI
import UserNotification

public struct AppView: View {
    let store: StoreOf<App>

    public init(store: StoreOf<App>) {
        self.store = store
    }

    public var body: some View {
        NavigationStack {
            List {
                AppliancesHomeWidgetView(store: store.scope(
                    state: \.applianceHomeWidget,
                    action: \.applianceHomeWidget
                ))

                OffPeakHomeWidgetView(store: store.scope(
                    state: \.offPeakHomeWidget,
                    action: \.offPeakHomeWidget
                ))

                UserNotificationHomeWidgetView(store: store.scope(
                    state: \.userNotificationHomeWidget,
                    action: \.userNotificationHomeWidget
                ))
            }
            #if os(iOS)
            .listRowSpacing(8)
            #endif
            .navigationTitle("Summary")
        }
    }
}

#Preview {
    AppView(store: Store(initialState: App.State()) {
        App()
    })
}

#Preview("At 23:50") {
    AppView(store: Store(initialState: App.State()) {
        App().dependency(\.date, DateGenerator { try! Date("2023-04-10T23:50:00+02:00", strategy: .iso8601) })
    })
}

#Preview("At 00:10") {
    AppView(store: Store(initialState: App.State()) {
        App().dependency(\.date, DateGenerator { try! Date("2023-04-10T00:10:00+02:00", strategy: .iso8601) })
    })
}

#Preview("At 02:10") {
    AppView(store: Store(initialState: App.State()) {
        App().dependency(\.date, DateGenerator { try! Date("2023-04-10T02:10:00+02:00", strategy: .iso8601) })
    })
}

#Preview("At 16:00") {
    AppView(store: Store(initialState: App.State()) {
        App().dependency(\.date, DateGenerator { try! Date("2023-04-10T16:00:00+02:00", strategy: .iso8601) })
    })
}

#Preview("With Notifications") {
    AppView(store: Store(initialState: App.State()) {
        App().transformDependency(\.userNotifications) {
            $0.stream = { .example }
        }
    })
}
