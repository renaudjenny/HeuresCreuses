#if canImport(NotificationCenter)
import ComposableArchitecture
import DependenciesAdditions
import HomeWidget
import NotificationCenter
import SwiftUI

public struct UserNotificationHomeWidget: Reducer {
    public struct State: Equatable {
        var notifications: [UserNotification] = []

        var nextNotification: UserNotification? {
            @Dependency(\.date) var date
            return notifications.sorted { $0.date < $1.date }.first { $0.date > date() }
        }

        public init(notifications: [UserNotification] = []) {
            self.notifications = notifications
        }
    }

    public enum Action: Equatable {
        case notificationsUpdated([UNNotificationRequest])
        case task
    }

    enum CancelID { case timer }

    public init () {}

    @Dependency(\.userNotificationCenter) var userNotificationCenter
    @Dependency(\.continuousClock) var clock

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .notificationsUpdated(notificationsContents):
                state.notifications = notificationsContents.compactMap {
                    guard
                        let trigger = $0.trigger as? UNTimeIntervalNotificationTrigger,
                        let date = trigger.nextTriggerDate()
                    else { return nil }
                    return UserNotification(id: $0.identifier, message: $0.content.body, date: date)
                }
                return .none
            case .task:
                return .run { send in
                    // TODO: replace this regular polling per something smarter with an extension of this dependency
                    for await _ in clock.timer(interval: .seconds(5)) {
                        let notifications = await userNotificationCenter.pendingNotificationRequests()
                        await send(.notificationsUpdated(notifications))
                    }
                }
                .cancellable(id: CancelID.timer)
            }
        }
    }
}

public struct UserNotificationHomeWidgetView: View {
    let store: StoreOf<UserNotificationHomeWidget>

    private struct ViewState: Equatable {
        let notificationsCount: Int
        let nextNotificationMessage: String?

        init(_ state: UserNotificationHomeWidget.State) {
            notificationsCount = state.notifications.count
            nextNotificationMessage = state.nextNotification?.message
        }
    }

    public var body: some View {
        WithViewStore(store, observe: ViewState.init) { viewStore in
            HomeWidgetView(title: "Notifications", icon: Image(systemName: "bell.badge")) {
                VStack(alignment: .leading) {
                    Text("**Programmed notifications**: \(viewStore.notificationsCount)")
                    if let nextNotificationMessage = viewStore.nextNotificationMessage {
                        Text("**Next**: \(nextNotificationMessage)")
                            .font(.footnote)
                            .multilineTextAlignment(.leading)
                    }
                }
            }
            .task { @MainActor in await viewStore.send(.task).finish() }
        }
    }

    public init(store: StoreOf<UserNotificationHomeWidget>) {
        self.store = store
    }
}

#Preview {
    List {
        UserNotificationHomeWidgetView(
            store: Store(initialState: UserNotificationHomeWidget.State()) {
                UserNotificationHomeWidget()
            }
        )
    }
}
#endif