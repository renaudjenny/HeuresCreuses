#if canImport(NotificationCenter)
import ComposableArchitecture
import Models
import NotificationCenter
import SwiftUI

public struct SendNotificationButtonView: View {
    let store: StoreOf<SendNotification>

    private struct ViewState: Equatable {
        let intent: SendNotification.Intent?
        let isRemindMeButtonShown: Bool
        let isNotificationAuthorized: Bool

        init(_ state: SendNotification.State) {
            isRemindMeButtonShown = state.userNotificationStatus != .alreadySent
            isNotificationAuthorized = ![.denied, .notDetermined].contains(state.notificationAuthorizationStatus)
            intent = state.intent
        }
    }

    public init(store: StoreOf<SendNotification>) {
        self.store = store
    }

    public var body: some View {
        WithViewStore(store, observe: ViewState.init) { viewStore in
            VStack {
                if viewStore.isRemindMeButtonShown {
                    Button { viewStore.send(.buttonTapped(viewStore.intent), animation: .default) } label: {
                        let duration = switch viewStore.intent {
                        case let .applianceToProgram(_, _, durationBeforeStart): durationBeforeStart
                        case let .offPeakStart(durationBeforeOffPeak): durationBeforeOffPeak
                        case let .offPeakEnd(durationBeforePeak): durationBeforePeak
                        case .none: Duration.zero
                        }

                        Label("Send me a notification in \(duration.hourMinute)", systemImage: "bell.badge")
                    }
                } else if viewStore.isNotificationAuthorized {
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
            .task { await viewStore.send(.task).finish() }
        }
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
