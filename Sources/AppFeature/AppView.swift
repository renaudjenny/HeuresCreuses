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
                    action: { .applianceHomeWidget($0) }
                ))

                OffPeakHomeWidgetView(store: store.scope(
                    state: \.offPeakHomeWidget,
                    action: { .offPeakHomeWidget($0) }
                ))

                UserNotificationHomeWidgetView(store: store.scope(
                    state: \.userNotificationHomeWidget,
                    action: { .userNotificationHomeWidget($0) }
                ))
            }
            .listRowSpacing(8)
            .navigationTitle("Summary")
        }
    }
}

#if DEBUG
struct AppView_Previews: PreviewProvider {
    static var previews: some View {
        Preview(store: Store(initialState: App.State()) { App() })
        Preview(store: Store(initialState: App.State()) {
            App().dependency(\.date, DateGenerator { try! Date("2023-04-10T23:50:00+02:00", strategy: .iso8601) })
        })
        .previewDisplayName("At 23:50")

        Preview(store: Store(initialState: App.State()) {
            App().dependency(\.date, DateGenerator { try! Date("2023-04-10T00:10:00+02:00", strategy: .iso8601) })
        })
        .previewDisplayName("At 00:10")

        Preview(store: Store(initialState: App.State()) {
            App().dependency(\.date, DateGenerator { try! Date("2023-04-10T02:10:00+02:00", strategy: .iso8601) })
        })
        .previewDisplayName("At 02:10")

        Preview(store: Store(initialState: App.State()) {
            App().dependency(\.date, DateGenerator { try! Date("2023-04-10T16:00:00+02:00", strategy: .iso8601) })
        })
        .previewDisplayName("At 16:00")

        Preview(
            store: Store(initialState: App.State()) {
                App().transformDependency(\.userNotificationCenter) {
                    $0.$pendingNotificationRequests = { @Sendable in
                        let content1 = UNMutableNotificationContent()
                        content1.body = "White Dishwasher\nProgram Eco\nDelay 3 hour"
                        let content2 = UNMutableNotificationContent()
                        content2.body = "Gray Washing machine\nProgram Intense\nDelay 4 hours"
                        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 123456, repeats: false)
                        return [
                            UNNotificationRequest(identifier: "1", content: content1, trigger: trigger),
                            UNNotificationRequest(identifier: "2", content: content2, trigger: trigger),
                        ]
                    }
                }
            }
        )
        .previewDisplayName("With Notifications")
    }

    private struct Preview: View {
        let store: StoreOf<App>

        var body: some View {
            AppView(store: store)
        }
    }
}
#endif
