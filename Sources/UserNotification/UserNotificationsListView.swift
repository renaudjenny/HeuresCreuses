import ComposableArchitecture
import SwiftUI
import UserNotificationsClientDependency

@Reducer
public struct UserNotificationsList {
    @ObservableState
    public struct State: Equatable {
        var notifications: IdentifiedArrayOf<UserNotification> = []
        var passedNotifications: IdentifiedArrayOf<UserNotification> = []

        init(
            notifications: IdentifiedArrayOf<UserNotification> = [],
            passedNotifications: IdentifiedArrayOf<UserNotification> = []
        ) {
            guard notifications.isEmpty else {
                self.notifications = notifications
                return
            }
            @Dependency(\.userNotifications) var userNotifications
            self.notifications = IdentifiedArrayOf(uniqueElements: userNotifications.notifications())
            self.passedNotifications = passedNotifications
        }
    }

    public enum Action: Equatable {
        case addTestNotification
        case cancel
        case delete(IndexSet)
        case moveOutdated(ids: [String])
        case notificationsUpdated([UserNotification])
        case task
    }

    @Dependency(\.continuousClock) var clock
    @Dependency(\.date.now) var now
    @Dependency(\.userNotifications) var userNotifications

    private enum CancelID {
        case notificationsUpdate
        case moveOutdated
    }

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .addTestNotification:
                let notification = UserNotification(
                    id: "12345",
                    title: "Test",
                    body: "Here is what a notification is looking like",
                    creationDate: .now,
                    duration: .seconds(3)
                )
                return .run { _ in try await userNotifications.add(notification) }
            case .cancel:
                return .merge(
                    .cancel(id: CancelID.notificationsUpdate),
                    .cancel(id: CancelID.moveOutdated)
                )
            case let .delete(indexSet):
                return .run { [notifications = state.notifications] _ in
                    try? await userNotifications.remove(indexSet.map { notifications[$0].id })
                }
            case let .moveOutdated(ids):
                state.passedNotifications = state.passedNotifications + state.notifications.filter { ids.contains($0.id) }
                state.notifications.removeAll { ids.contains($0.id) }
                return .none
            case let .notificationsUpdated(notifications):
                state.notifications = IdentifiedArrayOf(uniqueElements: notifications)
                return .none
            case .task:
                return .merge(
                    .run { send in
                        await moveOutdatedNotifications(send)
                        for await _ in clock.timer(interval: .seconds(1)) {
                            await moveOutdatedNotifications(send)
                        }
                    }
                    .cancellable(id: CancelID.moveOutdated),
                    .run { send in
                        for await notifications in userNotifications.stream() {
                            print(notifications.count)
                            await send(.notificationsUpdated(notifications))
                        }
                    }.cancellable(id: CancelID.notificationsUpdate)
                )
            }
        }
    }

    private func moveOutdatedNotifications(_ send: Send<Action>) async {
        let ids = userNotifications.notifications()
            .filter { $0.creationDate.addingTimeInterval(Double($0.duration.components.seconds)) < now }
            .map(\.id)
        guard !ids.isEmpty else { return }
        await send(.moveOutdated(ids: ids))
    }
}

struct UserNotificationsListView: View {
    let store: StoreOf<UserNotificationsList>

    var body: some View {
        List {
            Section("^[\(store.notifications.count) pending notifications](inflect: true)") {
                ForEach(store.notifications, content: notificationView)
                    .onDelete(perform: { store.send(.delete($0)) })
            }

            Section("Passed notifications") {
                ForEach(store.passedNotifications, content: passedNotificationView)
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

    private func passedNotificationView(_ notification: UserNotification) -> some View {
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
        let passedNotifications: IdentifiedArrayOf<UserNotification> = [
            UserNotification(
                id: "123456",
                title: "White Dishwasher",
                body: "White Dishwasher\nProgram Quick\nDelay 8 hour",
                creationDate: try! Date("2024-03-05T02:00:00+02:00", strategy: .iso8601),
                duration: .seconds(2 * 60 * 60)
            )
        ]
        UserNotificationsListView(store: Store(initialState: UserNotificationsList.State(passedNotifications: passedNotifications)) {
            UserNotificationsList()
                .transformDependency(\.userNotifications) { dependency in
                    dependency.stream = { .example }
                }
        })
    }
}
