import ComposableArchitecture
import SwiftUI
import UserNotificationsClientDependency

@Reducer
public struct UserNotificationsList {
    @ObservableState
    public struct State: Equatable {
        @Shared(.userNotifications) var notifications: IdentifiedArrayOf<UserNotification> = []
        var outdatedNotifications: IdentifiedArrayOf<UserNotification> = []

        init(
            notifications: IdentifiedArrayOf<UserNotification> = [],
            outdatedNotifications: IdentifiedArrayOf<UserNotification> = []
        ) {
            guard notifications.isEmpty else {
                self.notifications = notifications
                return
            }
            self._notifications = Shared(wrappedValue: notifications, .userNotifications)
            self.outdatedNotifications = outdatedNotifications
        }
    }

    public enum Action: Equatable {
        case addTestNotification
        case cancel
        case deleteNotifications(IndexSet)
        case deleteOutdatedNotifications(IndexSet)
        case notificationsUpdated(ongoing: [UserNotification], outdated: [UserNotification])
        case task
    }

    @Dependency(\.continuousClock) var clock
    @Dependency(\.date.now) var now
    @Dependency(\.userNotifications) var userNotifications
    @Dependency(\.uuid) var uuid

    private enum CancelID {
        case notificationsUpdate
        case moveOutdated
    }

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .addTestNotification:
                let id = uuid().uuidString
                let notification = UserNotification(
                    id: id,
                    title: "Test",
                    body: "It's a test notification with the id: \(id)",
                    creationDate: .now,
                    duration: .seconds(3)
                )
                state.notifications.append(notification)
                return .none
            case .cancel:
                return .merge(
                    .cancel(id: CancelID.notificationsUpdate),
                    .cancel(id: CancelID.moveOutdated)
                )
            case let .deleteNotifications(indexSet):
                return .run { [notifications = state.notifications] _ in
                    try? await userNotifications.remove(indexSet.map { notifications[$0].id })
                }
            case let .deleteOutdatedNotifications(indexSet):
                return .run { [outdatedNotifications = state.outdatedNotifications] _ in
                    try? await userNotifications.remove(indexSet.map { outdatedNotifications[$0].id })
                }
            case let .notificationsUpdated(ongoing, outdated):
                state.notifications = IdentifiedArrayOf(uniqueElements: ongoing)
                state.outdatedNotifications = IdentifiedArrayOf(uniqueElements: outdated)
                return .none
            case .task:
                return .run { send in
                    for await _ in clock.timer(interval: .seconds(1)) {
                        @Shared(.userNotifications) var notifications
                        let (ongoing, outdated) = notifications.elements.splitOutdated(now: now)
                        await send(.notificationsUpdated(ongoing: ongoing, outdated: outdated), animation: .smooth)
                    }
                }
                .cancellable(id: CancelID.moveOutdated)
            }
        }
    }
}

extension [UserNotification] {
    func splitOutdated(now: Date) -> (ongoing: Self, outdated: Self) {
        return reduce(into: ([], []), { partialResult, notification in
            if notification.creationDate.addingTimeInterval(Double(notification.duration.components.seconds)) < now {
                partialResult.outdated.append(notification)
            } else {
                partialResult.ongoing.append(notification)
            }
        })
    }
}

struct UserNotificationsListView: View {
    let store: StoreOf<UserNotificationsList>

    var body: some View {
        List {
            Section("^[\(store.notifications.count) pending notifications](inflect: true)") {
                ForEach(store.notifications, content: notificationView)
                    .onDelete(perform: { store.send(.deleteNotifications($0)) })
            }

            Section("Outdated notifications") {
                ForEach(store.outdatedNotifications, content: outdatedNotificationView)
                    .onDelete(perform: { store.send(.deleteOutdatedNotifications($0)) })
            }

            Section("Test") {
                Button { store.send(.addTestNotification) } label: {
                    Text("Add a test notification")
                }
            }
        }
        .navigationTitle("Notifications")
        .task { @MainActor in await store.send(.task).finish() }
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

    private func outdatedNotificationView(_ notification: UserNotification) -> some View {
        VStack(alignment: .leading) {
            Label("\(notification.triggerDate.formatted())", systemImage: "calendar.badge.clock")
                .font(.body)
                .foregroundStyle(.secondary)
            Text(notification.title)
                .font(.headline)
            Text(notification.body)
                .font(.body)
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
        let outdatedNotifications: IdentifiedArrayOf<UserNotification> = [
            UserNotification(
                id: "123456",
                title: "White Dishwasher",
                body: "White Dishwasher\nProgram Quick\nDelay 8 hour",
                creationDate: try! Date("2024-03-05T02:00:00+02:00", strategy: .iso8601),
                duration: .seconds(2 * 60 * 60)
            )
        ]
        UserNotificationsListView(store: Store(
            initialState: UserNotificationsList.State(outdatedNotifications: outdatedNotifications)
        ) {
            UserNotificationsList()
        })
    }
}
