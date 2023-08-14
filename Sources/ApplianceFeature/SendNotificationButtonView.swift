#if canImport(NotificationCenter)
import ComposableArchitecture
import NotificationCenter
import SwiftUI

struct SendNotificationButtonView: View {
    let store: StoreOf<SendNotification>

    struct ViewState: Equatable {
        let durationBeforeStart: String
        let isRemindMeButtonShown: Bool
        let isNotificationAuthorized: Bool

        init(_ state: SendNotification.State) {
            isRemindMeButtonShown = state.notificationAuthorizationStatus == .notDetermined
            isNotificationAuthorized = [.authorized, .ephemeral].contains(state.notificationAuthorizationStatus)
            durationBeforeStart = state.durationBeforeStart.hourMinute
        }
    }

    var body: some View {
        WithViewStore(store, observe: ViewState.init) { viewStore in
            if viewStore.isRemindMeButtonShown {
                Button { viewStore.send(.remindMeButtonTapped, animation: .default) } label: {
                    Label(
                        "Send me a notification in \(viewStore.durationBeforeStart)",
                        systemImage: "bell.badge"
                    )
                }
                .padding()
            } else if viewStore.isNotificationAuthorized {
                Label("Notification is programmed", systemImage: "bell").padding()
            } else {
                Label("""
                Notification has been denied, please go to settings and allow Heures Creuses \
                to send you notifications
                """,
                      systemImage: "bell.slash"
                )
                .padding()
            }
        }
    }
}
#endif
