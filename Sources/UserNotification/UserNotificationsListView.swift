import ComposableArchitecture
import SendNotification
import SwiftUI
import UserNotificationsClientDependency

@Reducer
public struct UserNotificationsList {
    public struct State: Equatable {
        var notifications: IdentifiedArrayOf<UserNotification> = []

        init(notifications: IdentifiedArrayOf<UserNotification> = []) {
            guard notifications.isEmpty else {
                self.notifications = notifications
                return
            }
            @Dependency(\.userNotifications) var userNotifications
            self.notifications = IdentifiedArrayOf(uniqueElements: userNotifications.notifications())
        }
    }

    public enum Action: Equatable {
        case delete(IndexSet)
        case notificationsUpdated([UserNotification])
        case task
    }

    @Dependency(\.continuousClock) var clock
    @Dependency(\.userNotificationCenter) var userNotificationCenter
    @Dependency(\.userNotifications) var userNotifications

    private enum CancelID { case timer }

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .delete(indexSet):
                for index in indexSet {
                    userNotifications.remove(state.notifications[index])
                }
                return .none
            case let .notificationsUpdated(notifications):
                for notification in notifications {
                    state.notifications.updateOrAppend(notification)
                }
                return .none
            case .task:
                return .run { send in
                    for await notifications in userNotifications.stream() {
                        await send(.notificationsUpdated(notifications))
                    }
                }
                .cancellable(id: CancelID.timer)
            }
        }
    }
}

struct UserNotificationsListView: View {
    let store: StoreOf<UserNotificationsList>

    private struct ViewState: Equatable {
        let notifications: IdentifiedArrayOf<UserNotification>

        init(_ state: UserNotificationsList.State) {
            notifications = state.notifications
        }
    }

    var body: some View {
        WithViewStore(store, observe: ViewState.init) { viewStore in
            List {
                ForEach(viewStore.notifications, content: notificationView)
                    .onDelete(perform: { viewStore.send(.delete($0)) })
            }
            .navigationTitle("^[\(viewStore.notifications.count) pending notifications](inflect: true)")
            .task { @MainActor in await viewStore.send(.task).finish() }
        }
    }

    private func notificationView(_ notification: UserNotification) -> some View {
        VStack(alignment: .leading) {
            Text(notification.title)
                .font(.headline)
            Text(notification.body)
                .font(.body)
            TimelineView(.periodic(from: .now, by: 1)) { _ in
                HStack {
                    Label(notification.formattedRemainingTime, systemImage: "clock.badge")
                        .foregroundStyle(.secondary)
                        .font(.body)
                        .monospacedDigit()

                    ProgressView(
                        value: max(notification.remainingTime, 0),
                        total: Double(notification.duration.components.seconds)
                    )
                }
            }
        }
    }
}

private extension UserNotification {
    var formattedRemainingTime: String {
        Duration.seconds(remainingTime).formatted(.time(pattern: .hourMinuteSecond))
    }

    var remainingTime: Double {
        @Dependency(\.date.now) var now
        return now.distance(to: triggerDate)
    }
}

#Preview {
    NavigationStack {
        UserNotificationsListView(store: Store(initialState: UserNotificationsList.State()) {
            UserNotificationsList()
                .transformDependency(\.userNotificationCenter) { dependency in
                    dependency.$pendingNotificationRequests = { @Sendable in
                        let content = UNMutableNotificationContent()
                        content.body = "Test notification body"
                        let trigger1 = UNTimeIntervalNotificationTrigger(timeInterval: 12345, repeats: false)
                        let trigger2 = UNTimeIntervalNotificationTrigger(timeInterval: 23456, repeats: false)
                        return [
                            UNNotificationRequest(identifier: "1234", content: content, trigger: trigger1),
                            UNNotificationRequest(identifier: "1235", content: content, trigger: trigger2)
                        ]
                    }
                }
        })
    }
}
