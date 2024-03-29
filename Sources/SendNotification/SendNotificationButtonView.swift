#if canImport(NotificationCenter) && os(iOS)
import ComposableArchitecture
import Models
import SwiftUI

public struct SendNotificationButtonView: View {
    let store: StoreOf<SendNotification>

    public init(store: StoreOf<SendNotification>) {
        self.store = store
    }

    public var body: some View {
        VStack {
            if store.userNotificationStatus != .alreadySent {
                Button { store.send(.buttonTapped(store.intent), animation: .default) } label: {
                    let duration = switch store.intent {
                    case let .applianceToProgram(_, _, durationBeforeStart): durationBeforeStart
                    case let .offPeakStart(durationBeforeOffPeak): durationBeforeOffPeak
                    case let .offPeakEnd(durationBeforePeak): durationBeforePeak
                    case .none: Duration.zero
                    }

                    Label("Send me a notification in \(duration.hourMinute)", systemImage: "bell.badge")
                }
            } else if ![.denied, .notDetermined].contains(store.notificationAuthorizationStatus) {
                Label("Notification is programmed", systemImage: "bell")
            } else {
                Label(
                        """
                        Notification has been denied, please go to settings and allow Heures Creuses \
                        to send you notifications
                        """,
                        systemImage: "bell.slash"
                )
            }
        }
        .task { await store.send(.task).finish() }
    }
}
#else
import ComposableArchitecture
import SwiftUI

public struct SendNotificationButtonView: View {
    public init(store: StoreOf<SendNotification>) {}

    public var body: some View {
        EmptyView()
    }
}
#endif
