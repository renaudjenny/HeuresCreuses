import ComposableArchitecture
import HomeWidget
import SwiftUI
import UserNotificationsClientDependency

#if canImport(NotificationCenter)
@Reducer
public struct UserNotificationHomeWidget {
    @ObservableState
    public struct State: Equatable {
        var notifications: [UserNotification] = []
        @Presents var destination: UserNotificationsList.State?

        var nextNotification: UserNotification? {
            @Dependency(\.date) var date
            return notifications.sorted { $0.triggerDate < $1.triggerDate }.first { $0.triggerDate > date() }
        }

        public init(notifications: [UserNotification] = [], destination: UserNotificationsList.State? = nil) {
            if !notifications.isEmpty {
                self.notifications = notifications
            } else {
                @Dependency(\.userNotifications) var userNotifications
                self.notifications = userNotifications.notifications()
            }
            self.destination = destination
        }
    }

    public enum Action: Equatable {
        case cancel
        case destination(PresentationAction<UserNotificationsList.Action>)
        case notificationsUpdated([UserNotification])
        case task
        case widgetTapped
    }

    enum CancelID {
        case removeOutdated
        case task
    }

    public init () {}

    @Dependency(\.continuousClock) var clock
    @Dependency(\.date.now) var now
    @Dependency(\.userNotifications) var userNotifications

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .cancel:
                return .merge(.cancel(id: CancelID.task), .cancel(id: CancelID.removeOutdated))
            case .destination:
                return .none
            case let .notificationsUpdated(notifications):
                state.notifications = notifications
                return .none
            case .task:
                return .merge(
                    removeOutdated(),
                    .run { send in
                        for await notifications in userNotifications.stream() {
                            await send(.notificationsUpdated(notifications))
                        }
                    }.cancellable(id: CancelID.task)
                )
            case .widgetTapped:
                state.destination = UserNotificationsList.State(
                    notifications: IdentifiedArray(uniqueElements: state.notifications)
                )
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination) {
            UserNotificationsList()
        }
    }

    private func removeOutdated() -> Effect<Action> {
        let removeOutdatedNotifications = {
            let ids = userNotifications.notifications()
                .filter { $0.creationDate.addingTimeInterval(Double($0.duration.components.seconds)) < now }
                .map(\.id)
            guard !ids.isEmpty else { return }
            try await userNotifications.remove(ids)
        }

        return .run { _ in
            try await removeOutdatedNotifications()
            for await _ in clock.timer(interval: .seconds(1)) {
                try await removeOutdatedNotifications()
            }
        }
        .cancellable(id: CancelID.removeOutdated)
    }
}

public struct UserNotificationHomeWidgetView: View {
    @Bindable var store: StoreOf<UserNotificationHomeWidget>

    public var body: some View {
        Button { store.send(.widgetTapped) } label: {
            HomeWidgetView(title: "Notifications", icon: Image(systemName: "bell.badge")) {
                VStack(alignment: .leading) {
                    Text("**Programmed notifications**: \(store.notifications.count)")
                    if let nextNotificationMessage = store.nextNotification.map({
                        ["\($0.title)", $0.body].joined(separator: "\n")
                    }) {
                        Text("**Next**: \(nextNotificationMessage)")
                            .font(.footnote)
                            .multilineTextAlignment(.leading)
                    }
                }
            }
        }
        .buttonStyle(.plain)
        .sheet(item: $store.scope(state: \.destination, action: \.destination)) { store in
            NavigationStack {
                UserNotificationsListView(store: store)
            }
        }
        .task { @MainActor in await store.send(.task).finish() }
    }

    public init(store: StoreOf<UserNotificationHomeWidget>) {
        self.store = store
    }
}

#Preview {
    NavigationStack {
        List {
            UserNotificationHomeWidgetView(
                store: Store(initialState: UserNotificationHomeWidget.State()) {
                    UserNotificationHomeWidget()
                        .transformDependency(\.userNotifications) { dependency in
                            dependency.stream = { .example }
                        }
                }
            )
        }
    }
}
#else
@Reducer
public struct UserNotificationHomeWidget {
    public struct State: Equatable {
        public init(notifications: [UserNotification] = [], destination: UserNotificationsList.State? = nil) {}
    }

    public enum Action: Equatable {}

    public init () {}

    public var body: some ReducerOf<Self> {
        EmptyReducer()
    }
}

public struct UserNotificationHomeWidgetView: View {
    let store: StoreOf<UserNotificationHomeWidget>

    public var body: some View {
        EmptyView()
    }

    public init(store: StoreOf<UserNotificationHomeWidget>) {
        self.store = store
    }
}
#endif
